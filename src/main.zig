const std = @import("std");

const GameState = @import("game.zig").GameState;
const Action = @import("game.zig").Action;
const gameTick = @import("game.zig").gameTick;
const sheet = @import("aseprite/SpriteSheet.zig");

pub const window_size = .{ 1280, 720 };

pub fn main() !void {
    const alloc = std.heap.c_allocator;

    var state = try GameState.init(alloc);
    std.log.info("Game initialized", .{});

    while (true) {
        switch (gameTick(&state) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
        }) {
            .none => {},
            .exit => {
                std.log.info("Exiting", .{});
                break;
            },
            .restart => {
                std.log.info("Tried to restart but it is not hot reloaded", .{});
                break;
            },
        }
    }
    std.log.info("Closing game", .{});
    state.deinit();
}

test {
    @setEvalBranchQuota(1000);
    _ = sheet;
    std.testing.refAllDeclsRecursive(@This());
}
