const std = @import("std");

const _engine = @import("engine");
const Engine = _engine.Zorion.Engine;
const Input = _engine.Input;

const glfw = _engine.glfw;
const math = _engine.math;
const gl = _engine.gl;

const zgui = @import("zgui");

pub fn main() !void {
    // Creating the engine
    var engine = Engine{};
    const window = try engine.init(.{ .fullscreen = false });
    _ = window;
    defer engine.deinit();

    while (engine.isRunning()) {
        engine.render();

        // Quick escape
        if (Input.isJustPressed(.Escape)) {
            engine.quit();
        }
    }
}
