const box2d = @import("box2d.zig");
const b2Vec2 = box2d.c.b2Vec2;
const b2Color = box2d.c.b2Color;
const b2Transform = box2d.c.b2Transform;
const b2AABB = box2d.c.b2AABB;
const std = @import("std");
const rl = @import("raylib");

const box2rlColor = @import("utils.zig").box2rlColor;

pub const DebugDraw = extern struct {
    /// Draw a closed polygon provided in CCW order.
    DrawPolygon: *const fn (vertices: [*]b2Vec2, vertexCount: c_int, color: b2Color, context: *anyopaque) callconv(.C) void = DrawPolygon,

    /// Draw a solid closed polygon provided in CCW order.
    DrawSolidPolygon: *const fn (transform: b2Transform, vertices: [*]const b2Vec2, vertexCount: c_int, radius: f32, color: b2Color, context: *anyopaque) callconv(.C) void = DrawSolidPolygon,

    /// Draw a circle.
    DrawCircle: *const fn (center: b2Vec2, radius: f32, color: b2Color, context: *anyopaque) callconv(.C) void = DrawCircle,

    /// Draw a solid circle.
    DrawSolidCircle: *const fn (transform: b2Transform, radius: f32, color: b2Color, context: *anyopaque) callconv(.C) void = DrawSolidCircle,

    /// Draw a capsule.
    DrawCapsule: *const fn (p1: b2Vec2, p2: b2Vec2, radius: f32, color: b2Color, context: *anyopaque) callconv(.C) void = DrawCapsule,

    /// Draw a solid capsule.
    DrawSolidCapsule: *const fn (p1: b2Vec2, p2: b2Vec2, radius: f32, color: b2Color, context: *anyopaque) callconv(.C) void = DrawSolidCapsule,

    /// Draw a line segment.
    DrawSegment: *const fn (p1: b2Vec2, p2: b2Vec2, color: b2Color, context: *anyopaque) callconv(.C) void = DrawSegment,

    /// Draw a transform. Choose your own length scale.
    DrawTransform: *const fn (transform: b2Transform, context: *anyopaque) callconv(.C) void = DrawTransform,

    /// Draw a point.
    DrawPoint: *const fn (position: b2Vec2, size: f32, color: b2Color, context: *anyopaque) callconv(.C) void = DrawPoint,

    /// Draw a string.
    DrawString: *const fn (position: b2Vec2, s: [*:0]const u8, context: *anyopaque) callconv(.C) void = DrawString,

    drawingBounds: b2AABB = .{
        .lowerBound = .{ .x = -10000, .y = -10000 },
        .upperBound = .{ .x = 10000, .y = 10000 },
    },
    drawShapes: bool = true,
    drawJoints: bool = true,
    drawJointExtras: bool = true,
    drawAABBs: bool = true,
    drawMass: bool = true,
    drawContacts: bool = true,
    drawGraphColors: bool = true,
    drawContactNormals: bool = true,
    drawContactImpulses: bool = true,
    drawFrictionImpulses: bool = true,
    context: ?*anyopaque = null,
};

fn DrawPolygon(vertices: [*]box2d.c.b2Vec2, vertexCount: c_int, color: box2d.c.b2Color, context: *anyopaque) callconv(.C) void {
    std.debug.assert(vertexCount <= box2d.c.b2_maxPolygonVertices);
    _ = context;
    var buf: [box2d.c.b2_maxPolygonVertices + 1]box2d.c.b2Vec2 = undefined;
    @memcpy(buf[0..@intCast(vertexCount)], vertices);
    buf[@intCast(vertexCount)] = buf[0];

    const rl_ver: [*]rl.Vector2 = @ptrCast(&buf[0]);

    rl.drawLineStrip(rl_ver[0..@intCast(vertexCount + 1)], box2rlColor(color));
}

/// Draw a solid closed polygon provided in CCW order.
fn DrawSolidPolygon(transform: box2d.c.b2Transform, vertices: [*]const box2d.c.b2Vec2, vertexCount: c_int, radius: f32, color: box2d.c.b2Color, context: *anyopaque) callconv(.C) void {
    std.debug.assert(vertexCount <= box2d.c.b2_maxPolygonVertices);
    _ = transform;
    _ = context;
    _ = radius;
    var buf: [box2d.c.b2_maxPolygonVertices + 1]box2d.c.b2Vec2 = undefined;
    @memcpy(buf[0..@intCast(vertexCount)], vertices);
    buf[@intCast(vertexCount)] = buf[0];

    const rl_ver: [*]rl.Vector2 = @ptrCast(&buf[0]);

    rl.drawTriangleStrip(rl_ver[0..@intCast(vertexCount + 1)], box2rlColor(color));
}

/// Draw a circle.
fn DrawCircle(center: b2Vec2, radius: f32, color: b2Color, context: *anyopaque) callconv(.C) void {
    std.log.debug("DrawCircle", .{});
    _ = center;
    _ = radius;
    _ = color;
    _ = context;
}

/// Draw a solid circle.
fn DrawSolidCircle(transform: box2d.c.b2Transform, radius: f32, color: box2d.c.b2Color, context: *anyopaque) callconv(.C) void {
    rl.drawCircle(@intFromFloat(transform.p.x), @intFromFloat(transform.p.y), radius, box2rlColor(color));
    _ = context;
}

/// Draw a capsule.
fn DrawCapsule(p1: b2Vec2, p2: b2Vec2, radius: f32, color: b2Color, context: *anyopaque) callconv(.C) void {
    std.log.debug("DrawCapsule", .{});
    _ = p1;
    _ = p2;
    _ = radius;
    _ = color;
    _ = context;
}

/// Draw a solid capsule.
fn DrawSolidCapsule(p1: b2Vec2, p2: b2Vec2, radius: f32, color: b2Color, context: *anyopaque) callconv(.C) void {
    std.log.debug("DrawSolidCapsule", .{});
    _ = p1;
    _ = p2;
    _ = radius;
    _ = color;
    _ = context;
}

/// Draw a line segment.
fn DrawSegment(p1: box2d.c.b2Vec2, p2: box2d.c.b2Vec2, color: box2d.c.b2Color, context: *anyopaque) callconv(.C) void {
    rl.drawLine(
        @intFromFloat(p1.x),
        @intFromFloat(p1.y),
        @intFromFloat(p2.x),
        @intFromFloat(p2.y),
        box2rlColor(color),
    );
    _ = context;
}

/// Draw a transform. Choose your own length scale.
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

/// Draw a point.
fn DrawPoint(position: box2d.c.b2Vec2, size: f32, color: box2d.c.b2Color, context: *anyopaque) callconv(.C) void {
    rl.drawCircle(
        @intFromFloat(position.x),
        @intFromFloat(position.y),
        size,
        box2rlColor(color),
    );
    _ = context;
}

/// Draw a string.
fn DrawString(position: box2d.c.b2Vec2, s: [*:0]const u8, context: *anyopaque) callconv(.C) void {
    rl.drawText(std.mem.sliceTo(s, 0), @intFromFloat(position.x), @intFromFloat(position.y), 10, rl.Color.white);
    _ = context;
}
