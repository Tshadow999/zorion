const std = @import("std");

const mach_glfw = @import("mach_glfw");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Run steps in here
    buildExamples(b, target, optimize);
}

// Add examples to the build system
// Copied from mach
fn buildExamples(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    for ([_]struct { name: []const u8 }{
        .{ .name = "sandbox" },
        .{ .name = "game1" },
    }) |example| {
        const exe = b.addExecutable(.{
            .name = example.name,
            .root_source_file = b.path(b.fmt("examples/{s}/main.zig", .{example.name})),
            .target = target,
            .optimize = optimize,
        });

        addDependencies(exe, b, target, optimize);
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step(b.fmt("run-{s}", .{example.name}), b.fmt("Run {s}", .{example.name}));
        run_step.dependOn(&run_cmd.step);
    }
}

// This is where all the dependencies should be added
// Copied from Shakedown Engine
fn addDependencies(
    exe: *std.Build.Step.Compile,
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    // Use mach-glfw
    const glfw_dep = b.dependency("mach_glfw", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("mach-glfw", glfw_dep.module("mach-glfw"));

    // gl
    const glModule = b.createModule(.{
        .root_source_file = b.path("deps/gl41.zig"),
    });
    exe.root_module.addImport("gl", glModule);

    // mach math
    const mathModule = b.createModule(.{ .root_source_file = b.path("deps/math/main.zig") });
    exe.root_module.addImport("math", mathModule);

    // Maybe need this later: zgltf
    // exe.root_module.addImport("zgltf", b.dependency("zgltf", .{
    //     .target = target,
    //     .optimize = optimize,
    // }).module("zgltf"));

    // Add our own src as well
    exe.root_module.addImport("engine", b.createModule(.{
        .root_source_file = b.path("src/engine.zig"),
        .imports = &.{
            .{ .name = "mach-glfw", .module = glfw_dep.module("mach-glfw") },
            .{ .name = "gl", .module = glModule },
            .{ .name = "math", .module = mathModule },
        },
        .link_libc = true,
    }));

    // Include C
    exe.linkLibC();
    exe.addCSourceFile(.{ .file = b.path("deps/stb_image.c"), .flags = &.{} });
    // exe.addCSourceFile(.{ .file = b.path("deps/cgltf.c"), .flags = &.{} });

    exe.addIncludePath(b.path("deps"));
}
