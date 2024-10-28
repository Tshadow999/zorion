const std = @import("std");

pub const math = @import("math");
pub const glfw = @import("mach-glfw");
pub const gl = @import("gl");

// Other imports
pub const primitive = @import("core/primitives.zig");
pub const resource = @import("core/resources.zig");
pub const Color = @import("color.zig");
pub const Zorion = @import("core/zorion.zig");
pub const input = @import("core/input.zig");
pub const c = @import("c.zig");

// Resource definitions
pub const Mesh = resource.Mesh;
pub const Shader = resource.Shader;
pub const Object = resource.Object;
pub const Texture = resource.Texture;
pub const Material = resource.Material;
