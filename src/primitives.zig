const std = @import("std");

const math = @import("math");
const gl = @import("gl");

const resources = @import("resources.zig");
const Color = @import("color.zig");

const Mesh = resources.Mesh;
const Vertex = resources.Vertex;

fn intToF32(value: anytype) f32 {
    return @as(f32, @floatFromInt(value));
}

fn circlePoints(points: []math.Vec3, sides: u32, radius: f32) void {
    for (0..sides + 1) |i| {
        const theta: f32 = @as(f32, @floatFromInt(i)) * math.tau / @as(f32, @floatFromInt(sides));
        const ci = math.vec3(@cos(theta) * radius, 0, @sin(theta) * radius);
        points[i] = ci;
    }
}

pub fn sphere(mesh: *Mesh, radius: f32, segments: u32) !void {
    const minSphereSegments: u32 = 4;
    const offset: u32 = @intCast(mesh.vertices.items.len);

    const vertSegs: u32 = if (segments < minSphereSegments) minSphereSegments else segments;
    const radSegs: u32 = if (segments < minSphereSegments) minSphereSegments else segments;

    for (0..vertSegs + 1) |v| {
        const height = -@cos(intToF32(v) / intToF32(vertSegs) * math.pi) * radius;
        const ringRadius = @sin(intToF32(v) / intToF32(vertSegs) * math.pi) * radius;

        var buffer = try std.BoundedArray(math.Vec3, 256).init(radSegs + 1);
        circlePoints(buffer.slice(), vertSegs, ringRadius);

        for (0..radSegs + 1) |i| {
            // plus on1 to rad and vertSegs or no?
            const uv = math.vec2(
                intToF32(i) / intToF32(radSegs),
                intToF32(v) / intToF32(vertSegs),
            );

            const pos = &buffer.slice()[i];

            pos.*.v[1] += height;
            try mesh.vertices.append(Vertex{
                .position = pos.*,
                .normal = pos.*.normalize(0.01),
                .uv = uv,
                .color = Color.white.toVec4(),
            });
        }
    }

    for (0..radSegs) |r| {
        for (0..vertSegs) |v| {
            const index0 = offset + (radSegs + 1) * v + r;
            const index1 = offset + (radSegs + 1) * v + r + 1;
            const index2 = index0 + (radSegs + 1);
            const index3 = index1 + (radSegs + 1);

            try mesh.indices.append(@intCast(index0));
            try mesh.indices.append(@intCast(index1));
            try mesh.indices.append(@intCast(index2));

            try mesh.indices.append(@intCast(index1));
            try mesh.indices.append(@intCast(index3));
            try mesh.indices.append(@intCast(index2));
        }
    }
}

