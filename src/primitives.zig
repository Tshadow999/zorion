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

        // vertSegs maybe?
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