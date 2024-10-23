const std = @import("std");

const math = @import("math");
const gl = @import("gl");

const resources = @import("resources.zig");

const Mesh = resources.Mesh;
const Vertex = resources.Vertex;

fn circlePoints(points: *std.ArrayList(math.Vec3), sides: u32, radius: f32) !void {
    for (0..sides + 1) |i| {
        const theta: f32 = @as(f32, @floatFromInt(i)) * math.tau / @as(f32, @floatFromInt(sides));
        const ci = math.vec3(@cos(theta) * radius, 0, @sin(theta) * radius);
        try points.append(ci);
    }
}

pub fn sphere(mesh: *Mesh, radius: f32, verticalSegments: u32, radialSegments: u32) !void {
    const vertSegs: u32 = if (verticalSegments < 3) 3 else verticalSegments;
    const radSegs: u32 = if (radialSegments < 3) 3 else radialSegments;

    mesh.vertices.clearRetainingCapacity();
    mesh.indices.clearRetainingCapacity();

    for (0..vertSegs + 1) |v| {
        const height = -@cos(@as(f32, @floatFromInt(v)) / @as(f32, @floatFromInt(vertSegs)) * math.pi) * radius;
        const ringRadius = @sin(@as(f32, @floatFromInt(v)) / @as(f32, @floatFromInt(vertSegs)) * math.pi) * radius;

        var buffer: [256 * @sizeOf(math.Vec3)]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buffer);

        var verts = std.ArrayList(math.Vec3).init(fba.allocator());
        defer verts.deinit();

        try circlePoints(&verts, vertSegs, ringRadius);

        for (0..radSegs + 1) |i| {
            verts.items[i].v[1] += height;
            try mesh.vertices.append(Vertex{ .position = verts.items[i] });
        }
    }

    for (mesh.vertices.items) |*vertex| {
        vertex.normal = vertex.position.normalize(0.01);
    }

    for (0..radSegs) |r| {
        for (0..vertSegs) |v| {
            const index0 = (radSegs + 1) * v + r;
            const index1 = (radSegs + 1) * v + r + 1;
            const index2 = (radSegs + 1) + index0;
            const index3 = (radSegs + 1) + index1;

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
    const vertices = [24]Vertex{
        // Front face
        .{ .position = math.vec3(0, 0, 0), .normal = math.vec3(0, 0, 1) },
        .{ .position = math.vec3(size, 0, 0), .normal = math.vec3(0, 0, 1) },
        .{ .position = math.vec3(size, size, 0), .normal = math.vec3(0, 0, 1) },
        .{ .position = math.vec3(0, size, 0), .normal = math.vec3(0, 0, 1) },

        // Back face
        .{ .position = math.vec3(0, 0, size), .normal = math.vec3(0, 0, -1) },
        .{ .position = math.vec3(size, 0, size), .normal = math.vec3(0, 0, -1) },
        .{ .position = math.vec3(size, size, size), .normal = math.vec3(0, 0, -1) },
        .{ .position = math.vec3(0, size, size), .normal = math.vec3(0, 0, -1) },

        // Left face
        .{ .position = math.vec3(0, 0, 0), .normal = math.vec3(-1, 0, 0) },
        .{ .position = math.vec3(0, size, 0), .normal = math.vec3(-1, 0, 0) },
        .{ .position = math.vec3(0, size, size), .normal = math.vec3(-1, 0, 0) },
        .{ .position = math.vec3(0, 0, size), .normal = math.vec3(-1, 0, 0) },

        // Right face
        .{ .position = math.vec3(size, 0, 0), .normal = math.vec3(1, 0, 0) },
        .{ .position = math.vec3(size, size, 0), .normal = math.vec3(1, 0, 0) },
        .{ .position = math.vec3(size, size, size), .normal = math.vec3(1, 0, 0) },
        .{ .position = math.vec3(size, 0, size), .normal = math.vec3(1, 0, 0) },

        // Top face
        .{ .position = math.vec3(0, size, 0), .normal = math.vec3(0, 1, 0) },
        .{ .position = math.vec3(size, size, 0), .normal = math.vec3(0, 1, 0) },
        .{ .position = math.vec3(size, size, size), .normal = math.vec3(0, 1, 0) },
        .{ .position = math.vec3(0, size, size), .normal = math.vec3(0, 1, 0) },

        // Bottom face
        .{ .position = math.vec3(0, 0, 0), .normal = math.vec3(0, -1, 0) },
        .{ .position = math.vec3(size, 0, 0), .normal = math.vec3(0, -1, 0) },
        .{ .position = math.vec3(size, 0, size), .normal = math.vec3(0, -1, 0) },
        .{ .position = math.vec3(0, 0, size), .normal = math.vec3(0, -1, 0) },
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

    mesh.vertices.clearRetainingCapacity();
    mesh.indices.clearRetainingCapacity();

    for (vertices) |vertex| {
        try mesh.vertices.append(vertex);
    }

    for (indices) |index| {
        try mesh.indices.append(index);
    }
}

pub fn quad(mesh: *Mesh, width: f32, height: f32) !void {
    mesh.vertices.clearRetainingCapacity();
    mesh.indices.clearRetainingCapacity();

    // Always forwards for now
    const squareVerts = [4]Vertex{
        .{
            .position = math.vec3(0, 0, 0),
            .normal = math.vec3(0, 0, 1),
            .uv = math.vec2(0, 0),
        },
        .{
            .position = math.vec3(width, 0, 0),
            .normal = math.vec3(0, 0, 1),
            .uv = math.vec2(1.0, 0),
        },
        .{
            .position = math.vec3(width, height, 0),
            .normal = math.vec3(0, 0, 1),
            .uv = math.vec2(1.0, 1.0),
        },
        .{
            .position = math.vec3(0, height, 0),
            .normal = math.vec3(0, 0, 1),
            .uv = math.vec2(0, 1.0),
        },
    };

    const squareIndices = [6]u32{
        0, 1, 2, // Triangle 1
        0, 2, 3, // Triangle 2
    };

    try mesh.vertices.appendSlice(&squareVerts);
    try mesh.indices.appendSlice(&squareIndices);
}
