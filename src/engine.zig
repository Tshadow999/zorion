const std = @import("std");

// Other imports
const primitive = @import("core/primitives.zig");
const resource = @import("core/resources.zig");
const Color = @import("color.zig");
pub const Zorion = @import("core/zorion.zig");
const input = @import("core/input.zig");
const c = @import("c.zig");

// Resource definitions
const Mesh = resource.Mesh;
const Shader = resource.Shader;
const Object = resource.Object;
const Texture = resource.Texture;
const Material = resource.Material;
