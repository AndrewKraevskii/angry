const std = @import("std");

pub fn main() !void {
    const fd = try std.posix.inotify_init1(0);

    _ = try std.posix.inotify_add_watch(
        fd,
        "./src/",
        std.os.linux.IN.MODIFY,
    );

    while (true) {
        var buf: [4096]u8 align(@alignOf(std.os.linux.inotify_event)) = undefined;
        const read_len = try std.posix.read(fd, &buf);

        var i: usize = 0;
        while (i < read_len) {
            const event: *std.os.linux.inotify_event = @ptrCast(&buf);
            if (event.getName()) |name| {
                std.log.info("{s} was modified", .{name});
            }

            i += @sizeOf(@TypeOf(event.*)) + event.len;
        }
    }
}
