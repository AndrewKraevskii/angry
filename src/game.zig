const std = @import("std");
const rl = @import("raylib");
const rlm = @import("raylib-math");
const window_size = @import("main.zig").window_size;

const DebugDraw = @import("debug_draw.zig").DebugDraw;
const box2d = @import("box2d.zig");

pub const Ball = struct {
    color: rl.Color,
    ttl: f32,
};

pub const Block = struct {
    color: rl.Color,
};

pub const GameState = struct {
    alloc: std.mem.Allocator,
    physics_world: box2d.World,
    bodies: std.ArrayListUnmanaged(box2d.Body),
    mouse_pressed: ?rl.Vector2 = null,
    state: enum {
        pause,
        play,
    } = .play,
    camera: rl.Camera2D,

    pub fn init(alloc: std.mem.Allocator) !GameState {
        var def = box2d.World.defaultDef();
        def.gravity = .{ .y = gravity, .x = 0 };
        const world = box2d.World.create(&def);

        var state: @This() = .{
            .alloc = alloc,
            .physics_world = world,
            .bodies = .{},
            .camera = .{
                .offset = .{ .x = 0, .y = 0 },
                .target = .{ .x = 0, .y = 0 },
                .rotation = 0,
                .zoom = 0,
            },
        };
        createBox(&state);
        return state;
    }
};

pub const Action = enum(u8) {
    none,
    exit,
    restart,
};

fn mouse_shift(state: *GameState) void {
    if (state.mouse_pressed == null and rl.isMouseButtonPressed(.mouse_button_left) or rl.isMouseButtonPressed(.mouse_button_right)) {
        state.mouse_pressed = rl.getMousePosition();
    }
    if (state.mouse_pressed != null and rl.isMouseButtonReleased(.mouse_button_left) or rl.isMouseButtonReleased(.mouse_button_right)) {
        state.mouse_pressed = null;
    }
}

fn frac(a: anytype, b: anytype) f32 {
    return @as(f32, @floatFromInt(a)) / @as(f32, @floatFromInt(b));
}

const gravity = 1000;
const strench_scale = 5;
const ttl = 100;

const friction_coef = 0.01;

fn createBox(state: *GameState) void {
    {
        var body_def = box2d.Body.defaultDef();
        body_def.type = box2d.c.b2_kinematicBody;
        body_def.position = .{ .x = window_size[0] / 2, .y = window_size[1] - 100 };

        var body = state.physics_world.createBody(&body_def);

        const box = box2d.Polygon.makeBox(window_size[0], 20);
        var shape_def: box2d.c.b2ShapeDef = box2d.Shape.defaultDef();
        const shape = body.createPolygon(&shape_def, box);

        state.bodies.append(state.alloc, shape.getBody()) catch {
            std.log.err("Failed to arr ball", .{});
        };
    }
}

fn addCircle(
    state: *GameState,
    pos: rl.Vector2,
    speed: rl.Vector2,
    body_type: enum {
        dinamic,
        kinematic,
    },
) void {
    var body_def = box2d.Body.defaultDef();
    body_def.linearVelocity = .{ .x = speed.x, .y = speed.y };
    body_def.type = switch (body_type) {
        .dinamic => box2d.c.b2_dynamicBody,
        .kinematic => box2d.c.b2_kinematicBody,
    };
    body_def.position = .{ .x = pos.x, .y = pos.y };

    var circle = state.physics_world.createBody(&body_def);
    const circle_def = box2d.Shape.defaultDef();
    const circle_shape = circle.createCircle(circle_def, .{
        .radius = 30,
    });

    state.bodies.append(state.alloc, circle_shape.getBody()) catch {
        std.log.err("Failed to arr ball", .{});
    };
}

fn updatePhysics(state: *GameState) void {

    // Spawn balls
    if (rl.isMouseButtonReleased(.mouse_button_left)) {
        if (state.mouse_pressed) |start| {
            const vec = calculate_speed(start, rl.getMousePosition());
            addCircle(state, start, vec, .kinematic);
        }
    }
    if (rl.isMouseButtonReleased(.mouse_button_right)) {
        if (state.mouse_pressed) |start| {
            const vec = calculate_speed(start, rl.getMousePosition());
            addCircle(state, start, vec, .dinamic);
        }
    }

    state.physics_world.step(
        rl.getFrameTime(),
        5,
    );

    _ = mouse_shift(state);
}

fn box2rlColor(color: box2d.c.b2Color) rl.Color {
    return .{
        .r = @intFromFloat(std.math.clamp(color.r, 0, 1) * 255),
        .g = @intFromFloat(std.math.clamp(color.g, 0, 1) * 255),
        .b = @intFromFloat(std.math.clamp(color.b, 0, 1) * 255),
        .a = @intFromFloat(std.math.clamp(1 - color.a, 0, 1) * 255),
    };
}

fn DrawSolidCircle(transform: box2d.c.b2Transform, radius: f32, color: box2d.c.b2Color, context: *anyopaque) callconv(.C) void {
    rl.drawCircle(@intFromFloat(transform.p.x), @intFromFloat(transform.p.y), radius, box2rlColor(color));
    _ = context;
}

