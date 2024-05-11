const std = @import("std");
const box2d = @import("box2d.zig");
const rl = @import("raylib");

pub fn box2rlColor(color: box2d.c.b2Color) rl.Color {
    return .{
        .r = @intFromFloat(std.math.clamp(color.r, 0, 1) * 255),
        .g = @intFromFloat(std.math.clamp(color.g, 0, 1) * 255),
        .b = @intFromFloat(std.math.clamp(color.b, 0, 1) * 255),
        .a = @intFromFloat(std.math.clamp(1 - color.a, 0, 1) * 255),
    };
}

pub fn frac(a: anytype, b: anytype) f32 {
    return @as(f32, @floatFromInt(a)) / @as(f32, @floatFromInt(b));
}
