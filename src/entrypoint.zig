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
    const window = try engine.init(1280, 720);
    defer engine.deinit();

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
        0, 0, 0, // 0
        1, 0, 0, // 1
        1, 1, 0, // 2
        0, 1, 0, // 3
        0, 0, 1, // 4
        1, 0, 1, // 5
        1, 1, 1, // 6
        0, 1, 1, // 7
    };

    // Indices
    const squareIndices = [_]u32{
        // front
        0, 1, 2,
        0, 2, 3,
        // back
        4, 5, 6,
        4, 6, 7,
        // left
        4, 0, 3,
        4, 3, 7,
        // right
        1, 5, 6,
        1, 6, 2,
        // top
        3, 2, 6,
        3, 6, 7,
        // bottom
        4, 5, 1,
        4, 1, 0,
    };

    var square = Mesh.init(alloc);

    try square.vertices.appendSlice(&squareVerts);
    try square.indices.appendSlice(&squareIndices);

    square.create();
    defer square.deinit();

    var motion = math.vec3(0, 0, 0);

    var camOffset = math.vec3(0.0, 0.0, 0.0);

    while (engine.isRunning()) {
        engine.render();

        // Quick escape
        if (window.getKey(.escape) == .press) {
            window.setShouldClose(true);
        }

        // moving camera
        if (window.getKey(.s) == .press) {
            camOffset.v[2] += 0.001;
        } else if (window.getKey(.w) == .press) {
            camOffset.v[2] -= 0.001;
        }

        if (window.getKey(.a) == .press) {
            camOffset.v[0] += 0.001;
        } else if (window.getKey(.d) == .press) {
            camOffset.v[0] -= 0.001;
        }

        if (window.getKey(.z) == .press) {
            camOffset.v[1] += 0.001;
        } else if (window.getKey(.x) == .press) {
            camOffset.v[1] -= 0.001;
        }

        // Updating camera settings
        if (window.getKey(.q) == .press) {
            engine.camera.near += 0.001;
            engine.camera.UpdateProjection();
        } else if (window.getKey(.e) == .press) {
            engine.camera.near -= 0.001;
            engine.camera.UpdateProjection();
        }

        const camOffsetMat = math.Mat4x4.translate(camOffset);
        engine.camera.view = math.Mat4x4.ident.mul(&camOffsetMat);

        // std.log.info("pos:{}", .{camOffset});

        motion.v[0] = @floatCast(@sin(glfw.getTime()));

        // Update Shader uniforms
        shader.bind();

        var uniformLocation = shader.getUniformLocation("offset");
        Shader.setVec3(uniformLocation, motion);

        uniformLocation = shader.getUniformLocation("projection");
        Shader.setMat4(uniformLocation, engine.camera.projection);

        uniformLocation = shader.getUniformLocation("view");
        Shader.setMat4(uniformLocation, engine.camera.view);

        // Create the flat triangle and cube meshes
        triangle.bind();
        square.bind();
    }
}