fn DrawPolygon(vertices: [*]box2d.c.b2Vec2, vertexCount: c_int, color: box2d.c.b2Color, context: *anyopaque) callconv(.C) void {
    var buf: [box2d.c.b2_maxPolygonVertices + 1]box2d.c.b2Vec2 = undefined;
    @memcpy(buf[0..@intCast(vertexCount)], vertices);
    buf[@intCast(vertexCount)] = buf[0];

    const rl_ver: [*]rl.Vector2 = @ptrCast(&buf);

    rl.drawLineStrip(rl_ver[0..@intCast(vertexCount + 1)], box2rlColor(color));
    _ = context;
}

fn DrawSolidPolygon(transform: box2d.c.b2Transform, vertices: [*]const box2d.c.b2Vec2, vertexCount: c_int, radius: f32, color: box2d.c.b2Color, context: *anyopaque) callconv(.C) void {
    _ = transform;
    _ = context;
    _ = radius;
    var buf: [box2d.c.b2_maxPolygonVertices + 1]box2d.c.b2Vec2 = undefined;
    @memcpy(buf[0..@intCast(vertexCount)], vertices);
    buf[@intCast(vertexCount)] = buf[0];

    const rl_ver: [*]rl.Vector2 = @ptrCast(&buf);

    rl.drawTriangleStrip(rl_ver[0..@intCast(vertexCount + 1)], box2rlColor(color));
}

fn DrawTransform(transform: box2d.c.b2Transform, context: *anyopaque) callconv(.C) void {
    rl.drawLine(
        @intFromFloat(transform.p.x),
        @intFromFloat(transform.p.y),
        @intFromFloat(transform.p.x + transform.q.c * 30),
        @intFromFloat(transform.p.y + transform.q.s * 30),
        rl.Color.blue,
    );
    _ = context;
}

fn DrawString(position: box2d.c.b2Vec2, s: [*:0]const u8, context: *anyopaque) callconv(.C) void {
    rl.drawText(std.mem.sliceTo(s, 0), @intFromFloat(position.x), @intFromFloat(position.y), 10, rl.Color.white);
    _ = context;
}

export fn gameTick(state: *GameState) Action {
    if (rl.isKeyPressed(.key_space)) {
        state.state = switch (state.state) {
            .pause => .play,
            .play => .pause,
        };

        std.log.debug("state changed: {any}", .{
            state.state,
        });
    }

    // update physics
    if (state.state == .play) {
        updatePhysics(state);
    }
    // draw screen
    rl.beginDrawing();
    rl.clearBackground(rl.Color.black);
    {
        if (state.mouse_pressed) |start| {
            rl.drawCircle(@intFromFloat(start.x), @intFromFloat(start.y), 10, rl.Color.orange);
            draw_trace(start, rl.getMousePosition());
            rl.drawLine(
                @intFromFloat(start.x),
                @intFromFloat(start.y),
                rl.getMouseX(),
                rl.getMouseY(),
                rl.Color.green,
            );
        }

        var buf: [100]u8 = undefined;
        const number_of_balls = std.fmt.bufPrintZ(&buf, "balls: {d}", .{state.bodies.items.len}) catch "Error :(";
        rl.drawText(number_of_balls, 0, 100, 30, rl.Color.white);

        // for (state.bodies.items) |body| {
        //     // const pos = body.getPosition();

        //     // rl.drawCircle(@intFromFloat(pos.x), @intFromFloat(pos.y), 30, rl.Color.red);
        //     sta
        // }
        var draw = DebugDraw{
            .DrawSolidCircle = DrawSolidCircle,
            .DrawPolygon = DrawPolygon,
            .DrawString = DrawString,
            .DrawSolidPolygon = DrawSolidPolygon,
            .DrawTransform = DrawTransform,
        };
        state.physics_world.draw(&draw);
        rl.drawFPS(0, 0);
    }

    if (state.state == .pause) {
        rl.beginBlendMode(@intFromEnum(rl.BlendMode.blend_multiplied));
        rl.drawRectangle(0, 0, window_size[0], window_size[1], .{
            .r = 100,
            .g = 100,
            .b = 100,
            .a = 255,
        });
        rl.endBlendMode();
        {
            const font = 40;
            const size = rl.measureText("Paused", font);
            rl.drawText("Paused", @divFloor(window_size[0] - size, 2), window_size[1] / 2, font, rl.Color.white);
        }
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

fn calculate_speed(start: rl.Vector2, end: rl.Vector2) rl.Vector2 {
    var vec = rlm.vector2Subtract(start, end);
    vec = rlm.vector2Scale(vec, strench_scale);
    return vec;
}

fn draw_trace(start: rl.Vector2, end: rl.Vector2) void {
    const speed = calculate_speed(start, end);

    const delta_t = 0.1;
    const dots = 10;

    for (0..dots) |i| {
        const time = @as(f32, @floatFromInt(i)) * delta_t;
        const x = start.x + time * speed.x;
        const y = start.y + time * speed.y + gravity * time * time / 2;
        rl.drawCircle(
            @intFromFloat(x),
            @intFromFloat(y),
            2,
            rl.Color.gray.alpha(1 - frac(i, dots)),
        );
    }
}
