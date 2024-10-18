const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

const math = @import("math");

pub const WindowProps = struct {
    width: u32 = 1280,
    height: u32 = 720,
    title: [:0]const u8 = "Zorion Engine",
    vsync: bool = true,
};

pub const Engine = struct {
    window: glfw.Window = undefined,
    camera: Camera3D = .{},

    const Self = @This();

    pub fn init(self: *Self, windowProps: WindowProps) !glfw.Window {
        // Not sure if I need this check
        // if (windowProps.width < 300 or windowProps.height < 300) {
        //     std.log.err("Invalid screen size", .{});
        //     std.process.exit(1);
        // }

        // Handle glfw callbacks
        glfw.setErrorCallback(errorCallback);
        if (!glfw.init(.{})) {
            std.log.err("Failed to init glfw: {?s}", .{glfw.getErrorString()});
            std.process.exit(1);
        }

        // Create a window
        const window = glfw.Window.create(
            windowProps.width,
            windowProps.height,
            windowProps.title,
            null,
            null,
            .{},
        ) orelse {
            std.log.err("Failed to create GLFW window: {?s}", .{glfw.getErrorString()});
            std.process.exit(1);
        };
        self.window = window;

        glfw.makeContextCurrent(self.window);

        const proc: glfw.GLProc = undefined;
        try gl.load(proc, glGetProcAddress);

        // One time enables
        gl.enable(gl.DEPTH_TEST);

        gl.enable(gl.CULL_FACE);
        gl.cullFace(gl.BACK);

        self.camera.screenWidth = windowProps.width;
        self.camera.screenHeight = windowProps.height;
        self.camera.UpdateProjection();

        return self.window;
    }

    pub fn render(self: *Self) void {
        self.window.swapBuffers();

        glfw.pollEvents();

        gl.clearColor(0.3, 0.1, 0.3, 1);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    }

    pub fn deinit(self: *Self) void {
        self.window.destroy();
        glfw.terminate();
    }

    pub fn isRunning(self: *Self) bool {
        return !self.window.shouldClose();
    }
};

pub const Camera3D = struct {
    projection: math.Mat4x4 = math.Mat4x4.ident,
    view: math.Mat4x4 = math.Mat4x4.ident,

    fov: f32 = 80,
    near: f32 = -1 + 0.1,
    far: f32 = 10_000,

    screenWidth: u32 = undefined,
    screenHeight: u32 = undefined,

    const Self = @This();

    pub fn UpdateProjection(
        self: *Self,
    ) void {
        const aspect: f32 = @as(f32, @floatFromInt(self.screenWidth)) / @as(f32, @floatFromInt(self.screenHeight));

        self.projection = math.Mat4x4.perspective(
            math.degreesToRadians(self.fov),
            aspect,
            self.near,
            self.far,
        );
    }
};

fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw:{}: {s}\n", .{ error_code, description });
}

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}
