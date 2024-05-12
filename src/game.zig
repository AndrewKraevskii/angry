const std = @import("std");
pub const rl = @import("raylib");
pub const rlm = @import("raylib-math");
const window_size = @import("main.zig").window_size;
const box2rlColor = @import("utils.zig").box2rlColor;
const frac = @import("utils.zig").frac;
const DebugDraw = @import("debug_draw.zig").DebugDraw;
const box2d = @import("box2d.zig");

pub const Ball = struct {
    color: rl.Color,
    ttl: f32,
};

pub const Block = struct {
    color: rl.Color,
};

fn getWorldDefenition() box2d.c.struct_b2WorldDef {
    var def = box2d.World.defaultDef();
    def.gravity = .{ .y = gravity, .x = 0 };
    return def;
}

pub const GameState = struct {
    gpa: std.mem.Allocator,

    /// Cleared every frame
    arena: std.heap.ArenaAllocator,

    physics_world: box2d.World,
    bodies: std.ArrayListUnmanaged(box2d.Body),
    mouse_pressed: ?rl.Vector2 = null,
    state: enum {
        pause,
        play,
    } = .play,
    camera: rl.Camera2D,
    left_over_time: f32 = 0,

    pub fn init(gpa: std.mem.Allocator) !GameState {
        rl.initWindow(window_size[0], window_size[1], "Angry");
        var def = getWorldDefenition();
        const world = box2d.World.create(&def);

        var state: @This() = .{
            .gpa = gpa,
            .arena = std.heap.ArenaAllocator.init(gpa),
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
    pub fn deinit(self: *@This()) void {
        rl.closeWindow();
        self.physics_world.destroy();
        self.bodies.deinit(self.gpa);
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

const gravity = 1000;
const strench_scale = 5;
const ttl = 100;

const friction_coef = 0.01;

fn createBox(state: *GameState) void {
    var body_def = box2d.Body.defaultDef();
    body_def.type = box2d.c.b2_kinematicBody;
    body_def.position = .{ .x = window_size[0] / 2, .y = window_size[1] - 100 };

    var body = state.physics_world.createBody(&body_def);

    const box = box2d.Polygon.makeBox(window_size[0], 20);
    var shape_def: box2d.c.b2ShapeDef = box2d.Shape.defaultDef();
    shape_def.restitution = 0.99;
    _ = body.createPolygon(&shape_def, box);

    state.bodies.append(state.gpa, body) catch {
        std.log.err("Failed to arr ball", .{});
    };
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
    var circle_def = box2d.Shape.defaultDef();
    circle_def.restitution = 0.99;
    const circle_shape = circle.createCircle(circle_def, .{
        .radius = 30,
    });

    state.bodies.append(state.gpa, circle_shape.getBody()) catch {
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
    var frame_time = rl.getFrameTime() + state.left_over_time;

    const step_time: f32 = 1.0 / 1000.0;

    while (frame_time > step_time) : (frame_time -= step_time) {
        state.physics_world.step(
            step_time,
            5,
        );
    }

    state.left_over_time = frame_time;

    _ = mouse_shift(state);
}

fn save(state: *GameState) !void {
    var buffer: [std.posix.HOST_NAME_MAX]u8 = undefined;
    const path = try std.fs.path.join(state.arena.allocator(), &.{
        try std.fs.selfExeDirPath(&buffer),
        "level.json",
    });

    const Level = @import("Level.zig");

    var level = Level{
        .objects = try state.arena.allocator().alloc(Level.Object, state.bodies.items.len),
    };

    for (state.bodies.items, level.objects) |body, *object| {
        const max_shapes = 16; // There is no restriction on number of shapes in box2d but in my game there is.
        const count = box2d.c.b2Body_GetShapeCount(body.id);
        std.debug.assert(count < max_shapes);
        var shapes: [max_shapes]box2d.c.struct_b2ShapeId = undefined;
        std.debug.assert(
            count == box2d.c.b2Body_GetShapes(
                body.id,
                &shapes,
                max_shapes,
            ),
        );

        for (shapes[0..@intCast(count)]) |shape| {
            const shape_type = box2d.c.b2Shape_GetType(shape);
            switch (shape_type) {
                box2d.c.b2_circleShape => {
                    const pos = body.getPosition();
                    const circle = box2d.c.b2Shape_GetCircle(shape);
                    object.* = .{ .circle = .{
                        .center = .{ .x = pos.x, .y = pos.y },
                        .radius = circle.radius,
                    } };
                },
                box2d.c.b2_polygonShape => {
                    const polygon = box2d.c.b2Shape_GetPolygon(shape);
                    var vertices: [8]Level.Vector2 = undefined;
                    const vertex_count: usize = @intCast(polygon.count);
                    for (vertices[0..vertex_count], polygon.vertices[0..vertex_count]) |*vt, vf| {
                        vt.* = .{ .x = vf.x, .y = vf.y };
                    }
                    const pos = body.getPosition();
                    object.* = .{ .polygon = .{
                        .vertices = vertices,
                        .centroid = .{ .x = pos.x, .y = pos.y },
                        .count = polygon.count,
                        .radius = polygon.radius,
                        .position = .{ .x = pos.x, .y = pos.y },
                    } };
                },
                else => {
                    std.log.err("Shape saving is not supported: {d}", .{shape_type});
                },
            }
        }

        // const pos = body.getPosition();
        // _ = pos; // autofix
        // object.* = .{ .circle = .{
        //     .center = .{ .x = pos.x, .y = pos.y },
        //     .radius = 10,
        // } };
    }
    try level.save_to_file(path);
}

fn load(state: *GameState) !void {
    var buffer: [std.posix.HOST_NAME_MAX]u8 = undefined;
    const path = try std.fs.path.join(state.arena.allocator(), &.{
        try std.fs.selfExeDirPath(&buffer),
        "level.json",
    });

    const Level = @import("Level.zig");

    const level = try Level.read_from_file(state.arena.allocator(), path);

    for (state.bodies.items) |*item| {
        item.destroy();
    }
    state.bodies.clearRetainingCapacity();
    state.physics_world.destroy();

    var def = getWorldDefenition();
    state.physics_world = box2d.World.create(&def);
    for (level.objects) |object| {
        switch (object) {
            .circle => |circle| {
                addCircle(state, .{ .x = circle.center.x, .y = circle.center.y }, .{ .x = 0, .y = 0 }, .dinamic);
            },
            .polygon => |polygon| {
                var bodyDef: box2d.c.b2BodyDef = box2d.c.b2DefaultBodyDef();
                bodyDef.type = box2d.c.b2_kinematicBody;
                bodyDef.position = .{ .x = polygon.position.x, .y = polygon.position.y };
                std.debug.print("position: {any}\n", .{bodyDef.position});
                const body = box2d.c.b2CreateBody(state.physics_world.id, &bodyDef);
                var vertices: [8]box2d.c.b2Vec2 = undefined;
                const vertex_count: usize = @intCast(polygon.count);
                for (vertices[0..vertex_count], polygon.vertices[0..vertex_count]) |*vt, vf| {
                    vt.* = .{ .x = vf.x, .y = vf.y };
                }
                var box: box2d.c.b2Polygon = box2d.c.b2MakePolygon(&.{
                    .points = vertices,
                    .count = polygon.count,
                }, polygon.radius);

                var shapeDef: box2d.c.b2ShapeDef = box2d.c.b2DefaultShapeDef();
                shapeDef.friction = 0.6;
                shapeDef.density = 2.0;

                _ = box2d.c.b2CreatePolygonShape(body, &shapeDef, &box);

                try state.bodies.append(state.gpa, box2d.Body{ .id = body });
            },
        }
    }
}

pub export fn gameTick(state: *GameState) callconv(.C) Action {
    if (!state.arena.reset(.retain_capacity)) {
        std.log.err("Arena realloc faled", .{});
    }
    if (rl.windowShouldClose()) {
        return .exit;
    }
    if (rl.isKeyPressed(.key_space)) {
        state.state = switch (state.state) {
            .pause => .play,
            .play => .pause,
        };

        std.log.debug("state changed: {s}", .{@tagName(state.state)});
    }
    if (rl.isKeyPressed(.key_s)) saving: {
        {
            const time = std.time.Instant.now() catch return .exit;
            std.log.info("Saving to file: {s}", .{"./level.json"});
            save(state) catch |err| {
                std.log.err("Failed to save file with error: {s}", .{@errorName(err)});
                break :saving;
            };
            const delta = (std.time.Instant.now() catch return .exit).since(time);
            std.log.info("Saved... It took {d}s", .{frac(delta, std.time.ns_per_s)});
        }
        {
            const time = std.time.Instant.now() catch return .exit;
            std.log.info("Loading from file: {s}", .{"./level.json"});
            load(state) catch |err| {
                std.log.err("Failed to load from file with error: {s}", .{@errorName(err)});
                break :saving;
            };
            const delta = (std.time.Instant.now() catch return .exit).since(time);
            std.log.info("Loaded... It took {d}s", .{frac(delta, std.time.ns_per_s)});
        }
    }

    if (rl.isKeyPressed(rl.KeyboardKey.key_r)) {
        return .restart;
    }

    // update physics
    if (state.state == .play) {
        updatePhysics(state);
    }
    // draw screen
    rl.beginDrawing();
    rl.clearBackground(rl.Color.dark_gray);
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

        var draw = DebugDraw{};
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
