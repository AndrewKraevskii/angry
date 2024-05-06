const rl = @import("raylib");

const GameState = @import("main.zig").GameState;
const Action = @import("main.zig").Action;

export fn gameTick(state: *GameState) Action {
    // update phisics

    // draw screen
    rl.beginDrawing();
    rl.clearBackground(rl.Color.black);

    rl.drawLine(
        0,
        0,
        @intFromFloat(state.position[0]),
        @intFromFloat(state.position[1]),
        rl.Color.red,
    );

    rl.endDrawing();
    state.position[0] = @floatCast(500 + 39 * @sin(rl.getTime()));
    state.position[1] = @floatCast(500 + 314 * @cos(rl.getTime()));

    if (rl.windowShouldClose()) {
        return .exit;
    }
    return .none;
}
