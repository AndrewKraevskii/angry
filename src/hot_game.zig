const State = @import("./game.zig").GameState;
const Action = @import("./game.zig").Action;
const std = @import("std");

export fn gameTick(state: *State) Action {
    return @import("game.zig").gameTick(state) catch |err| {
        std.log.err("{s}", @errorName(err));
    };
}
