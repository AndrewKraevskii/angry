const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    build_plain(b, target, optimize);
}

fn build_plain(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const exe = b.addExecutable(.{
        .name = "angry",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib");
    const raygui = raylib_dep.module("raygui");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const ztracy = b.dependency("ztracy", .{
        .enable_ztracy = true,
        .enable_fibers = true,
    });
    exe.root_module.addImport("ztracy", ztracy.module("root"));
    exe.linkLibrary(ztracy.artifact("tracy"));

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);

    exe.linkLibC();
    linkWithBox2d(b, exe);

    const run_cmd = b.addRunArtifact(exe);

    b.installArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const testing = b.addTest(.{
        .name = "angry-test",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    testing.linkLibrary(raylib_artifact);
    testing.root_module.addImport("raylib", raylib);

    testing.linkLibC();
    linkWithBox2d(b, testing);

    b.installArtifact(exe);

    const test_step = b.step("test", "Run tests");
    const run_test = b.addRunArtifact(testing);
    test_step.dependOn(&run_test.step);
}

fn linkWithBox2d(
    b: *std.Build,
    lib: *std.Build.Step.Compile,
) void {
    lib.linkLibC();

    const box2c = b.dependency("box2d", .{});

    lib.addIncludePath(box2c.path("src"));
    lib.addIncludePath(box2c.path("include"));
    lib.addIncludePath(box2c.path("extern/simde"));

    inline for (&[_][]const u8{
        "aabb.c",
        "allocate.c",
        "array.c",
        "bitset.c",
        "block_array.c",
        "body.c",
        "broad_phase.c",
        "constraint_graph.c",
        "contact.c",
        "contact_solver.c",
        "core.c",
        "distance.c",
        "distance_joint.c",
        "dynamic_tree.c",
        "geometry.c",
        "hull.c",
        "id_pool.c",
        "island.c",
        "joint.c",
        "manifold.c",
        "math_functions.c",
        "motor_joint.c",
        "mouse_joint.c",
        "prismatic_joint.c",
        "revolute_joint.c",
        "shape.c",
        "solver.c",
        "solver_set.c",
        "stack_allocator.c",
        "table.c",
        "timer.c",
        "types.c",
        "weld_joint.c",
        "wheel_joint.c",
        "world.c",
    }) |file| {
        lib.addCSourceFile(.{
            .file = box2c.path(b.pathJoin(&.{ "src", file })),
        });
    }
}