pub fn cube(mesh: *Mesh, size: f32) !void {
    const offset: u32 = @intCast(mesh.vertices.items.len);

    const vertices = [24]Vertex{
        // Front face
        .{ .position = math.vec3(0, 0, 0), .normal = math.vec3(0, 0, 1), .uv = math.vec2(0, 0), .color = Color.white.toVec4() },
        .{ .position = math.vec3(size, 0, 0), .normal = math.vec3(0, 0, 1), .uv = math.vec2(1.0, 0), .color = Color.white.toVec4() },
        .{ .position = math.vec3(size, size, 0), .normal = math.vec3(0, 0, 1), .uv = math.vec2(1.0, 1.0), .color = Color.white.toVec4() },
        .{ .position = math.vec3(0, size, 0), .normal = math.vec3(0, 0, 1), .uv = math.vec2(0, 1.0), .color = Color.white.toVec4() },

        // Back face
        .{ .position = math.vec3(0, 0, size), .normal = math.vec3(0, 0, -1), .uv = math.vec2(1.0, 0), .color = Color.white.toVec4() },
        .{ .position = math.vec3(size, 0, size), .normal = math.vec3(0, 0, -1), .uv = math.vec2(1.0, 0), .color = Color.white.toVec4() },
        .{ .position = math.vec3(size, size, size), .normal = math.vec3(0, 0, -1), .uv = math.vec2(1.0, 1.0), .color = Color.white.toVec4() },
        .{ .position = math.vec3(0, size, size), .normal = math.vec3(0, 0, -1), .uv = math.vec2(0, 1.0), .color = Color.white.toVec4() },

        // Left face
        .{ .position = math.vec3(0, 0, 0), .normal = math.vec3(-1, 0, 0), .uv = math.vec2(0, 0), .color = Color.white.toVec4() },
        .{ .position = math.vec3(0, size, 0), .normal = math.vec3(-1, 0, 0), .uv = math.vec2(1.0, 0), .color = Color.white.toVec4() },
        .{ .position = math.vec3(0, size, size), .normal = math.vec3(-1, 0, 0), .uv = math.vec2(1.0, 1.0), .color = Color.white.toVec4() },
        .{ .position = math.vec3(0, 0, size), .normal = math.vec3(-1, 0, 0), .uv = math.vec2(0, 1.0), .color = Color.white.toVec4() },

        // Right face
        .{ .position = math.vec3(size, 0, 0), .normal = math.vec3(1, 0, 0), .uv = math.vec2(0, 0), .color = Color.white.toVec4() },
        .{ .position = math.vec3(size, size, 0), .normal = math.vec3(1, 0, 0), .uv = math.vec2(1.0, 0), .color = Color.white.toVec4() },
        .{ .position = math.vec3(size, size, size), .normal = math.vec3(1, 0, 0), .uv = math.vec2(1.0, 1.0), .color = Color.white.toVec4() },
        .{ .position = math.vec3(size, 0, size), .normal = math.vec3(1, 0, 0), .uv = math.vec2(0, 1.0), .color = Color.white.toVec4() },

        // Top face
        .{ .position = math.vec3(0, size, 0), .normal = math.vec3(0, 1, 0), .uv = math.vec2(0, 0), .color = Color.white.toVec4() },
        .{ .position = math.vec3(size, size, 0), .normal = math.vec3(0, 1, 0), .uv = math.vec2(1.0, 0), .color = Color.white.toVec4() },
        .{ .position = math.vec3(size, size, size), .normal = math.vec3(0, 1, 0), .uv = math.vec2(1.0, 1.0), .color = Color.white.toVec4() },
        .{ .position = math.vec3(0, size, size), .normal = math.vec3(0, 1, 0), .uv = math.vec2(0, 1.0), .color = Color.white.toVec4() },

        // Bottom face
        .{ .position = math.vec3(0, 0, 0), .normal = math.vec3(0, -1, 0), .uv = math.vec2(0, 0), .color = Color.white.toVec4() },
        .{ .position = math.vec3(size, 0, 0), .normal = math.vec3(0, -1, 0), .uv = math.vec2(1.0, 0), .color = Color.white.toVec4() },
        .{ .position = math.vec3(size, 0, size), .normal = math.vec3(0, -1, 0), .uv = math.vec2(1.0, 1.0), .color = Color.white.toVec4() },
        .{ .position = math.vec3(0, 0, size), .normal = math.vec3(0, -1, 0), .uv = math.vec2(0, 1.0), .color = Color.white.toVec4() },
    };

    const indices = [36]u32{
        // Front face
        0,  1,  2,
        0,  2,  3,
        // Back face
        4,  6,  5,
        4,  7,  6,
        // Left face
        8,  9,  10,
        8,  10, 11,
        // Right face
        12, 14, 13,
        12, 15, 14,
        // Top face
        16, 17, 18,
        16, 18, 19,
        // Bottom face
        20, 22, 21,
        20, 23, 22,
    };

    for (vertices) |vertex| {
        try mesh.vertices.append(vertex);
    }

    for (indices) |index| {
        try mesh.indices.append(index + offset);
    }
}

pub fn quad(mesh: *Mesh, width: f32, height: f32) !void {
    const offset: u32 = @intCast(mesh.vertices.items.len);

    // Always forwards for now
    const squareVerts = [4]Vertex{
        .{
            .position = math.vec3(0, 0, 0),
            .normal = math.vec3(0, 0, 1),
            .uv = math.vec2(0, 0),
            .color = Color.white.toVec4(),
        },
        .{
            .position = math.vec3(width, 0, 0),
            .normal = math.vec3(0, 0, 1),
            .uv = math.vec2(1.0, 0),
            .color = Color.white.toVec4(),
        },
        .{
            .position = math.vec3(width, height, 0),
            .normal = math.vec3(0, 0, 1),
            .uv = math.vec2(1.0, 1.0),
            .color = Color.white.toVec4(),
        },
        .{
            .position = math.vec3(0, height, 0),
            .normal = math.vec3(0, 0, 1),
            .uv = math.vec2(0, 1.0),
            .color = Color.white.toVec4(),
        },
    };

    const squareIndices = [6]u32{
        offset + 0, offset + 1, offset + 2, // Triangle 1
        offset + 0, offset + 2, offset + 3, // Triangle 2
    };

    try mesh.vertices.appendSlice(&squareVerts);
    try mesh.indices.appendSlice(&squareIndices);
}
