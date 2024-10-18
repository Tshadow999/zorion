const std = @import("std");
const gl = @import("gl");
const math = @import("math");

const AttributeHelper = struct {};

pub const Vertex = extern struct {
    position: math.Vec3 = math.vec3(0, 0, 0),
    uv: math.Vec2 = math.vec2(0, 0),
    normal: math.Vec3 = math.vec3(0, 0, 0),
    color: math.Vec4 = math.vec4(0, 0, 0, 0),

    pub fn addAtributes() void {
        Mesh.addElement(0, 3, 0, false); // @offsetOf(Vertex, "position") = 0
        Mesh.addElement(1, 2, @offsetOf(Vertex, "uv"), false);
        Mesh.addElement(2, 3, @offsetOf(Vertex, "normal"), false);
        Mesh.addElement(3, 4, @offsetOf(Vertex, "color"), false);

        // std.log.info("Size of Vec2:{}", .{@sizeOf(math.Vec2)}); // = 8
        // std.log.info("Size of Vec3:{}", .{@sizeOf(math.Vec3)}); // = 16
        // std.log.info("Size of Vec4:{}", .{@sizeOf(math.Vec4)}); // = 16
        // std.log.info("Size of vertex:{}", .{@sizeOf(Vertex)}); // = 64?
    }
};

pub const Mesh = struct {
    vertices: std.ArrayList(Vertex),
    indices: std.ArrayList(u32),

    vao: u32 = undefined,
    vbo: u32 = undefined,
    ibo: u32 = undefined,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Mesh {
        return .{
            .vertices = std.ArrayList(Vertex).init(allocator),
            .indices = std.ArrayList(u32).init(allocator),
        };
    }

    fn addElement(
        index: u32,
        elementCount: i32,
        elementPosition: u32,
        normalized: bool,
    ) void {
        const glNormalized: gl.GLboolean = if (normalized) gl.TRUE else gl.FALSE;
        gl.vertexAttribPointer(
            index,
            elementCount,
            gl.FLOAT,
            glNormalized,
            @sizeOf(Vertex),
            @ptrFromInt(elementPosition),
        );
        gl.enableVertexAttribArray(index);
    }

    pub fn create(self: *Self) void {
        gl.genVertexArrays(1, &self.vao);
        gl.genBuffers(1, &self.vbo);
        gl.genBuffers(1, &self.ibo);

        gl.bindVertexArray(self.vao);

        gl.bindBuffer(gl.ARRAY_BUFFER, self.vbo);
        gl.bufferData(gl.ARRAY_BUFFER, @intCast(self.vertices.items.len * @sizeOf(Vertex)), self.vertices.items[0..].ptr, gl.STATIC_DRAW);

        Vertex.addAtributes();

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

    const Error = error{
        InvalidUniformName,
        InvalidVertexShader,
        InvalidFragmentShader,
    };

    const Self = @This();

    pub fn load(self: *Self, vertexPath: []u8, fragmentPath: []u8) void {
        _ = self;
        _ = vertexPath;
        _ = fragmentPath;
    }

    pub fn bind(self: *Self) void {
        gl.useProgram(self.program);
    }

    pub fn compile(self: *Self) !void {
        const vertShader = gl.createShader(gl.VERTEX_SHADER);
        gl.shaderSource(vertShader, 1, &self.vertexSource.ptr, null);
        gl.compileShader(vertShader);
        try checkShaderCompileStatus(vertShader, true);

        const fragShader = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(fragShader, 1, &self.fragmentSource.ptr, null);
        gl.compileShader(fragShader);
        try checkShaderCompileStatus(fragShader, false);

        self.program = gl.createProgram();
        gl.attachShader(self.program, vertShader);
        gl.attachShader(self.program, fragShader);

        gl.linkProgram(self.program);

        gl.deleteShader(vertShader);
        gl.deleteShader(fragShader);
    }

    fn checkShaderCompileStatus(shader: u32, isVertexShader: bool) !void {
        var isCompiled: i32 = 0;
        gl.getShaderiv(shader, gl.COMPILE_STATUS, &isCompiled);
        if (isCompiled == gl.FALSE) {
            var maxLength: i32 = 0;
            gl.getShaderiv(shader, gl.INFO_LOG_LENGTH, &maxLength);

            const errorLogSize: usize = 512;
            var log = [1:0]u8{0} ** errorLogSize;
            gl.getShaderInfoLog(shader, errorLogSize, &maxLength, &log);

            gl.deleteShader(shader);

            if (isVertexShader) {
                std.log.err("VERTEX SHADER\n{s}", .{log[0..@intCast(maxLength)]});
                return Error.InvalidVertexShader;
            } else {
                std.log.err("FRAGMENT SHADER\n{s}", .{log[0..@intCast(maxLength)]});
                return Error.InvalidFragmentShader;
            }
        }
    }

    pub fn deinit(self: *Self) void {
        gl.deleteProgram(self.program);
    }

    // Shader uniforms:
    pub fn setUniformByName(self: *Self, name: []const u8, uniform: anytype) !void {
        const location = gl.getUniformLocation(self.program, name.ptr);
        if (location == -1) {
            return Error.InvalidUniformName;
        }
        setUniform(location, uniform);
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
