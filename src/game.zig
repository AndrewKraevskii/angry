const std = @import("std");
pub const rl = @import("raylib");
const window_size = @import("main.zig").window_size;
const box2rlColor = @import("utils.zig").box2rlColor;
const frac = @import("utils.zig").frac;
const DebugDraw = @import("debug_draw.zig").DebugDraw;
const box2d = @import("box2d.zig");
const SpriteSheet = @import("./aseprite/SpriteSheet.zig");
const Object = @import("Object.zig");
const Vec2 = @import("math.zig").Vec2;

const tracy = @import("ztracy");
pub const Block = struct {
    color: rl.Color,
};

fn getWorldDefinition() box2d.c.struct_b2WorldDef {
    var def = box2d.World.defaultDef();
    def.gravity = .{ .y = gravity, .x = 0 };
    return def;
}

const screen_to_sprite_pixels = 4;
const gravity = 1000;
const strench_scale = 5;

const friction_coef = 0.01;

pub const Game = struct {
    gpa: std.mem.Allocator,

    /// Cleared every frame
    arena: std.heap.ArenaAllocator,

    physics_world: box2d.World,
    bodies: std.ArrayListUnmanaged(Object),
    mouse_pressed: ?rl.Vector2 = null,
    state: struct {
        pause: enum {
            pause,
            play,
            fn toggle(self: *@This()) void {
                self.* = switch (self.*) {
                    .pause => .play,
                    .play => .pause,
                };
            }
        },
        editor: enum {
            game,
            editor,
            fn toggle(self: *@This()) void {
                self.* = switch (self.*) {
                    .game => .editor,
                    .editor => .game,
                };
            }
        },
        debug_draw: bool,
    } = .{
        .pause = .play,
        .editor = .game,
        .debug_draw = true,
    },
    camera: rl.Camera2D,
    left_over_time: f32 = 0,
    atlas: SpriteSheet,

    pub fn init(gpa: std.mem.Allocator) !Game {
        rl.initWindow(window_size[0], window_size[1], "Angry");
        var def = getWorldDefinition();
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
            .atlas = try SpriteSheet.loadSpriteSheet(gpa, "res/atlas"),
        };

        createLevel(&state);
        return state;
    }
    pub fn deinit(self: *@This()) void {
        self.atlas.deinit();
        rl.closeWindow();
        self.physics_world.destroy();
        for (self.bodies.items) |*item| {
            item.deinit();
        }
        self.bodies.deinit(self.gpa);
    }
};

pub const Action = enum(u8) {
    none,
    exit,
    restart,
};

fn mouse_shift(state: *Game) void {
    if (state.mouse_pressed == null and rl.isMouseButtonPressed(.mouse_button_left) or rl.isMouseButtonPressed(.mouse_button_right)) {
        state.mouse_pressed = rl.getMousePosition();
    }
    if (state.mouse_pressed != null and rl.isMouseButtonReleased(.mouse_button_left) or rl.isMouseButtonReleased(.mouse_button_right)) {
        state.mouse_pressed = null;
    }
}

fn createLevel(state: *Game) void {
    var body_def = box2d.Body.defaultDef();
    body_def.type = box2d.c.b2_kinematicBody;
    body_def.position = .{ .x = window_size[0] / 2, .y = window_size[1] - 100 };

    var body = state.physics_world.createBody(&body_def);

    const size = Vec2{ .x = window_size[0], .y = 20 };
    const box = box2d.Polygon.makeBox(size.x, size.y);
    var shape_def: box2d.c.b2ShapeDef = box2d.Shape.defaultDef();
    shape_def.restitution = 0.99;
    _ = body.createPolygon(&shape_def, box);

    state.bodies.append(state.gpa, Object.init(
        body,
        "grass",
        null,
    )) catch {
        std.log.err("Failed to arr ball", .{});
    };
}

fn updatePhysics(state: *Game) void {
    const zone = tracy.ZoneN(@src(), "UpdatePhysics");
    defer zone.End();
    var frame_time = rl.getFrameTime() + state.left_over_time;
    const step_time: f32 = 1.0 / 1000.0;
    while (frame_time > step_time) : (frame_time -= step_time) {
        const physics_step = tracy.ZoneN(@src(), "UpdateStep");
        defer physics_step.End();
        state.physics_world.step(
            step_time,
            5,
        );
    }

    state.left_over_time = frame_time;
}

fn gameInput(state: *Game) !void {
    if (rl.isMouseButtonReleased(.mouse_button_left)) {
        if (state.mouse_pressed) |start| {
            const vec = calculate_speed(start, rl.getMousePosition());
            try state.bodies.append(
                state.gpa,
                Object.createCircle(
                    state,
                    start,
                    vec,
                    .dynamic,
                    30,
                    "bird",
                ),
            );
        }
    }
    if (rl.isMouseButtonReleased(.mouse_button_right)) {
        if (state.mouse_pressed) |start| {
            const end = rl.getMousePosition();
            try state.bodies.append(
                state.gpa,
                Object.createThickLine(
                    state,
                    start,
                    end,
                    .dynamic,
                    20,
                    "block",
                ),
            );
        }
    }
    _ = mouse_shift(state);
}

fn generalInput(state: *Game) void {
    if (rl.isKeyPressed(.key_e)) {
        state.state.editor.toggle();
    }
    if (rl.isKeyPressed(.key_space)) {
        state.state.pause.toggle();
    }
}

pub fn gameTick(state: *Game) !Action {
    if (!state.arena.reset(.retain_capacity)) {
        std.log.err("Arena realloc faled", .{});
    }

    if (rl.isKeyPressed(rl.KeyboardKey.key_r)) {
        return .restart;
    }
    if (rl.windowShouldClose()) {
        return .exit;
    }
    const button = @import("./ui/button.zig").button;

    generalInput(state);
    // update physics
    if (state.state.pause == .play) {
        gameInput(state) catch @panic("OOM");
        updatePhysics(state);
    }

    // draw screen

    rl.beginDrawing();
    rl.clearBackground(rl.Color.dark_gray);

    if (state.state.editor != .editor) {
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

            if (state.state.debug_draw) {
                var debug_draw_struct: DebugDraw = .{};
                state.physics_world.draw(&debug_draw_struct);
            }

            for (state.bodies.items) |item| {
                item.draw(state.*);
            }

            rl.drawFPS(0, 0);
        }

        if (state.state.pause == .pause) {
            rl.beginBlendMode(.blend_multiplied);
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
    } else {
        var draw = DebugDraw{};
        state.physics_world.draw(&draw);
        rl.drawFPS(0, 0);
    }
    if (button(.{ .x = 1000, .y = 100 }, "Pause", .{ .font_size = 20 }) == .pressed) {
        state.state.pause.toggle();
        std.log.debug("button pressed", .{});
    }
    if (button(.{ .x = 1200, .y = 100 }, "Debug", .{ .font_size = 20 }) == .pressed) {
        state.state.debug_draw = !state.state.debug_draw;
        std.log.debug("button pressed", .{});
    }

    rl.endDrawing();
    return .none;
}

fn calculate_speed(start: rl.Vector2, end: rl.Vector2) rl.Vector2 {
    var vec = start.subtract(end);
    vec = vec.scale(strench_scale);
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
