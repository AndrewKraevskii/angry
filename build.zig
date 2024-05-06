const std = @import("std");

pub fn build(b: *std.Build) void {
    const game_only = b.option(bool, "game_only", "only build the game shared library") orelse false;
    const lib_name = b.option([]const u8, "lib_name", "name to use when building shared") orelse "game";

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const shared_lib = b.addSharedLibrary(.{
        .name = lib_name,
        .root_source_file = b.path("src/game.zig"),
        .target = target,
        .optimize = optimize,
    });

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
    const rlgl = raylib_dep.module("rlgl");
    const raylib_artifact = raylib_dep.artifact("raylib");

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raylib-math", raylib_math);
    exe.root_module.addImport("rlgl", rlgl);

    shared_lib.linkLibrary(raylib_artifact);
    shared_lib.root_module.addImport("raylib", raylib);
    shared_lib.root_module.addImport("raylib-math", raylib_math);
    shared_lib.root_module.addImport("rlgl", rlgl);

    exe.linkLibrary(shared_lib);
    // _ = lib_only;
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
