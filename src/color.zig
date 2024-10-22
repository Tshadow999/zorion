const std = @import("std");

const math = @import("math");

r: f32 = 0.0,
g: f32 = 0.0,
b: f32 = 0.0,
a: f32 = 1.0,

const Color = @This();

pub fn init(r: f32, g: f32, b: f32, a: f32) Color {
    return .{ .r = r, .g = g, .b = b, .a = a };
}

pub fn setAlpha(self: Color, a: f32) Color {
    return .{ .r = self.r, .g = self.g, .b = self.b, .a = a };
}

pub fn multiplyRGB(self: Color, multiplicant: f32) Color {
    return .{
        .r = self.r * multiplicant,
        .g = self.g * multiplicant,
        .b = self.b * multiplicant,
        .a = self.a,
    };
}

pub fn clamp01(self: Color) Color {
    return .{
        .r = @max(@min(self.r, 1), 0),
        .g = @max(@min(self.g, 1), 0),
        .b = @max(@min(self.b, 1), 0),
        .a = @max(@min(self.a, 1), 0),
    };
}

pub fn toVec(self: Color) @Vector(4, f32) {
    return .{ self.r, self.g, self.b, self.a };
}

pub fn toVec3(self: Color) math.Vec3 {
    return .{ .v = .{ self.r, self.g, self.b } };
}

pub fn toVec4(self: Color) math.Vec4 {
    return .{ .v = toVec(self) };
}

pub fn fromVec(v: @Vector(4, f32)) Color {
    return .{ .r = v[0], .g = v[1], .b = v[2], .a = v[3] };
}

pub fn from255(self: Color) Color {
    return .{
        .r = @as(f32, self.r / 255),
        .g = @as(f32, self.g / 255),
        .b = @as(f32, self.b / 255),
        .a = @as(f32, self.a / 255),
    };
}

pub const white = init(1.0, 1.0, 1.0, 1.0);
pub const black = init(0.0, 0.0, 0.0, 1.0);
pub const clear = init(0.0, 0.0, 0.0, 0.0);

pub const red = init(1.0, 0.0, 0.0, 1.0);
pub const green = init(0.0, 1.0, 0.0, 1.0);
pub const blue = init(0.0, 0.0, 1.0, 1.0);

// TODO add more
