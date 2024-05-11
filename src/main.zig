const std = @import("std");

const GameState = @import("game.zig").GameState;
const Action = @import("game.zig").Action;
const gameTick = @import("game.zig").gameTick;

pub const window_size = .{ 1920, 1080 };

pub fn main() !void {
    const alloc = std.heap.c_allocator;

    var state = try GameState.init(alloc);

    while (true) {
        switch (gameTick(&state)) {
            .none => {},
            .exit => break,
            .restart => {
                break;
            },
        }
    }
    state.deinit();
}
