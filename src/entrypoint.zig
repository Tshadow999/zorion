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
const Object = resource.Object;

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

    // Sphere
    var sphere: Mesh = Mesh.init(alloc);
    try primitive.sphere(&sphere, 1, 64, 64);
    sphere.create();
    defer sphere.deinit();

    var motion = math.vec3(0, 0, 0);

    var camOffset = math.vec3(0.0, 0.0, 5);

    window.setKeyCallback(input.keyCallBack);
    var lineModeToggle = false;

    const camMoveSpeed: f32 = 0.01;

    try engine.createScene();

    for (0..100) |i| {
        _ = i;
        _ = try engine.scene.?.addObject(&sphere, &shader);
    }

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
        if (input.isPressed(&window, .S)) {
            camOffset.v[2] += camMoveSpeed;
        } else if (input.isPressed(&window, .W)) {
            camOffset.v[2] -= camMoveSpeed;
        }

        if (input.isPressed(&window, .A)) {
            camOffset.v[0] += camMoveSpeed;
        } else if (input.isPressed(&window, .D)) {
            camOffset.v[0] -= camMoveSpeed;
        }

        if (input.isPressed(&window, .Down)) {
            camOffset.v[1] += camMoveSpeed;
        } else if (input.isPressed(&window, .Up)) {
            camOffset.v[1] -= camMoveSpeed;
        }

        // Updating camera settings
        if (input.isPressed(&window, .Q)) {
            engine.camera.near += camMoveSpeed;
            engine.camera.UpdateProjection();
        } else if (input.isPressed(&window, .E)) {
            engine.camera.near -= camMoveSpeed;
            engine.camera.UpdateProjection();
        }

        const camOffsetMat = math.Mat4x4.translate(camOffset);
        engine.camera.view = math.Mat4x4.ident.mul(&camOffsetMat);

        motion.v[0] = @floatCast(@sin(glfw.getTime()));
        motion.v[1] = @floatCast(@cos(glfw.getTime()));

        const modelOffset = math.Mat4x4.translate(motion);

        // Update Shader uniforms
        try shader.setUniformByName("projection", engine.camera.projection);
        try shader.setUniformByName("view", engine.camera.view);

        std.log.info("engine.scene.?.objects.len:{d}", .{engine.scene.?.objects.len});

        for (engine.scene.?.objects.slice(), 0..engine.scene.?.objects.len) |*object, i| {
            const position = math.Mat4x4.translate(math.vec3(
                2.0 * @as(f32, @floatFromInt(@mod(i, 10))),
                0,
                2.0 * @as(f32, @floatFromInt(i)) / 10.0,
            ));
            object.transform.local2World = math.Mat4x4.ident.mul(&position);
            object.transform.local2World = math.Mat4x4.mul(&object.transform.local2World, &modelOffset);
        }

        // sphereObj.transform.local2World = ;
        try engine.scene.?.render();

        input.clearEvents();
    }
}
