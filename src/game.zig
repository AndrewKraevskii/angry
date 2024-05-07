const std = @import("std");
const rl = @import("raylib");

pub const GameState = struct {
    alloc: std.mem.Allocator,
    texture: rl.Texture,
    position: rl.Vector2,
    speed: rl.Vector2,

    pub fn init(alloc: std.mem.Allocator) GameState {
        const dvd = rl.imageText("DVD", 200, rl.Color.blue);
        const texture = rl.loadTextureFromImage(dvd);
        // rl.unloadImage(dvd);
        return .{ .alloc = alloc, .texture = texture, .position = rl.Vector2{
            .x = 10,
            .y = 10,
        }, .speed = rl.Vector2{
            .x = 0.1,
            .y = 0.1,
        } };
    }
};

const Action = @import("main.zig").Action;

export fn gameTick(state: *GameState) Action {
    // update physics
    state.position.x += state.speed.x;
    state.position.y += state.speed.y;

    if (state.position.x < 0) {
        state.speed.x = @abs(state.speed.x);
    }
    if (state.position.y < 0) {
        state.speed.y = @abs(state.speed.y);
    }
    if (state.position.x > 1920 - @as(f32, @floatFromInt(state.texture.width))) {
        state.speed.x = -@abs(state.speed.x);
    }
    if (state.position.y > 1080 - @as(f32, @floatFromInt(state.texture.height))) {
        state.speed.y = -@abs(state.speed.y);
    }

    // draw screen
    rl.beginDrawing();
    rl.clearBackground(rl.Color.black);

    rl.drawTexture(
        state.texture,
        @intFromFloat(state.position.x),
        @intFromFloat(state.position.y),
        rl.Color.white,
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
