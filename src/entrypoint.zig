const std = @import("std");

const glfw = @import("mach-glfw");
const math = @import("math");
const gl = @import("gl");

const primitive = @import("primitives.zig");
const resource = @import("resources.zig");
const Zorion = @import("zorion.zig");
const input = @import("input.zig");

const Mesh = resource.Mesh;
const Shader = resource.Shader;

pub fn main() !void {
    var engine = Zorion.Engine{};
    const window = try engine.init(.{});

    defer engine.deinit();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var shader = Shader{
        .fragmentSource = @embedFile("Assets/frag.glsl"),
        .vertexSource = @embedFile("Assets/vert.glsl"),
    };

    try shader.compile();
    defer shader.deinit();

    // Contruct Square position
    // const squareVerts = [_]resource.Vertex{
    //     .{
    //         .position = math.vec3(0, 0, 0), // 0
    //     },
    //     .{
    //         .position = math.vec3(1, 0, 0), // 1
    //     },
    //     .{
    //         .position = math.vec3(1, 1, 0), // 2
    //     },
    //     .{
    //         .position = math.vec3(0, 1, 0), // 3
    //     },
    //     .{
    //         .position = math.vec3(0, 0, 1), // 4
    //     },
    //     .{
    //         .position = math.vec3(1, 0, 1), // 5
    //     },
    //     .{
    //         .position = math.vec3(1, 1, 1), // 6
    //     },
    //     .{
    //         .position = math.vec3(0, 1, 1), // 7
    //     },
    // };

    // // Indices
    // const squareIndices = [_]u32{
    //     // front
    //     0, 1, 2,
    //     0, 2, 3,
    //     // back
    //     4, 5, 6,
    //     4, 6, 7,
    //     // left
    //     4, 0, 3,
    //     4, 3, 7,
    //     // right
    //     1, 5, 6,
    //     1, 6, 2,
    //     // top
    //     3, 2, 6,
    //     3, 6, 7,
    //     // bottom
    //     4, 5, 1,
    //     4, 1, 0,
    // };

    // Sphere:
    var sphere: Mesh = Mesh.init(alloc);
    try primitive.sphere(&sphere, 3.0, 64, 64);

    sphere.create();
    defer sphere.deinit();

    // var square = Mesh.init(alloc);

    // try square.vertices.appendSlice(&squareVerts);
    // try square.indices.appendSlice(&squareIndices);

    // square.create();
    // defer square.deinit();

    var motion = math.vec3(0, 0, 0);

    var camOffset = math.vec3(0.0, 0.0, 5);

    // Wire frame mode!
    gl.polygonMode(gl.FRONT, gl.FILL); // try point line or fill

    while (engine.isRunning()) {
        engine.render();

        // Quick escape
        if (input.isPressed(.Escape, getKeyState, &window)) {
            window.setShouldClose(true);
        }

        // moving camera
        if (input.isPressed(.S, getKeyState, &window)) {
            camOffset.v[2] += 0.001;
        } else if (input.isPressed(.W, getKeyState, &window)) {
            camOffset.v[2] -= 0.001;
        }

        if (input.isPressed(.A, getKeyState, &window)) {
            camOffset.v[0] += 0.001;
        } else if (input.isPressed(.D, getKeyState, &window)) {
            camOffset.v[0] -= 0.001;
        }

        if (input.isPressed(.Down, getKeyState, &window)) {
            camOffset.v[1] += 0.001;
        } else if (input.isPressed(.Up, getKeyState, &window)) {
            camOffset.v[1] -= 0.001;
        }

        // Updating camera settings
        if (input.isPressed(.Q, getKeyState, &window)) {
            engine.camera.near += 0.001;
            engine.camera.UpdateProjection();
        } else if (input.isPressed(.E, getKeyState, &window)) {
            engine.camera.near -= 0.001;
            engine.camera.UpdateProjection();
        }

        const camOffsetMat = math.Mat4x4.translate(camOffset);
        engine.camera.view = math.Mat4x4.ident.mul(&camOffsetMat);

        motion.v[0] = @floatCast(@sin(glfw.getTime()));
        motion.v[1] = @floatCast(@cos(glfw.getTime()));

        // Update Shader uniforms
        shader.bind();

        try shader.setUniformByName("offset", motion);
        try shader.setUniformByName("projection", engine.camera.projection);
        try shader.setUniformByName("view", engine.camera.view);

        // create the sphere mesh
        sphere.bind();

        // Create the cube mesh
        // square.bind();
    }
}

fn getKeyState(window: *const glfw.Window, key: input.Key) input.State {
    const state = window.getKey(input.keyToGlfw(key));
    return switch (state) {
        .press => input.State.Press,
        .release => input.State.Release,
        else => input.State.None,
    };
}
