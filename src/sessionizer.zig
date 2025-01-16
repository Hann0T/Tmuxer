const std = @import("std");
const tmux = @import("./tmux.zig");

pub fn run(allocator: std.mem.Allocator) !void {
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "bash", "-c", "find /home/hann0t/Personal/* /home/hann0t/Work/* -mindepth 1 -maxdepth 1 -type d | fzf" },
    });
    defer {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
    }

    if (result.stderr.len > 0) {
        return error.StdErr;
    }

    if (result.stdout.len <= 0) {
        return;
    }

    const selected: []const u8 = std.mem.trimRight(u8, result.stdout, "\n");

    var iter = std.mem.splitAny(u8, selected, "/\n");
    var base_name: []const u8 = undefined;
    while (iter.next()) |splited| {
        if (splited.len > 0) {
            base_name = splited;
        }
    }

    const has_session = try tmux.has_session(allocator, base_name);
    std.debug.print("has session {s}? {any}\n", .{ base_name, has_session });
    if (!has_session) {
        try tmux.new_session(allocator, base_name, selected);
    }

    if (try tmux.in_tmux(allocator)) {
        std.debug.print("switching to session: {s}\n", .{base_name});
        try tmux.switch_client(allocator, base_name);
    } else {
        std.debug.print("attaching to session: {s}\n", .{base_name});
        try tmux.attach(allocator, base_name);
    }
}
