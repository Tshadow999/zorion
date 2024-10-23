const std = @import("std");

const glfw = @import("mach-glfw");
const math = @import("math");
const gl = @import("gl");

const c = @import("c.zig");

const primitive = @import("primitives.zig");
const resource = @import("resources.zig");
const color = @import("color.zig");
const Zorion = @import("zorion.zig");
const input = @import("input.zig");

const Mesh = resource.Mesh;
const Shader = resource.Shader;
const Object = resource.Object;

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

    const camMoveSpeed: f32 = 0.01;

    var width: c_int = undefined;
    var height: c_int = undefined;
    var channels: c_int = undefined;

    const buffer = c.stbi_load("src/Assets/wall.jpg", &width, &height, &channels, 0);
    defer c.stbi_image_free(buffer);
    //std.log.info("width:{}\t height:{}\t channels:{}\n", .{ width, height, channels });cl

    var textureId: u32 = undefined;
    gl.genTextures(1, &textureId);
    gl.bindTexture(gl.TEXTURE_2D, textureId);

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT); // or gl.CLAMP_TO_EDGE
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);

    gl.texImage2D(
        gl.TEXTURE_2D,
        0,
        if (channels == 4) gl.RGBA8 else gl.RGBA,
        width,
        height,
        0,
        if (channels == 4) gl.RGB8 else gl.RGB,
        gl.UNSIGNED_BYTE,
        buffer,
    );

    try engine.createScene();

    for (0..500) |i| {
        _ = i;
        _ = try engine.scene.?.addObject(&quad, &shader);
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
        try shader.setUniformByName("u_projection", engine.camera.projection);
        try shader.setUniformByName("u_view", engine.camera.view);
        try shader.setUniformByName("u_tint", color.lime.toVec4());
        // try shader.setUniformByName("u_texture", @as(i32, @intCast(textureId)));

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
