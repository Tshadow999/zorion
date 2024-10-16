const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

const math = @import("math");

pub const Engine = struct {
    window: glfw.Window = undefined,
    camera: Camera3D = .{},

    const Self = @This();

    pub fn init(self: *Self, screenWidth: u16, screenHeight: u16) !glfw.Window {
        if (screenWidth < 300 or screenHeight < 300) {
            std.log.err("Invalid screen size", .{});
            std.process.exit(1);
        }

        // Handle glfw callbacks
        glfw.setErrorCallback(errorCallback);
        if (!glfw.init(.{})) {
            std.log.err("Failed to init glfw: {?s}", .{glfw.getErrorString()});
            std.process.exit(1);
        }

        // Create a window
        const window = glfw.Window.create(
            screenWidth,
            screenHeight,
            "Zorion Engine",
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

        self.camera.UpdateProjection();

        return self.window;
    }

    pub fn render(self: *Self) void {
        self.window.swapBuffers();

        glfw.pollEvents();

        gl.clearColor(0.3, 0.1, 0.3, 1);
        gl.clear(gl.COLOR_BUFFER_BIT);
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
    aspect: f32 = 16.0 / 9.0,
    near: f32 = -1 + 0.1,
    far: f32 = 10_000,

    const Self = @This();

    pub fn UpdateProjection(
        self: *Self,
    ) void {
        self.projection = math.Mat4x4.perspective(
            math.degreesToRadians(self.fov),
            self.aspect,
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
