const std = @import("std");
const box2d = @import("box2d.zig");
const Game = @import("game.zig").Game;
const math = @import("math.zig");
const Vec2 = math.Vec2;
const toVec = math.toVec;
const toBox = math.toBox;
const rl = @import("raylib");

body: box2d.Body,
name: []const u8,
size: Vec2,
draw_mode: enum {
    repeat_width,
    repeat_height,
    repeat_all,
    stretch,
},

pub fn init(body: box2d.Body, name: ?[]const u8, maybe_size: ?Vec2) @This() {
    const size = maybe_size orelse findSizeOfBody(body);

    return .{
        .body = body,
        .name = name orelse "",
        .size = size,
        .draw_mode = if (maybe_size == null) .repeat_width else .stretch,
    };
}

pub fn createCircle(
    state: *Game,
    pos: rl.Vector2,
    speed: rl.Vector2,
    body_type: enum {
        dynamic,
        kinematic,
    },
    radius: f32,
    name: []const u8,
) @This() {
    var body_def = box2d.Body.defaultDef();
    body_def.linearVelocity = .{ .x = speed.x, .y = speed.y };

    body_def.type = switch (body_type) {
        .dynamic => box2d.c.b2_dynamicBody,
        .kinematic => box2d.c.b2_kinematicBody,
    };
    body_def.position = .{ .x = pos.x, .y = pos.y };

    var circle = state.physics_world.createBody(&body_def);
    var circle_def = box2d.Shape.defaultDef();
    circle_def.restitution = 0.99;
    _ = circle.createCircle(circle_def, .{
        .radius = radius,
    });

    return init(circle, name, .{
        .x = radius * 2,
        .y = radius * 2,
    });
}

pub fn createThickLine(
    state: *Game,
    start: rl.Vector2,
    end: rl.Vector2,
    body_type: enum {
        dynamic,
        kinematic,
    },
    thickness: f32,
    name: []const u8,
) @This() {
    var body_def = box2d.Body.defaultDef();
    body_def.type = switch (body_type) {
        .dynamic => box2d.c.b2_dynamicBody,
        .kinematic => box2d.c.b2_kinematicBody,
    };
    body_def.position = toBox(start.lerp(end, 0.5));

    body_def.linearDamping = 0.999;
    body_def.angularDamping = 0.999;
    body_def.angle = -start.lineAngle(end) + std.math.pi / 2.0;

    std.log.debug("body_def.angle: {d}", .{body_def.angle});

    var body = state.physics_world.createBody(&body_def);

    const size = Vec2{ .x = thickness, .y = start.distance(end) };

    const box = box2d.Polygon.makeBox(size.x / 2, size.y / 2);
    var shape_def: box2d.c.b2ShapeDef = box2d.Shape.defaultDef();
    shape_def.restitution = 0.999;
    _ = body.createPolygon(&shape_def, box);

    return init(body, name, size);
}

pub fn draw(self: @This(), game: Game) void {
    const slice = game.atlas.mapping.get(self.name) orelse {
        // TODO: Draw missing texture
        return;
    };
    const position = toVec(self.body.getPosition());

    switch (self.draw_mode) {
        .stretch => {
            rl.drawTexturePro(
                game.atlas.atlas,
                slice,
                .{
                    .x = position[0],
                    .y = position[1],
                    .width = self.size.x,
                    .height = self.size.y,
                },
                .{ .x = self.size.x / 2, .y = self.size.y / 2 },
                self.body.getAngle() * std.math.deg_per_rad,
                rl.Color.white,
            );
        },
        .repeat_width => {
            const times: usize = @intFromFloat(@floor(self.size.x / slice.width));

            const start_pos = position - toVec(self.size) / @as(@Vector(2, f32), @splat(2));
            for (0..times) |i| {
                var pos = start_pos;
                pos[0] += @as(f32, @floatFromInt(i)) * slice.width;
                rl.drawTexturePro(
                    game.atlas.atlas,
                    slice,
                    .{
                        .x = pos[0],
                        .y = pos[1],
                        .width = slice.width,
                        .height = slice.height,
                    },
                    .{ .x = 0, .y = 0 },
                    0,
                    rl.Color.white,
                );
            }
        },
        else => @panic("Not implemented"),
    }
}
pub fn deinit(self: *@This()) void {
    _ = self; // autofix
}

fn findSizeOfBody(body: box2d.Body) Vec2 {
    var min = @Vector(2, f32){ 0, 0 };
    var max = @Vector(2, f32){ 0, 0 };

    var shapes: [16]box2d.Shape = undefined;
    const shapes_slice = shapes[0..body.getShapes(&shapes)];

    for (shapes_slice) |shape| {
        for (shape.getPolygon().polygon.vertices) |vertex| {
            min[0] = @min(min[0], vertex.x);
            min[1] = @min(min[1], vertex.y);
            max[0] = @max(max[0], vertex.x);
            max[1] = @max(max[1], vertex.y);
        }
    }

    const size = max - min;
    return .{
        .x = size[0],
        .y = size[1],
    };
}
