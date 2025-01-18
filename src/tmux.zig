const std = @import("std");

pub fn has_session(allocator: std.mem.Allocator, name: []const u8) !bool {
    const args = [_][]const u8{ "tmux", "has-session", "-t", name };
    var child = std.process.Child.init(&args, allocator);
    child.stdout_behavior = .Ignore;
    child.stderr_behavior = .Ignore;

    const res = try child.spawnAndWait();

    if (res.Exited == 1) {
        return false;
    }

    return true;
}

pub fn new_session(allocator: std.mem.Allocator, name: []const u8, path: []const u8) !void {
    const args = [_][]const u8{ "tmux", "new-session", "-c", path, "-ds", name };
    var child = std.process.Child.init(&args, allocator);
    child.stdout_behavior = .Ignore;
    child.stderr_behavior = .Ignore;

    const res = try child.spawnAndWait();

    if (res.Exited == 1) {
        return error.DuplicateSession;
    }
}

pub fn switch_client(allocator: std.mem.Allocator, name: []const u8) !void {
    const args = [_][]const u8{ "tmux", "switch-client", "-t", name };
    var child = std.process.Child.init(&args, allocator);
    child.stdout_behavior = .Ignore;
    child.stderr_behavior = .Ignore;

    const res = try child.spawnAndWait();

    if (res.Exited == 1) {
        return error.SessionDoesNotExists;
    }
}

pub fn attach(allocator: std.mem.Allocator, name: []const u8) !void {
    const args = [_][]const u8{ "tmux", "attach", "-t", name };
    var child = std.process.Child.init(&args, allocator);
    child.stdout_behavior = .Ignore;
    child.stderr_behavior = .Ignore;

    const res = try child.spawnAndWait();

    if (res.Exited == 1) {
        return error.InvalidSession;
    }
}

// https://github.com/ghostty-org/ghostty/blob/72d085525b22d66468c5969a4d507a0fa68d4a04/src/os/env.zig#L71
pub fn in_tmux(allocator: std.mem.Allocator) !bool {
    _ = allocator;
    return std.posix.getenv("TMUX") != null;
}
