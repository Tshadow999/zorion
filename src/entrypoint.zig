const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

const resource = @import("resources.zig");
const Zorion = @import("zorion.zig");
const Mesh = resource.Mesh;
const Shader = resource.Shader;

const math = @import("math");

pub fn main() !void {
    var engine = Zorion.Engine{};
    const window = try engine.init();
    _ = window;
    defer engine.deinit();

    engine.camera.projection = math.Mat4x4.perspective(math.degreesToRadians(60.0), 16.0 / 9.0, 0.01, 10_000);

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

    var shader = Shader{
        .fragmentSource = @embedFile("Assets/frag.glsl"),
        .vertexSource = @embedFile("Assets/vert.glsl"),
    };

    shader.compile();
    defer shader.deinit();

    // Contruct Square position
    const squareVerts = [_]f32{
        -0.5, -0.5, 0.0, // bottom left
        0.5, -0.5, 0.0, // bottom right
        0.5, 0.5, 0.0, // top right
        -0.5, 0.5, 0.0, // top left
    };

    // Indices
    const squareIndices = [_]u32{
        0, 1, 2,
        0, 2, 3,
    };

    var square = Mesh.init(alloc);

    try square.vertices.appendSlice(&squareVerts);
    try square.indices.appendSlice(&squareIndices);

    square.create();
    defer square.deinit();

    var motion = math.vec3(0, 0, 0);

    while (engine.isRunning()) {
        engine.render();

        // Draw triangle
        shader.bind();

        motion.v[0] = @floatCast(@sin(glfw.getTime()));

        var uniformLocation = shader.getUniformLocation("offset");
        Shader.setVec3(uniformLocation, motion);

        uniformLocation = shader.getUniformLocation("projection");
        Shader.setMat4(uniformLocation, engine.camera.projection);

        triangle.bind();
        // square.bind();

    }
}
