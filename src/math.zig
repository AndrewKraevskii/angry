const rl = @import("raylib");
const boxVec = @import("box2d.zig").c.b2Vec2;

pub const Vec2 = struct {
    x: f32,
    y: f32,
};

pub fn toVec(vec: anytype) @Vector(2, f32) {
    return .{ vec.x, vec.y };
}

pub fn toRl(vec: anytype) rl.Vector2 {
    return .{ .x = vec.x, .y = vec.y };
}
pub fn toBox(vec: anytype) boxVec {
    return .{ .x = vec.x, .y = vec.y };
}
