const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

pub const Engine = struct {
    window: glfw.Window = undefined,

    const Self = @This();

    pub fn init(self: *Self) !glfw.Window {
        glfw.setErrorCallback(errorCallback);
        if (!glfw.init(.{})) {
            std.log.err("Failed to init glfw: {?s}", .{glfw.getErrorString()});
            std.process.exit(1);
        }

        const window = glfw.Window.create(
            1280,
            720,
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

fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw:{}: {s}\n", .{ error_code, description });
}

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}
