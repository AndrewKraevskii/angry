const std = @import("std");

pub fn build(b: *std.Build) void {
    const with_hot_reloading = b.option(bool, "hot_reload", "add ability to hot reload game (linux only)") orelse
        false;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    if (with_hot_reloading) {
        build_hot_reload(b, target, optimize);
    } else {
        build_plain(b, target, optimize);
    }
}

fn build_hot_reload(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const game_only = b.option(bool, "game_only", "only build the game shared library") orelse false;
    const lib_name = b.option([]const u8, "lib_name", "name to use when building shared") orelse "game";
    const shared_lib = b.addSharedLibrary(.{
        .name = lib_name,
        .root_source_file = b.path("src/hot_game.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "angry",
        .root_source_file = b.path("src/hot_main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib");
    const raylib_math = raylib_dep.module("raylib-math");
    const rlgl = raylib_dep.module("rlgl");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const options = b.addOptions();
    options.addOption(bool, "hot_reload", true);

    exe.root_module.addOptions("config", options);
    shared_lib.root_module.addOptions("config", options);

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raylib-math", raylib_math);
    exe.root_module.addImport("rlgl", rlgl);

    shared_lib.linkLibrary(raylib_artifact);
    shared_lib.root_module.addImport("raylib", raylib);
    shared_lib.root_module.addImport("raylib-math", raylib_math);
    shared_lib.root_module.addImport("rlgl", rlgl);

    shared_lib.linkLibC();
    linkWithBox2d(b, shared_lib);
    linkWithBox2d(b, exe);

    exe.linkLibrary(shared_lib);
    const run_cmd = b.addRunArtifact(exe);
    if (game_only) {
        b.installArtifact(shared_lib);
    } else {
        b.installArtifact(exe);
        b.installArtifact(shared_lib);
    }

    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
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
    const raylib_math = raylib_dep.module("raylib-math");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const ztracy = b.dependency("ztracy", .{
        .enable_ztracy = true,
        .enable_fibers = true,
    });
    exe.root_module.addImport("ztracy", ztracy.module("root"));
    exe.linkLibrary(ztracy.artifact("tracy"));

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raylib-math", raylib_math);

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
    testing.root_module.addImport("raylib-math", raylib_math);

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
        "block_allocator.c",
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
        "implementation.c",
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
