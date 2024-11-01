const std = @import("std");

const _engine = @import("engine");
const Engine = _engine.Zorion.Engine;

const glfw = _engine.glfw;
const math = _engine.math;
const gl = _engine.gl;

const Input = _engine.Input;

const Material = _engine.Material;
const Shader = _engine.Shader;
const Texture = _engine.Texture;
const Mesh = _engine.Mesh;
const Object = _engine.Object;
const primitive = _engine.primitive;
const Color = _engine.Color;

pub fn main() !void {
    var engine = Engine{};
    const window = try engine.init(.{ .fullscreen = true, .cursorMode = .disabled });

    defer engine.deinit();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var shader = Shader{
        .fragmentSource = @embedFile("frag.glsl"),
        .vertexSource = @embedFile("vert.glsl"),
    };
    try shader.compile();
    defer shader.deinit();

    var sphere: Mesh = Mesh.init(alloc);
    try primitive.sphere(&sphere, 1, 16);
    sphere.create();
    defer sphere.deinit();

    var quad: Mesh = Mesh.init(alloc);
    try primitive.quad(&quad, 1.0, 1.0);
    quad.create();
    defer quad.deinit();

    var cube: Mesh = Mesh.init(alloc);
    try primitive.cube(&cube, 1.5);
    cube.create();
    defer cube.deinit();

    var lineModeToggle = false;

    engine.createScene();

    var wallTexture = try Texture.load("examples/sandbox/wall.jpg");
    defer wallTexture.deinit();
    wallTexture.create();

    var prototypeTexture = try Texture.load("examples/sandbox/prototype.png");
    defer prototypeTexture.deinit();
    prototypeTexture.create();

    var prototypeMat = Material{ .shader = &shader };

    try prototypeMat.addProperty("u_tint", Color.black);
    try prototypeMat.addProperty("u_texture", &prototypeTexture);
    // try prototypeMat.addProperty("u_texture", &wallTexture);

    var wallMat = Material{ .shader = &shader };
    try wallMat.addProperty("u_tint", Color.blue);
    try wallMat.addProperty("u_texture", &prototypeTexture);
    //  try wallMat.addProperty("u_texture", &wallTexture);

    var motion = math.vec3(0, 0, 0);

    var camOffset = math.vec3(-15.0, 0.0, 5);
    var angleY: f32 = 0.0;
    var angleX: f32 = 0.0;
    const camMoveSpeed: f32 = 10;

    var pcg = std.rand.Pcg.init(456);

    const objectCount: f32 = 1024;
    const rootObjectCount = @sqrt(objectCount);

    for (0..objectCount) |i| {
        _ = i;
        _ = try engine.scene.?.addObject(&sphere, if (pcg.random().boolean()) &prototypeMat else &wallMat);
    }

    var lastFrameTime = glfw.getTime();

    // CORE LOOP \\
    while (engine.isRunning()) {
        engine.render();

        const delta: f32 = @floatCast(glfw.getTime() - lastFrameTime);
        lastFrameTime = glfw.getTime();

        std.log.info("fps:{d}", .{1.0 / delta});

        // Quick escape
        if (Input.isJustPressed(.Escape)) {
            engine.quit();
        }

        // Polygon mode toggle
        if (Input.isJustPressed(.P)) {
            lineModeToggle = !lineModeToggle;
            gl.polygonMode(gl.FRONT, if (lineModeToggle) gl.LINE else gl.FILL); // try point line or fill
        }

        // Moving camera
        if (Input.isPressed(&window, .S)) {
            camOffset.v[2] += camMoveSpeed * delta;
        } else if (Input.isPressed(&window, .W)) {
            camOffset.v[2] -= camMoveSpeed * delta;
        }

        if (Input.isPressed(&window, .A)) {
            camOffset.v[0] += camMoveSpeed * delta;
        } else if (Input.isPressed(&window, .D)) {
            camOffset.v[0] -= camMoveSpeed * delta;
        }

        if (Input.isPressed(&window, .LeftCtrl)) {
            camOffset.v[1] += camMoveSpeed * delta;
        } else if (Input.isPressed(&window, .LeftShift)) {
            camOffset.v[1] -= camMoveSpeed * delta;
        }

        // Rotating camera
        const mouseState = Input.getMouseState();
        angleY -= mouseState.relativeX * delta * math.tau;
        angleX = math.clamp(angleX - mouseState.relativeY * delta * math.tau, -math.pi / 2.0, math.pi / 2.0);

        // Updating camera settings
        // if (input.isPressed(&window, .Q)) {
        //     engine.camera.near += camMoveSpeed * delta * 0.1;
        //     engine.camera.UpdateProjection();
        // } else if (input.isPressed(&window, .E)) {
        //     engine.camera.near -= camMoveSpeed * delta * 0.1;
        //     engine.camera.UpdateProjection();
        // }

        const camTranslation = math.Mat4x4.translate(camOffset);

        const yaw = math.Mat4x4.rotateY(angleY);
        const pitch = math.Mat4x4.rotateX(angleX);

        const rotationMat = math.Mat4x4.mul(&pitch, &yaw);
        engine.camera.view = math.Mat4x4.mul(&rotationMat, &camTranslation);

        shader.bind();

        // Update Shader uniforms
        try shader.setUniformByName("u_projection", engine.camera.projection);
        try shader.setUniformByName("u_view", engine.camera.view);

        for (engine.scene.?.objects.slice(), 0..engine.scene.?.objects.len) |*object, i| {
            const position = math.Mat4x4.translate(math.vec3(
                2.0 * @as(f32, @floatFromInt(@mod(i, @as(usize, @intFromFloat(rootObjectCount))))),
                0,
                2.0 * @as(f32, @floatFromInt(i)) / rootObjectCount,
            ));

            motion.v[1] = 0.5 * @as(f32, @floatCast(
                @cos(glfw.getTime() + @as(f32, @floatFromInt(@mod(i, @as(usize, @intFromFloat(rootObjectCount)))))) + @sin(glfw.getTime() + @as(f32, @floatFromInt(i)) / rootObjectCount),
            ));
            const modelOffset = math.Mat4x4.translate(motion);

            object.transform.local2World = math.Mat4x4.ident.mul(&position);
            object.transform.local2World = math.Mat4x4.mul(&object.transform.local2World, &modelOffset);
        }
        try engine.scene.?.render();

        Input.clearEvents();
    }
}
