const std = @import("std");

inotify_fd: i32,

pub fn init() !@This() {
    const fd = try std.posix.inotify_init1(0);
    return .{
        .inotify_fd = fd,
    };
}

pub fn deinit(self: @This()) void {
    std.posix.close(self.inotify_fd);
}

pub fn addFile(self: *@This(), path: []const u8) !void {
    _ = try std.posix.inotify_add_watch(self.inotify_fd, path, std.os.linux.IN.MODIFY);
}

pub fn listen(self: *@This()) !void {
    const max_event_size = @sizeOf(std.os.linux.inotify_event) + std.os.linux.NAME_MAX + 1;
    var buf: [max_event_size]u8 align(@alignOf(std.os.linux.inotify_event)) = undefined;

    _ = try std.posix.read(self.inotify_fd, &buf);
}
