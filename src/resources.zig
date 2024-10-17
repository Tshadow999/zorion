const std = @import("std");
const gl = @import("gl");
const math = @import("math");

pub const Mesh = struct {
    vertices: std.ArrayList(f32),
    indices: std.ArrayList(u32),

    vao: u32 = undefined,
    vbo: u32 = undefined,
    ibo: u32 = undefined,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Mesh {
        return .{
            .vertices = std.ArrayList(f32).init(allocator),
            .indices = std.ArrayList(u32).init(allocator),
        };
    }

    pub fn create(self: *Self) void {
        gl.genVertexArrays(1, &self.vao);
        gl.genBuffers(1, &self.vbo);
        gl.genBuffers(1, &self.ibo);

        gl.bindVertexArray(self.vao);

        gl.bindBuffer(gl.ARRAY_BUFFER, self.vbo);
        gl.bufferData(gl.ARRAY_BUFFER, @intCast(self.vertices.items.len * @sizeOf(f32)), self.vertices.items[0..].ptr, gl.STATIC_DRAW);

        gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), null);
        gl.enableVertexAttribArray(0);

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ibo);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, @intCast(self.indices.items.len * @sizeOf(u32)), self.indices.items[0..].ptr, gl.STATIC_DRAW);

        gl.bindVertexArray(0);
        gl.bindBuffer(gl.ARRAY_BUFFER, 0);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
    }

    pub fn bind(self: *Self) void {
        gl.bindVertexArray(self.vao);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ibo);

        gl.drawElements(gl.TRIANGLES, @intCast(self.indices.items.len), gl.UNSIGNED_INT, null);
    }

    pub fn deinit(self: *Self) void {
        gl.deleteVertexArrays(1, &self.vao);
        gl.deleteBuffers(1, &self.vbo);
        gl.deleteBuffers(1, &self.ibo);

        self.vertices.deinit();
        self.indices.deinit();
    }
};

pub const Shader = struct {
    program: u32 = 0,
    vertexSource: []const u8,
    fragmentSource: []const u8,

    const Self = @This();

    pub fn load(self: *Self, vertexPath: []u8, fragmentPath: []u8) void {
        _ = self;
        _ = vertexPath;
        _ = fragmentPath;
    }

    pub fn bind(self: *Self) void {
        gl.useProgram(self.program);
    }

    pub fn compile(self: *Self) void {
        const vertShader = gl.createShader(gl.VERTEX_SHADER);
        gl.shaderSource(vertShader, 1, &self.vertexSource.ptr, null);
        gl.compileShader(vertShader);
        checkShaderCompileStatus(vertShader, "VERTEX");

        const fragShader = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(fragShader, 1, &self.fragmentSource.ptr, null);
        gl.compileShader(fragShader);
        checkShaderCompileStatus(fragShader, "FRAGMENT");

        self.program = gl.createProgram();
        gl.attachShader(self.program, vertShader);
        gl.attachShader(self.program, fragShader);

        gl.linkProgram(self.program);

        gl.deleteShader(vertShader);
        gl.deleteShader(fragShader);
    }

    fn checkShaderCompileStatus(shader: u32, shaderType: []const u8) void {
        var status: i32 = 0;
        gl.getShaderiv(shader, gl.COMPILE_STATUS, &status);
        if (status == gl.FALSE) {
            var logLength: i32 = 0;
            gl.getShaderiv(shader, gl.INFO_LOG_LENGTH, &logLength);

            var log = std.ArrayList(u8).init(std.heap.page_allocator);
            defer log.deinit();
            // try log.ensureTotalCapacity(@intCast(logLength));
            gl.getShaderInfoLog(shader, logLength, null, log.items.ptr);

            std.log.err("{s} Shader compile error: {s}", .{ shaderType, log.items });
            std.process.exit(1);
        }
    }

    pub fn deinit(self: *Self) void {
        gl.deleteProgram(self.program);
    }

    // Shader uniforms:

    pub fn getUniformLocation(self: *Self, name: []const u8) i32 {
        return gl.getUniformLocation(self.program, name.ptr);
    }

    // TODO add more types
    pub fn setUniform(location: i32, uniform: anytype) void {
        switch (@TypeOf(uniform)) {
            i32 => gl.uniform1i(location, uniform),
            u32 => gl.uniform1ui(location, uniform),
            f32 => gl.uniform1f(location, uniform),
            math.Vec2 => gl.uniform2fv(location, 1, &uniform.v[0]),
            math.Vec3 => gl.uniform3fv(location, 1, &uniform.v[0]),
            math.Vec4 => gl.uniform4fv(location, 1, &uniform.v[0]),
            math.Mat4x4 => gl.uniformMatrix4fv(@intCast(location), 1, gl.FALSE, &uniform.v[0].v[0]),
            else => {
                std.log.err("Uniform type not yet implemented: ({})", .{@TypeOf(uniform)});
                std.process.exit(1);
            },
        }
    }
};
