const std = @import("std");

const glfw = @import("mach-glfw");
const math = @import("math");
const gl = @import("gl");

const input = @import("input.zig");
const resource = @import("resources.zig");
const Scene = resource.Scene;

pub const WindowProps = struct {
    width: u32 = 1280,
    height: u32 = 720,
    title: [:0]const u8 = "Zorion Engine",
    vsync: bool = true,
    fullscreen: bool = true,
};

pub const Engine = struct {
    window: glfw.Window = undefined,
    camera: Camera3D = .{},
    scene: ?Scene = null,

    pub fn init(self: *Engine, windowProps: WindowProps) !glfw.Window {

        // Handle glfw callbacks
        glfw.setErrorCallback(errorCallback);
        if (!glfw.init(.{})) {
            std.log.err("Failed to init glfw: {?s}", .{glfw.getErrorString()});
            std.process.exit(1);
        }

        // Full screen check
        const monitor: glfw.Monitor = glfw.Monitor.getPrimary() orelse unreachable;
        const mode = monitor.getVideoMode() orelse unreachable;

        const width = if (windowProps.fullscreen) mode.getWidth() else windowProps.width;
        const height = if (windowProps.fullscreen) mode.getHeight() else windowProps.height;

        const windowHints: glfw.Window.Hints = if (windowProps.fullscreen) .{
            .red_bits = @intCast(mode.getRedBits()),
            .green_bits = @intCast(mode.getGreenBits()),
            .blue_bits = @intCast(mode.getBlueBits()),
            .refresh_rate = @intCast(mode.getRefreshRate()),
        } else .{};

        // Create a window
        const window = glfw.Window.create(
            width,
            height,
            windowProps.title,
            if (windowProps.fullscreen) monitor else null,
            null,
            windowHints,
        ) orelse {
            std.log.err("Failed to create GLFW window: {?s}", .{glfw.getErrorString()});
            std.process.exit(1);
        };
        self.window = window;

        // Set up some callbacks
        self.window.setFramebufferSizeCallback(frameBufferChangedCallback);
        self.window.setCursorPosCallback(getMousePosCallback);

        glfw.makeContextCurrent(self.window);

        const proc: glfw.GLProc = undefined;
        try gl.load(proc, glGetProcAddress);

        // One time enables
        gl.enable(gl.DEPTH_TEST);

        gl.enable(gl.CULL_FACE);
        gl.cullFace(gl.BACK);
        self.window.setInputModeCursor(.disabled);

        gl.polygonMode(gl.FRONT, gl.FILL); // Possible modes: point, line or fill

        gl.viewport(0, 0, @as(c_int, @intCast(width)), @as(c_int, @intCast(height)));

        self.camera.screenWidth = windowProps.width;
        self.camera.screenHeight = windowProps.height;
        self.camera.UpdateProjection();

        return self.window;
    }

    pub fn render(self: *Engine) void {
        input.resetMouseRelative();
        self.window.swapBuffers();

        glfw.pollEvents();

        gl.clearColor(0.3, 0.1, 0.3, 1);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    }

    pub fn isRunning(self: *Engine) bool {
        return !self.window.shouldClose();
    }

    pub fn createScene(self: *Engine) void {
        self.scene = .{ .objects = .{} };
    }
    pub fn quit(self: *Engine) void {
        self.window.setShouldClose(true);
    }

    pub fn deinit(self: *Engine) void {
        self.window.destroy();
        glfw.terminate();
    }
};

pub const Camera3D = struct {
    projection: math.Mat4x4 = math.Mat4x4.ident,
    view: math.Mat4x4 = math.Mat4x4.ident,

    fov: f32 = 80,
    // Projection fixed now?
    near: f32 = -1,
    far: f32 = 1,

    screenWidth: u32 = undefined,
    screenHeight: u32 = undefined,

    pub fn UpdateProjection(
        self: *Camera3D,
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

// Window callbacks

fn frameBufferChangedCallback(window: glfw.Window, width: u32, height: u32) void {
    gl.viewport(0, 0, @as(c_int, @intCast(width)), @as(c_int, @intCast(height)));
    _ = window;
}

fn getMousePosCallback(window: glfw.Window, xpos: f64, ypos: f64) void {
    input.mousePosCallback(@floatCast(xpos), @floatCast(ypos));
    _ = window;
}

// Other

fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw:{}: {s}\n", .{ error_code, description });
}

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}
