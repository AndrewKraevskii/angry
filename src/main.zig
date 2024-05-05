const std = @import("std");
const rl = @import("raylib");
const box2d = @import("./box2d.zig");

const GameState = struct {
    balls: []u32,
    wall: [1]u32,
    physics_world: box2d.World,
};

const box_height = 10;
const window_size = .{ 1920, 1080 };

fn initGame(alloc: std.mem.Allocator) !GameState {
    var world = box2d.World{
        .gravity = .{
            .y = 9.8,
            .x = 0.0,
        },
        .iterations = 6,
        .accumulateImpulses = true,
        .warmStarting = true,
        .positionCorrection = true,
        .bodies = box2d.World.BodyMap.init(alloc),
        .arbiters = box2d.World.ArbiterMap.init(alloc),
    };

    const balls = [_]struct { box2d.Vec2, box2d.Vec2, f32 }{ .{
        .{ .x = 50.0, .y = 0.0 },
        .{ .x = box_height * 4, .y = box_height },
        1,
    }, .{
        .{ .x = 52.0, .y = 12.0 },
        .{ .x = box_height, .y = box_height },
        1,
    } };

    const handlers = try alloc.alloc(u32, balls.len);
    for (balls[0..], handlers) |ball, *handler| {
        handler.* = world.addBody(
            box2d.Body.init(
                ball[0],
                ball[1],
                ball[2],
            ),
        );
    }

    const wall = world.addBody(
        box2d.Body.init(
            .{ .x = 932.0, .y = 1100.0 },
            .{ .x = 2000, .y = 100 },
            std.math.inf(f32),
        ),
    );

    return .{
        .balls = handlers,
        .wall = .{wall},
        .physics_world = world,
    };
}

fn drawBox(box: box2d.Body, color: rl.Color) void {
    rl.drawRectangleV(
        .{ .x = box.position.x - box.width.x / 2, .y = box.position.y - box.width.y / 2 },
        .{ .x = box.width.x, .y = box.width.y },
        color,
    );
}

fn updateGame(self: *GameState) void {
    // update phisics
    const dt = rl.getFrameTime();

    self.physics_world.step(dt);

    // draw screen
    rl.beginDrawing();
    rl.clearBackground(rl.Color.black);

    for (self.balls) |ball_handler| {
        const box = self.physics_world.bodies.get(ball_handler) orelse @panic("ball missing :(");
        drawBox(box, rl.Color.red);
    }

    for (self.wall) |ball_handler| {
        const box = self.physics_world.bodies.get(ball_handler) orelse @panic("ball missing :(");
        drawBox(box, rl.Color.white);
    }

    rl.endDrawing();
}

pub fn main() !void {
    const alloc = std.heap.c_allocator;

    rl.initWindow(window_size[0], window_size[1], "Hello");

    var game = try initGame(alloc);

    while (!rl.windowShouldClose()) {
        updateGame(&game);
    }

    defer rl.closeWindow();
}
