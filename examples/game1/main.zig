const std = @import("std");
const engine = @import("engine");

const glfw = engine.glfw;
const math = engine.math;
const gl = engine.gl;

pub fn main() void {
    std.log.info("Hello from game1", .{});
}
