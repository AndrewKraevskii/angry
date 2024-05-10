const box2d = @import("box2d.zig");
const b2Vec2 = box2d.c.b2Vec2;
const b2Color = box2d.c.b2Color;
const b2Transform = box2d.c.b2Transform;
const b2AABB = box2d.c.b2AABB;
const std = @import("std");

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

fn DrawPolygon(vertices: [*]b2Vec2, vertexCount: c_int, color: b2Color, context: *anyopaque) callconv(.C) void {
    std.log.debug("DrawPolygon", .{});
    _ = vertices;
    _ = vertexCount;
    _ = color;
    _ = context;
}

/// Draw a solid closed polygon provided in CCW order.
fn DrawSolidPolygon(transform: b2Transform, vertices: [*]const b2Vec2, vertexCount: c_int, radius: f32, color: b2Color, context: *anyopaque) callconv(.C) void {
    std.log.debug("DrawSolidPolygon", .{});
    _ = transform;
    _ = vertices;
    _ = vertexCount;
    _ = radius;
    _ = color;
    _ = context;
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
fn DrawSolidCircle(transform: b2Transform, radius: f32, color: b2Color, context: *anyopaque) callconv(.C) void {
    std.log.debug("DrawSolidCircle", .{});
    _ = transform;
    _ = radius;
    _ = color;
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
fn DrawSegment(p1: b2Vec2, p2: b2Vec2, color: b2Color, context: *anyopaque) callconv(.C) void {
    std.log.debug("DrawSegment", .{});
    _ = p1;
    _ = p2;
    _ = color;
    _ = context;
}

/// Draw a transform. Choose your own length scale.
fn DrawTransform(transform: b2Transform, context: *anyopaque) callconv(.C) void {
    std.log.debug("DrawTransform", .{});
    _ = transform;
    _ = context;
}

/// Draw a point.
fn DrawPoint(position: b2Vec2, size: f32, color: b2Color, context: *anyopaque) callconv(.C) void {
    std.log.debug("DrawPoint", .{});
    _ = position;
    _ = size;
    _ = color;
    _ = context;
}

/// Draw a string.
fn DrawString(position: b2Vec2, s: [*:0]const u8, context: *anyopaque) callconv(.C) void {
    std.log.debug("DrawString", .{});
    _ = position;
    _ = s;
    _ = context;
}
