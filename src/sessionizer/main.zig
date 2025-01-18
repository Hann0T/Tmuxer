const std = @import("std");
const assert = std.debug.assert;
const tmux = @import("../tmux.zig");
pub const Config = @import("Config.zig");

pub fn run(allocator: std.mem.Allocator, config: Config) !void {
    assert(config.directories != null);

    const directories = try std.mem.join(allocator, " ", config.directories.?);
    defer allocator.free(directories);

    const cmd = try std.fmt.allocPrint(allocator, "find {s} -mindepth 1 -maxdepth 1 -type d | fzf", .{directories});
    defer allocator.free(cmd);

    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "bash", "-c", cmd },
    });
    defer {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
    }

    if (result.stderr.len > 0) {
        std.log.err("tmux {s}\n", .{result.stderr});
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
