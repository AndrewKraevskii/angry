const std = @import("std");
const rl = @import("raylib");
const box2d = @import("./box2d.zig");
const raymath = @import("raylib-math");

pub const GameState = struct {
    alloc: std.mem.Allocator,
    position: @Vector(2, f32),
};

pub const Action = enum(u8) {
    none,
    exit,
};

const box_height = 10;
const window_size = .{ 1920, 1080 };

// TODO: make it atomic (works fine without it)
var gameTick: *const fn (self: *GameState) Action = undefined;

fn compileShared(alloc: std.mem.Allocator, num: u32) !void {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();

    var buf: [256]u8 = undefined;
    const name = std.fmt.bufPrint(
        &buf,
        "-Dlib_name={}",
        .{num},
    ) catch unreachable;
    const process_args = [_][]const u8{ "zig", "build", "-Dgame_only=true", name };
    const res = try std.ChildProcess.run(.{
        .allocator = arena.allocator(),
        .argv = process_args[0..],
    });

    std.log.info(
        "Recompiled: {s}\n{s}",
        .{ res.stdout, res.stderr },
    );
}

fn loadShared(num: u32) !void {
    var buf: [256]u8 = undefined;
    const name = std.fmt.bufPrint(
        &buf,
        "zig-out/lib/lib{}.so",
        .{num},
    ) catch unreachable;
    var shared_lib = try std.DynLib.open(name);
    gameTick = shared_lib.lookup(@TypeOf(gameTick), "gameTick") orelse return error.SymbolNotFound;
}

pub fn main() !void {
    const alloc = std.heap.c_allocator;

    var state = GameState{
        .position = .{ 50.0, 50.0 },
        .alloc = alloc,
    };
    rl.initWindow(window_size[0], window_size[1], "Angry");
    var i: u32 = 0;
    try compileShared(alloc, i);
    try loadShared(i);
    i += 1;

    while (true) {
        const action = gameTick(&state);
        switch (action) {
            .none => {},
            .exit => break,
        }

        if (rl.isKeyPressed(rl.KeyboardKey.key_r)) {
            const proc = try std.Thread.spawn(.{}, struct {
                fn exec(num: u32) !void {
                    try compileShared(alloc, num);
                    try loadShared(num);
                }
            }.exec, .{i});
            proc.detach();
            i += 1;
        }
    }

    rl.closeWindow();
}
