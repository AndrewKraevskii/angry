const std = @import("std");
const Watcher = @import("./Watcher.zig");

const GameState = @import("./game.zig").GameState;
const Action = @import("game.zig").Action;

pub const window_size = .{ 1920, 1080 };

var gameTick: *const fn (self: *GameState) callconv(.C) Action = undefined;

fn compileShared(num: u32) !void {
    var buffer: [16 * 4096]u8 = undefined;
    var alloc = std.heap.FixedBufferAllocator.init(&buffer);

    var buf: [256]u8 = undefined;
    const name = std.fmt.bufPrint(
        &buf,
        "-Dlib_name={}",
        .{num},
    ) catch unreachable;
    const process_args = [_][]const u8{
        "zig",
        "build",
        "-Dgame_only=true",
        "-Dhot_reload=true",
        name,
    };

    const res = try std.ChildProcess.run(.{
        .allocator = alloc.allocator(),
        .argv = process_args[0..],
    });

    switch (res.term) {
        .Exited => |code| {
            if (code != 0) {
                std.log.info(
                    "Failed: {s}\n{s}",
                    .{ res.stdout, res.stderr },
                );
                return error.FailedToRecompile;
            }
        },
        else => {},
    }
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
    if (inited) {
        mutex.lock();
        defer mutex.unlock();
        loaded_lib.close();
    } else {
        inited = true;
    }
    loaded_lib = shared_lib;
}

var mutex: std.Thread.Mutex = .{};

var inited = false;
var loaded_lib: std.DynLib = undefined;

pub fn main() !void {
    const alloc = std.heap.c_allocator;

    try compileShared(0);
    try loadShared(0);
    var state = try GameState.init(alloc);

    const updater = try std.Thread.spawn(.{}, update, .{});

    while (true) {
        mutex.lock();

        defer mutex.unlock();
        switch (gameTick(&state)) {
            .none => {},
            .exit => break,
            .restart => {
                restart(alloc);
                break;
            },
        }
    }
    updater.detach();
    state.deinit();
}

// TODO: better name
fn update() !void {
    var watcher = try Watcher.init();
    errdefer watcher.deinit();
    const dir = try std.fs.cwd().openDir("src", .{
        .iterate = true,
    });

    var iterator = dir.iterate();
    while (try iterator.next()) |file| {
        if (file.kind == .file) {
            std.log.debug("listen to file: {s}", .{file.name});
            var buf: [std.os.linux.PATH_MAX]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "src/{s}", .{file.name});
            try watcher.addFile(path);
        }
    }
    var i: usize = 1;
    while (true) : (i += 1) {
        try watcher.listen();

        compileShared(@intCast(i)) catch
            continue;

        try loadShared(@intCast(i));

        std.log.info("hot realoaded", .{});
    }
}

fn restart(alloc: std.mem.Allocator) void {
    var child = std.process.Child.init(&[_][]const u8{ "zig", "build", "run" }, alloc);
    child.spawn() catch {};
}
