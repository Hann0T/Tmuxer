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

pub fn in_tmux(allocator: std.mem.Allocator) !bool {
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{ "bash", "-c", "echo $TMUX" },
    });
    defer {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
    }

    if (result.stderr.len > 0) {
        return error.StdErr;
    }

    // TODO: better condition
    return result.stdout.len > 1;
}
