const std = @import("std");
const sessionizer = @import("sessionizer/main.zig");
const assert = std.debug.assert;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    var iter = try std.process.argsWithAllocator(allocator);
    defer iter.deinit();

    const binary_name = iter.next().?;

    while (iter.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            try help(binary_name);
            return;
        }

        if (std.mem.eql(u8, arg, "sessionizer")) {
            var config = sessionizer.Config.init(allocator);
            defer config.deinit();

            if (sessionizer.Config.parse(&config, &iter) catch |err| {
                std.log.err("{s}", .{@errorName(err)});
                return;
            }) {
                try sessionizer.run(allocator, config);
            }
            return;
        }

        if (std.mem.eql(u8, arg, "mkdir")) {
            std.log.info("Not implemented\n", .{});
            return;
        }

        if (std.mem.eql(u8, arg, "exec")) {
            std.log.info("Not implemented\n", .{});
            return;
        }

        std.log.info("Invalid command\n", .{});
    }

    // print help if the loop didn't do anything
    try help(binary_name);
    return;
}

fn help(binary_name: []const u8) !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("{s} [-h | --help] <command>\n", .{binary_name});
    try stdout.print("\nList of commands:\n", .{});
    try stdout.print("  sessionizer: Open the tmux sessionizer\n", .{});
    try stdout.print("  mkdir: Create a directory in one of the sessionizer paths\n", .{});
    try stdout.print("  exec: Execute a command in one of the tmux sessions\n", .{});

    try bw.flush();
}
