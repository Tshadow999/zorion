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
    const verts = [_]f32{
        -0.5, -0.5, 0.0,
        0.5,  -0.5, 0.0,
        0.0,  0.5,  0.0,
    };

    // Indices
    const indices = [_]u32{
        0, 1, 2,
    };

    // Construct Index buffer
    var indexBufferObj: u32 = undefined;
    gl.genBuffers(1, &indexBufferObj);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBufferObj);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(u32), &indices, gl.STATIC_DRAW);

    // Contruct Vertex array
    var vertexArrayObj: u32 = undefined;
    gl.genVertexArrays(1, &vertexArrayObj);
    gl.bindVertexArray(vertexArrayObj);

    // Contruct Vertex buffer
    var vertexBufferObj: u32 = undefined;
    gl.genBuffers(1, &vertexBufferObj);

    gl.bindBuffer(gl.ARRAY_BUFFER, vertexBufferObj);
    gl.bufferData(gl.ARRAY_BUFFER, verts.len * @sizeOf(f32), &verts, gl.STATIC_DRAW);

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);

    gl.bindBuffer(gl.ARRAY_BUFFER, 0);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
    gl.bindVertexArray(0);

    // Shaders

    // Vertex
    const vertShaderSource: [*]const u8 = @embedFile("vert.glsl");
    const vertShader: u32 = gl.createShader(gl.VERTEX_SHADER);

    gl.shaderSource(vertShader, 1, &vertShaderSource, null);
    gl.compileShader(vertShader);

    // Fragment
    const fragShaderSource: [*]const u8 = @embedFile("frag.glsl");
    const fragShader: u32 = gl.createShader(gl.FRAGMENT_SHADER);

    gl.shaderSource(fragShader, 1, &fragShaderSource, null);
    gl.compileShader(fragShader);

    const shaderProgram = gl.createProgram();
    gl.attachShader(shaderProgram, vertShader);
    gl.attachShader(shaderProgram, fragShader);

    gl.linkProgram(shaderProgram);

    gl.deleteShader(vertShader);
    gl.deleteShader(fragShader);

    gl.useProgram(shaderProgram);

    while (!window.shouldClose()) {
        glfw.pollEvents();

        gl.clearColor(0.3, 0.1, 0.3, 1);
        gl.clear(gl.COLOR_BUFFER_BIT);

        // Draw triangle
        gl.useProgram(shaderProgram);
        gl.bindVertexArray(vertexArrayObj);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBufferObj);
        gl.drawElements(gl.TRIANGLES, indices.len, gl.UNSIGNED_INT, null);

        window.swapBuffers();
    }
}
