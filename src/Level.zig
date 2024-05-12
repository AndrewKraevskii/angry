const std = @import("std");

objects: []Object,
pub const Vector2 = struct { x: f32, y: f32 };

pub const Object = union(enum) {
    circle: struct {
        center: Vector2,
        radius: f32,
    },
    polygon: Polygon,

    pub const Polygon = struct {
        vertices: [8]Vector2,
        centroid: Vector2,
        count: i32,
        radius: f32,
        position: Vector2,
    };
};

pub fn save_to_file(self: @This(), absolute_path: []const u8) !void {
    const file = try std.fs.createFileAbsolute(absolute_path, .{});
    defer file.close();
    try self.serialize(file.writer());
}

pub fn read_from_file(arena: std.mem.Allocator, absolute_path: []const u8) !@This() {
    const file = try std.fs.openFileAbsolute(absolute_path, .{});
    defer file.close();
    return deserialize(arena, file.reader());
}

pub fn serialize(self: @This(), writer: anytype) !void {
    try std.json.stringify(self, .{
        .whitespace = .indent_4,
    }, writer);
}

pub fn deserialize(arena: std.mem.Allocator, reader: anytype) !@This() {
    const max_size = 1 * 1024 * 1024;
    const slice = try reader.readAllAlloc(arena, max_size);
    errdefer arena.free(slice);
    const parsed = try std.json.parseFromSliceLeaky(@This(), arena, slice, .{});
    return parsed;
}
