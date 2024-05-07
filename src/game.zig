const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");
const window_size = @import("main.zig").window_size;

pub const Ball = struct {
    pos: rl.Vector2,
    speed: rl.Vector2,
    color: rl.Color,
    size: f32 = 10,
    ttl: f32,
};

pub const GameState = struct {
    alloc: std.mem.Allocator,
    mouse_pressed: ?rl.Vector2 = null,
    balls: std.ArrayList(Ball),

    pub fn init(alloc: std.mem.Allocator) !GameState {
        return .{
            .alloc = alloc,
            .balls = try std.ArrayList(Ball).initCapacity(
                alloc,
                4096,
            ),
        };
    }
};

pub const Action = enum(u8) {
    none,
    exit,
    restart,
};

fn mouse_shift(state: *GameState) void {
    if (state.mouse_pressed == null and rl.isMouseButtonPressed(.mouse_button_left)) {
        state.mouse_pressed = rl.getMousePosition();
    }
    if (state.mouse_pressed != null and rl.isMouseButtonReleased(.mouse_button_left)) {
        state.mouse_pressed = null;
    }
}

fn frac(a: anytype, b: anytype) f32 {
    return @as(f32, @floatFromInt(a)) / @as(f32, @floatFromInt(b));
}

export fn gameTick(state: *GameState) Action {
    // update physics
    const ttl = 10;
    {
        if (rl.isMouseButtonReleased(.mouse_button_left)) {
            if (state.mouse_pressed) |start| {
                var vec = rlm.vector2Subtract(start, rl.getMousePosition());
                vec = rlm.vector2Scale(vec, 10);
                _ = state.balls.append(.{
                    .pos = start,
                    .ttl = ttl,
                    .speed = vec,
                    .color = rl.Color.red,
                }) catch {};
            }
        }

        for (state.balls.items) |*ball| {
            if (ball.ttl <= 0) {
                continue;
            }
            ball.ttl -= rl.getFrameTime();
            ball.pos = rlm.vector2Add(ball.pos, rlm.vector2Scale(ball.speed, rl.getFrameTime()));

            ball.speed = rlm.vector2Add(ball.speed, .{ .x = 0, .y = 1000 * rl.getFrameTime() });
        }

        var i: usize = 0;
        while (i < state.balls.items.len) {
            if (state.balls.items[i].pos.y > window_size[1]) {
                state.balls.items[i].pos.y = window_size[1];
                state.balls.items[i].speed.y *= -1;
            }
            if (state.balls.items[i].pos.x > window_size[0]) {
                state.balls.items[i].pos.x = window_size[0];
                state.balls.items[i].speed.x *= -1;
            }
            if (state.balls.items[i].pos.y < 0) {
                state.balls.items[i].pos.y = 0;
                state.balls.items[i].speed.y *= -1;
            }
            if (state.balls.items[i].pos.x < 0) {
                state.balls.items[i].pos.x = 0;
                state.balls.items[i].speed.x *= -1;
            }
            if (state.balls.items[i].ttl <= 0) {
                _ = state.balls.swapRemove(i);
                continue;
            }
            i += 1;
        }
    }
    _ = mouse_shift(state);

    // draw screen
    rl.beginDrawing();
    rl.clearBackground(rl.Color.black);
    if (state.mouse_pressed) |start| {
        rl.drawCircle(@intFromFloat(start.x), @intFromFloat(start.y), 10, rl.Color.orange);
        rl.drawLine(
            @intFromFloat(start.x),
            @intFromFloat(start.y),
            rl.getMouseX(),
            rl.getMouseY(),
            rl.Color.green,
        );
    }

    rl.drawFPS(0, 0);
    var buf: [100]u8 = undefined;
    const number_of_balls = std.fmt.bufPrintZ(&buf, "balls: {d}", .{state.balls.items.len}) catch "Error :(";
    rl.drawText(number_of_balls, 0, 100, 30, rl.Color.white);
    for (state.balls.items) |ball| {
        rl.drawCircle(
            @intFromFloat(ball.pos.x),
            @intFromFloat(ball.pos.y),
            ball.size,
            ball.color.alpha(ball.ttl / ttl),
        );
    }

    rl.endDrawing();
    if (rl.windowShouldClose()) {
        return .exit;
    }
    if (rl.isKeyPressed(rl.KeyboardKey.key_r)) {
        return .restart;
    }
    return .none;
}
