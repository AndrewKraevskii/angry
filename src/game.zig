const std = @import("std");
const rl = @import("raylib");

pub const GameState = struct {
    alloc: std.mem.Allocator,

    pub fn init(alloc: std.mem.Allocator) GameState {
        return .{
            .alloc = alloc,
        };
    }
};

pub const Action = enum(u8) {
    none,
    exit,
    restart,
};

export fn gameTick(state: *GameState) Action {
    // update physics
    // draw screen
    rl.beginDrawing();
    _ = state;
    // rl.clearBackground(rl.Color.white);

    const start_x = rl.getRandomValue(0, 1920);
    const start_y = rl.getRandomValue(0, 1080);
    const end_x = rl.getRandomValue(0, 1920);
    const end_y = rl.getRandomValue(0, 1080);

    const rand = rl.getRandomValue(
        0,
        254,
    );
    // std.debug.print("{d}\n", .{rand});

    // const color: rl.Color = @bitCast(rand);

    rl.drawLine(
        start_x,
        start_y,
        end_x,
        end_y,
        .{
            .r = @intCast(rand),
            .g = @truncate(@abs(start_x)),
            .b = @truncate(@abs(start_y)),
            .a = 255,
        },
    );

    rl.endDrawing();
    if (rl.windowShouldClose()) {
        return .exit;
    }
    if (rl.isKeyPressed(rl.KeyboardKey.key_r)) {
        return .restart;
    }
    return .none;
}
