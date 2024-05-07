const std = @import("std");

inotify_fd: i32,
alloc: std.mem.Allocator,
files: std.AutoArrayHashMapUnmanaged(i32, []const u8),

pub fn init(alloc: std.mem.Allocator) !@This() {
    const fd = try std.posix.inotify_init1(0);
    return .{
        .inotify_fd = fd,
        .alloc = alloc,
        .files = std.AutoArrayHashMap(i32, []const u8).init(alloc),
    };
}

pub fn deinit(self: @This()) !@This() {
    std.posix.close(self);
}

pub fn addFile(self: *@This(), path: []const u8) !void {
    const wd = try std.posix.inotify_add_watch(self.inotify_fd, path, std.os.linux.IN.MODIFY);
    errdefer std.posix.inotify_rm_watch(self.inotify_fd, wd);
    const res = try self.files.getOrPut(self.alloc, wd);
    if (res.found_existing) {
        return error.FileIsAlreadyBeenWatched;
    }
    errdefer std.debug.assert(self.files.swapRemoveAt(res.index));

    res.value_ptr.* = try self.alloc.dupe(path);
}

pub fn listen(self: *@This()) ![][]const u8 {
    // TODO: handle errors
    const max_event_size = @sizeOf(std.os.linux.inotify_event) + std.os.linux.NAME_MAX + 1;
    var buf: [max_event_size]u8 align(@alignOf(std.os.linux.inotify_event)) = undefined;

    const len = try std.posix.read(self.inotify_fd, &buf);

    var i: usize = 0;
    var list = std.ArrayList([]const u8).init(self.alloc);
    while (i + @sizeOf(std.os.linux.inotify_event) < len) {
        const event: *std.os.linux.inotify_event = @ptrCast(buf[i..].ptr);

        const file_path = self.files.get(event.wd).?;
        try list.append(file_path);

        i += @sizeOf(@TypeOf(event.*)) + event.len;
    }

    return try list.toOwnedSlice();
}
