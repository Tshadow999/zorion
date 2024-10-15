const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

const res = @import("resources.zig");
const Mesh = res.Mesh;
const Shader = res.Shader;

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}

fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw:{}: {s}\n", .{ error_code, description });
}

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

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var triangle = Mesh.init(alloc);

    try triangle.vertices.appendSlice(&verts);
    try triangle.indices.appendSlice(&indices);

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
