const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}

fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw:{}: {s}\n", .{ error_code, description });
}

const Mesh = struct {
    vertices: [32]f32 = [1]f32{0} ** 32,
    indices: [32]u32 = [1]u32{0} ** 32,

    vertexCount: u32 = 0,
    indexCount: u32 = 0,

    vao: u32 = undefined,
    vbo: u32 = undefined,
    ibo: u32 = undefined,

    const Self = @This();

    fn create(self: *Self) void {
        gl.genVertexArrays(1, &self.vao);
        gl.genBuffers(1, &self.vbo);
        gl.genBuffers(1, &self.ibo);

        gl.bindVertexArray(self.vao);

        gl.bindBuffer(gl.ARRAY_BUFFER, self.vbo);
        gl.bufferData(gl.ARRAY_BUFFER, self.vertexCount * @sizeOf(f32), &self.vertices, gl.STATIC_DRAW);

        gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), null);
        gl.enableVertexAttribArray(0);

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ibo);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, self.indexCount * @sizeOf(u32), &self.indices, gl.STATIC_DRAW);

        gl.bindVertexArray(0);
        gl.bindBuffer(gl.ARRAY_BUFFER, 0);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
    }

    fn bind(self: *Self) void {
        gl.bindVertexArray(self.vao);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.ibo);

        gl.drawElements(gl.TRIANGLES, @intCast(self.indexCount), gl.UNSIGNED_INT, null);
    }

    fn deinit(self: *Self) void {
        gl.deleteVertexArrays(1, &self.vao);
        gl.deleteBuffers(1, &self.vbo);
        gl.deleteBuffers(1, &self.ibo);
    }
};

const Shader = struct {
    program: u32 = 0,
    vertexSource: []const u8,
    fragmentSource: []const u8,

    const Self = @This();

    fn load(self: *Self, vertexPath: []u8, fragmentPath: []u8) void {
        _ = self;
        _ = vertexPath;
        _ = fragmentPath;
    }

    fn bind(self: *Self) void {
        gl.useProgram(self.program);
    }

    fn compile(self: *Self) void {
        const vertShader = gl.createShader(gl.VERTEX_SHADER);
        gl.shaderSource(vertShader, 1, &self.vertexSource.ptr, null);
        gl.compileShader(vertShader);

        const fragShader = gl.createShader(gl.FRAGMENT_SHADER);
        gl.shaderSource(fragShader, 1, &self.fragmentSource.ptr, null);
        gl.compileShader(fragShader);

        self.program = gl.createProgram();
        gl.attachShader(self.program, vertShader);
        gl.attachShader(self.program, fragShader);

        gl.linkProgram(self.program);

        gl.compileShader(vertShader);
        gl.compileShader(fragShader);
    }

    fn deinit(self: *Self) void {
        gl.deleteProgram(self.program);
    }
};

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("Failed to init glfw: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    const window = glfw.Window.create(
        1280,
        720,
        "Zorion Engine",
        null,
        null,
        .{},
    ).?;
    defer window.destroy();

    glfw.makeContextCurrent(window);

    const proc: glfw.GLProc = undefined;
    try gl.load(proc, glGetProcAddress);

    // Contruct triangle position
    const verts = [_]f32{
        -0.5, -0.5, 0.0,
        0.5,  -0.5, 0.0,
        0.0,  0.5,  0.0,
    };

    // Indices
    const indices = [_]u32{
        0, 1, 2,
    };

    var triangle = Mesh{};
    @memcpy(triangle.vertices[0..verts.len], verts[0..]);
    @memcpy(triangle.indices[0..indices.len], indices[0..]);
    triangle.vertexCount = verts.len;
    triangle.indexCount = indices.len;

    triangle.create();
    defer triangle.deinit();

    var triangleShader = Shader{
        .fragmentSource = @embedFile("frag.glsl"),
        .vertexSource = @embedFile("vert.glsl"),
    };

    triangleShader.compile();
    defer triangleShader.deinit();

    while (!window.shouldClose()) {
        glfw.pollEvents();

        gl.clearColor(0.3, 0.1, 0.3, 1);
        gl.clear(gl.COLOR_BUFFER_BIT);

        // Draw triangle
        triangleShader.bind();
        triangle.bind();

        window.swapBuffers();
    }
}
