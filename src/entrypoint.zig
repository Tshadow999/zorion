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

    // Cube
    var cube: Mesh = Mesh.init(alloc);
    try primitive.cube(&cube, 3.33);
    cube.create();
    defer cube.deinit();

    // Sphere
    var sphere: Mesh = Mesh.init(alloc);
    try primitive.sphere(&sphere, 0.1, 64, 64);
    sphere.create();
    defer sphere.deinit();

    // Quad
    var quad: Mesh = Mesh.init(alloc);
    try primitive.quad(&quad, 1.0, 4.0);
    quad.create();
    defer quad.deinit();

    var motion = math.vec3(0, 0, 0);

    var camOffset = math.vec3(0.0, 0.0, 5);

    // Wire frame mode!
    gl.polygonMode(gl.FRONT, gl.FILL); // try point line or fill

    window.setKeyCallback(input.keyCallBack);
    var lineModeToggle = false;

    const camMoveSpeed: f32 = 0.1;

    while (engine.isRunning()) {
        engine.render();

        // Quick escape
        if (input.isJustPressed(.Escape)) {
            window.setShouldClose(true);
        }

        if (input.isJustPressed(.P)) {
            lineModeToggle = !lineModeToggle;
            gl.polygonMode(gl.FRONT, if (lineModeToggle) gl.LINE else gl.FILL); // try point line or fill
        }

        // moving camera
        if (input.isPressed(.S)) {
            camOffset.v[2] += camMoveSpeed;
        } else if (input.isPressed(.W)) {
            camOffset.v[2] -= camMoveSpeed;
        }

        if (input.isPressed(.A)) {
            camOffset.v[0] += camMoveSpeed;
        } else if (input.isPressed(.D)) {
            camOffset.v[0] -= camMoveSpeed;
        }

        if (input.isPressed(.Down)) {
            camOffset.v[1] += camMoveSpeed;
        } else if (input.isPressed(.Up)) {
            camOffset.v[1] -= camMoveSpeed;
        }

        // Updating camera settings
        if (input.isPressed(.Q)) {
            engine.camera.near += camMoveSpeed;
            engine.camera.UpdateProjection();
        } else if (input.isPressed(.E)) {
            engine.camera.near -= camMoveSpeed;
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
        // sphere.bind();

        // Create cube mesh
        // cube.bind();

        quad.bind();

        input.clearEvents();
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
