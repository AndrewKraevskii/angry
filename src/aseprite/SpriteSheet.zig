const std = @import("std");
const rl = @import("raylib");

const JsonRepresentation = struct {
    frames: []struct {
        filename: []const u8,
        frame: struct { x: u32, y: u32, w: u32, h: u32 },
        rotated: bool,
        trimmed: bool,
        spriteSourceSize: struct { x: u32, y: u32, w: u32, h: u32 },
        sourceSize: struct { w: u32, h: u32 },
        duration: u32,
    },

    meta: struct {
        app: []const u8,
        version: []const u8,
        image: []const u8,
        format: []const u8,
        size: struct {
            w: u32,
            h: u32,
        },
        scale: f32,
        slices: []struct {
            name: []const u8,
            color: []const u8,
            keys: []struct { frame: u32, bounds: JsonBounds },
        },
    },
};

alloc: std.mem.Allocator,
atlas: rl.Texture2D,
mapping: std.StringHashMapUnmanaged(Bounds),

pub const JsonBounds = struct {
    x: f32,
    y: f32,
    w: f32,
    h: f32,
};

pub const Bounds = rl.Rectangle;

fn loadSlice(alloc: std.mem.Allocator, path: []const u8) !std.StringHashMapUnmanaged(Bounds) {
    const json_path = try std.fmt.allocPrintZ(
        alloc,
        "{s}.json",
        .{path},
    );
    defer alloc.free(json_path);
    const file_content = std.fs.cwd().readFileAlloc(alloc, json_path, 1024 * 1024) catch |err| {
        switch (err) {
            error.FileNotFound => {
                std.log.err("Failed to find file in path: {s}", .{json_path});
            },
            else => {},
        }
        return err;
    };
    defer alloc.free(file_content);
    const parsed = try std.json.parseFromSlice(JsonRepresentation, alloc, file_content, .{
        .ignore_unknown_fields = true,
    });
    defer parsed.deinit();
    var slices = std.StringHashMapUnmanaged(Bounds){};
    try slices.ensureTotalCapacity(
        alloc,
        @intCast(parsed.value.meta.slices.len),
    );
    errdefer {
        var iter = slices.iterator();
        while (iter.next()) |entry| {
            alloc.free(entry.key_ptr.*);
        }
        slices.deinit(alloc);
    }
    for (parsed.value.meta.slices) |slice| {
        const key = try alloc.dupe(u8, slice.name);
        errdefer alloc.free(key);
        const entry = try slices.getOrPut(alloc, key);
        if (entry.found_existing) return error.FoundRepeatingLables;

        std.debug.assert(slice.keys.len == 1);
        const bounds = slice.keys[0].bounds;
        entry.value_ptr.* = .{ .x = bounds.x, .y = bounds.y, .width = bounds.w, .height = bounds.h };
    }
    return slices;
}

/// User must provide path without extention. It will use json and png extension to load files.
/// User must call deinit() on result.
pub fn loadSpriteSheet(alloc: std.mem.Allocator, path: []const u8) !@This() {
    const image_path = try std.fmt.allocPrintZ(
        alloc,
        "{s}.png",
        .{path},
    );
    defer alloc.free(image_path);

    const slice = try loadSlice(alloc, path);
    const texture = rl.loadTexture(image_path);

    return .{
        .mapping = slice,
        .atlas = texture,
        .alloc = alloc,
    };
}

pub fn deinit(self: *@This()) void {
    var iter = self.mapping.keyIterator();
    while (iter.next()) |key| {
        self.alloc.free(key.*);
    }
    self.mapping.deinit(self.alloc);
    rl.unloadTexture(self.atlas);
}

test loadSlice {
    const alloc = std.testing.allocator;
    var slice = try loadSlice(alloc, "res/for_tests");
    defer {
        var iter = slice.keyIterator();
        while (iter.next()) |key| {
            alloc.free(key.*);
        }
        slice.deinit(alloc);
    }
    try std.testing.expectEqual(slice.size, 2);
    try std.testing.expectEqual(slice.get("wood"), Bounds{ .x = 0, .y = 0, .width = 16, .height = 16 });
    try std.testing.expectEqual(slice.get("bird"), Bounds{ .x = 16, .y = 0, .width = 16, .height = 16 });
}
