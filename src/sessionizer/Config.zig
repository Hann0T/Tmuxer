const std = @import("std");
const assert = std.debug.assert;

const Config = @This();

arena: ?std.heap.ArenaAllocator = null,
directories: ?[][]const u8 = null,

pub fn parse(config: *Config, iter: *std.process.ArgIterator) !void {
    assert(config.arena != null);
    if (iter.inner.index == iter.inner.count) {
        try help();
        return error.InvalidArgument;
    }

    const allocator = config.arena.?.allocator();
    var list = std.ArrayList([]const u8).init(allocator);
    defer list.deinit();

    while (iter.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "--help")) {
            try help();
            return error.HelpArgument;
        }

        if (!std.mem.startsWith(u8, arg, "--")) {
            return error.InvalidArgument;
        }

        if (std.mem.indexOf(u8, arg, "path=")) |index| {
            const start = index + 5;
            if (arg[start..].len <= 0) {
                try help();
                return error.HelpArgument;
            }

            var path_iter = std.mem.splitScalar(u8, arg[start..], ',');
            while (path_iter.next()) |path| {
                if (path.len > 0) {
                    const trimmed = std.mem.trim(u8, path, " ");
                    try list.append(try format_path(allocator, trimmed));
                }
            }
        } else {
            try help();
            return error.HelpArgument;
        }
    }

    config.directories = try list.toOwnedSlice();
}

pub fn help() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Sessionizer options:\n", .{});
    try stdout.print("\n--path=path1,path2,path3\n", .{});
    try stdout.print("\tSpecify one or more directory paths, separated by commas.\n", .{});
    try stdout.print("\nExample:\n", .{});
    try stdout.print("sessionizer --path=/home/user/projects/Zig,/home/user/projects/C\n", .{});

    try bw.flush();
}

pub fn init(alloc_gpa: std.mem.Allocator) Config {
    var config: Config = .{
        .arena = std.heap.ArenaAllocator.init(alloc_gpa),
        .directories = null,
    };
    errdefer config.deinit();

    return config;
}

pub fn deinit(self: *Config) void {
    if (self.arena) |arena| {
        arena.deinit();
    }
}

fn format_path(allocator: std.mem.Allocator, path: []const u8) ![]const u8 {
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    // own the memory
    try buffer.appendSlice(path);
    if (std.mem.endsWith(u8, path, "/")) {
        try buffer.appendSlice("*");
    } else {
        try buffer.appendSlice("/*");
    }

    return buffer.toOwnedSlice();
}
