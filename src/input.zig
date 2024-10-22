const std = @import("std");

const math = @import("math");
const glfw = @import("mach-glfw");

const Event = struct {
    key: glfw.Key,
    scancode: i32,
    action: glfw.Action,
    mods: glfw.Mods,
};

var keyEvents: std.BoundedArray(Event, 16) = std.BoundedArray(Event, 16).init(0) catch unreachable;

fn getKeyState(window: *const glfw.Window, key: Key) State {
    const state = window.getKey(keyToGlfw(key));
    return switch (state) {
        .press => .Press,
        .repeat => .Hold,
        .release => .Release,
    };
}

pub fn keyCallBack(window: glfw.Window, key: glfw.Key, scancode: i32, action: glfw.Action, mods: glfw.Mods) void {
    keyEvents.append(.{
        .key = key,
        .scancode = scancode,
        .action = action,
        .mods = mods,
    }) catch {};
    _ = window;
}
pub fn clearEvents() void {
    keyEvents.len = 0;
}

pub const State = enum { Press, Release, Hold, None };

pub const Key = enum { A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z, One, Two, Three, Four, Five, Six, Seven, Eight, Nine, Zero, Up, Down, Left, Right, Escape, Space, LeftShift, LeftCtrl, LeftAlt, RightShift, RightCtrl, RightAlt, Enter, Backspace, Tab, CapsLock, F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, Insert, Delete, Home, End, PageUp, PageDown, Plus, Minus, Period, Comma, Slash, Semicolon, Apostrophe, LeftBracket, RightBracket, Backslash, Tilde };

pub fn keyToGlfw(key: Key) glfw.Key {
    return switch (key) {
        .A => glfw.Key.a,
        .B => glfw.Key.b,
        .C => glfw.Key.c,
        .D => glfw.Key.d,
        .E => glfw.Key.e,
        .F => glfw.Key.f,
        .G => glfw.Key.g,
        .H => glfw.Key.h,
        .I => glfw.Key.i,
        .J => glfw.Key.j,
        .K => glfw.Key.k,
        .L => glfw.Key.l,
        .M => glfw.Key.m,
        .N => glfw.Key.n,
        .O => glfw.Key.o,
        .P => glfw.Key.p,
        .Q => glfw.Key.q,
        .R => glfw.Key.r,
        .S => glfw.Key.s,
        .T => glfw.Key.t,
        .U => glfw.Key.u,
        .V => glfw.Key.v,
        .W => glfw.Key.w,
        .X => glfw.Key.x,
        .Y => glfw.Key.y,
        .Z => glfw.Key.z,
        .One => glfw.Key.one,
        .Two => glfw.Key.two,
        .Three => glfw.Key.three,
        .Four => glfw.Key.four,
        .Five => glfw.Key.five,
        .Six => glfw.Key.six,
        .Seven => glfw.Key.seven,
        .Eight => glfw.Key.eight,
        .Nine => glfw.Key.nine,
        .Zero => glfw.Key.zero,
        .Up => glfw.Key.up,
        .Down => glfw.Key.down,
        .Left => glfw.Key.left,
        .Right => glfw.Key.right,
        .Escape => glfw.Key.escape,
        .Space => glfw.Key.space,
        .LeftShift => glfw.Key.left_shift,
        .LeftCtrl => glfw.Key.left_control,
        .LeftAlt => glfw.Key.left_alt,
        .RightShift => glfw.Key.right_shift,
        .RightCtrl => glfw.Key.right_control,
        .RightAlt => glfw.Key.right_alt,
        .Enter => glfw.Key.enter,
        .Backspace => glfw.Key.backspace,
        .Tab => glfw.Key.tab,
        .CapsLock => glfw.Key.caps_lock,
        .F1 => glfw.Key.F1,
        .F2 => glfw.Key.F2,
        .F3 => glfw.Key.F3,
        .F4 => glfw.Key.F4,
        .F5 => glfw.Key.F5,
        .F6 => glfw.Key.F6,
        .F7 => glfw.Key.F7,
        .F8 => glfw.Key.F8,
        .F9 => glfw.Key.F9,
        .F10 => glfw.Key.F10,
        .F11 => glfw.Key.F11,
        .F12 => glfw.Key.F12,
        .Insert => glfw.Key.insert,
        .Delete => glfw.Key.delete,
        .Home => glfw.Key.home,
        .End => glfw.Key.end,
        .PageUp => glfw.Key.page_up,
        .PageDown => glfw.Key.page_down,
        .Plus => glfw.Key.kp_add,
        .Minus => glfw.Key.kp_subtract,
        .Period => glfw.Key.period,
        .Comma => glfw.Key.comma,
        .Slash => glfw.Key.slash,
        .Semicolon => glfw.Key.semicolon,
        .Apostrophe => glfw.Key.apostrophe,
        .LeftBracket => glfw.Key.left_bracket,
        .RightBracket => glfw.Key.right_bracket,
        .Backslash => glfw.Key.backslash,
        .Tilde => glfw.Key.grave_accent,
    };
}

pub fn isPressed(window: *const glfw.Window, key: Key) bool {
    return getKeyState(window, key) == .Press;
}

pub fn isJustPressed(key: Key) bool {
    for (keyEvents.constSlice()) |event| {
        if (event.key == keyToGlfw(key) and event.action == .press) {
            return true;
        }
    }
    return false;
}

pub fn isReleased(key: Key) bool {
    for (keyEvents.constSlice()) |event| {
        if (event.key == keyToGlfw(key) and event.action == .release) {
            return true;
        }
    }
    return false;
}
