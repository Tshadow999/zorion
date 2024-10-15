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
    const verts = [9]f32{
        -0.5, -0.5, 0.0,
        0.5,  -0.5, 0.0,
        0.0,  0.5,  0.0,
    };

    // Contruct Vertex array
    var vertexArray: u32 = undefined;
    gl.genVertexArrays(1, &vertexArray);
    gl.bindVertexArray(vertexArray);

    // Contruct Vertex buffer
    var vertexBuffer: u32 = undefined;
    gl.genBuffers(1, &vertexBuffer);

    gl.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
    gl.bufferData(gl.ARRAY_BUFFER, verts.len * @sizeOf(f32), &verts, gl.STATIC_DRAW);

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);

    while (!window.shouldClose()) {
        glfw.pollEvents();

        gl.clearColor(0.3, 0.1, 0.3, 1);
        gl.clear(gl.COLOR_BUFFER_BIT);

        // Draw triangle
        gl.drawArrays(gl.TRIANGLES, 0, 3);

        window.swapBuffers();
    }
}
