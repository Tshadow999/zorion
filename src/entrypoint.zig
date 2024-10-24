const std = @import("std");

const glfw = @import("mach-glfw");
const math = @import("math");
const gl = @import("gl");

const primitive = @import("primitives.zig");
const resource = @import("resources.zig");
const color = @import("color.zig");
const Zorion = @import("zorion.zig");
const input = @import("input.zig");

const Mesh = resource.Mesh;
const Shader = resource.Shader;
const Object = resource.Object;
const Texture = resource.Texture;

pub fn main() !void {
    var engine = Zorion.Engine{};
    const window = try engine.init(.{ .fullscreen = false });

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

    var sphere: Mesh = Mesh.init(alloc);
    try primitive.sphere(&sphere, 1, 64, 64);
    sphere.create();
    defer sphere.deinit();

    var quad: Mesh = Mesh.init(alloc);
    try primitive.quad(&quad, 1.0, 1.0);
    quad.create();
    defer quad.deinit();

    var motion = math.vec3(0, 0, 0);

    var camOffset = math.vec3(0.0, 0.0, 5);

    window.setKeyCallback(input.keyCallBack);
    var lineModeToggle = false;

    const camMoveSpeed: f32 = 10;

    engine.createScene();

    var prototypeTexture = try Texture.load("src/Assets/prototype.png");
    defer prototypeTexture.deinit();
    prototypeTexture.create();

    var prototypeMat = resource.Material{ .shader = &shader };

    try prototypeMat.addProperty("u_tint", color.azure.toVec4());
    try prototypeMat.addProperty("u_texture", &prototypeTexture);

    var wallTexture = try Texture.load("src/Assets/wall.jpg");
    defer wallTexture.deinit();
    wallTexture.create();

    var wallMat = resource.Material{ .shader = &shader };
    try wallMat.addProperty("u_tint", color.violet.toVec4());
    try wallMat.addProperty("u_texture", &wallTexture);

    var pcg = std.rand.Pcg.init(456);

    for (0..500) |i| {
        _ = i;
        _ = try engine.scene.?.addObject(
            &quad,
            if (pcg.random().boolean()) &prototypeMat else &wallMat,
        );
    }

    var lastFrameTime = glfw.getTime();

    // CORE LOOP \\
    while (engine.isRunning()) {
        engine.render();

        const delta: f32 = @floatCast(glfw.getTime() - lastFrameTime);
        lastFrameTime = glfw.getTime();

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
            camOffset.v[2] += camMoveSpeed * delta;
        } else if (input.isPressed(&window, .W)) {
            camOffset.v[2] -= camMoveSpeed * delta;
        }

        if (input.isPressed(&window, .A)) {
            camOffset.v[0] += camMoveSpeed * delta;
        } else if (input.isPressed(&window, .D)) {
            camOffset.v[0] -= camMoveSpeed * delta;
        }

        if (input.isPressed(&window, .Down)) {
            camOffset.v[1] += camMoveSpeed * delta;
        } else if (input.isPressed(&window, .Up)) {
            camOffset.v[1] -= camMoveSpeed * delta;
        }

        // Updating camera settings
        if (input.isPressed(&window, .Q)) {
            engine.camera.near += camMoveSpeed * delta * 0.1;
            engine.camera.UpdateProjection();
        } else if (input.isPressed(&window, .E)) {
            engine.camera.near -= camMoveSpeed * delta * 0.1;
            engine.camera.UpdateProjection();
        }

        const camOffsetMat = math.Mat4x4.translate(camOffset);
        engine.camera.view = math.Mat4x4.ident.mul(&camOffsetMat);

        motion.v[0] = @floatCast(@sin(glfw.getTime()));
        motion.v[1] = @floatCast(@cos(glfw.getTime()));

        const modelOffset = math.Mat4x4.translate(motion);

        shader.bind();

        // Update Shader uniforms
        try shader.setUniformByName("u_projection", engine.camera.projection);
        try shader.setUniformByName("u_view", engine.camera.view);
        try shader.setUniformByName("u_tint", color.lime.toVec4());
        // try shader.setUniformByName("u_texture", @as(i32, @intCast(wallTexture.id)));

        for (engine.scene.?.objects.slice(), 0..engine.scene.?.objects.len) |*object, i| {
            const position = math.Mat4x4.translate(math.vec3(
                2.0 * @as(f32, @floatFromInt(@mod(i, 25))),
                0,
                2.0 * @as(f32, @floatFromInt(i)) / 25.0,
            ));
            object.transform.local2World = math.Mat4x4.ident.mul(&position);
            object.transform.local2World = math.Mat4x4.mul(&object.transform.local2World, &modelOffset);
        }

        try engine.scene.?.render();

        input.clearEvents();
    }
}
