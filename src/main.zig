const std = @import("std");
const parseRequest = @import("http/parser.zig").parseRequest;
const route = @import("router.zig").route;
const handlers = @import("handlers.zig");

var running = std.atomic.Value(bool).init(true);

fn consoleCtrlHandler(ctrl_type: std.os.windows.DWORD) callconv(.winapi) std.os.windows.BOOL {
    _ = ctrl_type;
    running.store(false, .seq_cst);
    return 1;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Register Ctrl-C handler
    if (std.os.windows.kernel32.SetConsoleCtrlHandler(consoleCtrlHandler, 1) == 0) {
        std.log.err("Failed to set console ctrl handler", .{});
    }

    var pool: std.Thread.Pool = undefined;
    try pool.init(.{
        .allocator = allocator,
        .n_jobs = std.Thread.getCpuCount() catch 4,
    });
    defer pool.deinit();

    const address = try std.net.Address.parseIp("0.0.0.0", 8080);

    var server = try address.listen(.{
        .reuse_address = true,
    });
    defer server.deinit();

    // Set accept timeout (1 second) for the server socket
    const timeout_ms: u32 = 1000;
    try std.posix.setsockopt(
        server.stream.handle,
        std.posix.SOL.SOCKET,
        std.posix.SO.RCVTIMEO,
        std.mem.asBytes(&timeout_ms),
    );

    std.log.info("Listening on http://localhost:8080. Press Ctrl+C to stop.", .{});

    while (running.load(.seq_cst)) {
        const conn = server.accept() catch |err| {
            if (err == error.WouldBlock) {
                continue;
            }
            std.log.err("Accept error: {}", .{err});
            continue;
        };

        try pool.spawn(handleConnection, .{ conn, allocator });
    }

    std.log.info("Stopping server...", .{});
    // pool.deinit() will wait for all tasks to finish
}

fn logRequest(method: []const u8, path: []const u8, status: u16, duration_ns: u64) void {
    const duration_ms = @as(f64, @floatFromInt(duration_ns)) / 1_000_000.0;
    std.log.info("[INFO] {s} {s} {} {d:.2}ms", .{ method, path, status, duration_ms });
}

fn handleConnection(conn: std.net.Server.Connection, allocator: std.mem.Allocator) void {
    defer conn.stream.close();

    // Set receive timeout (5 seconds)
    const timeout_ms: u32 = 5000;
    std.posix.setsockopt(
        conn.stream.handle,
        std.posix.SOL.SOCKET,
        std.posix.SO.RCVTIMEO,
        std.mem.asBytes(&timeout_ms),
    ) catch |err| {
        std.log.err("Failed to set socket timeout: {}", .{err});
        return;
    };

    while (true) {
        // Scope for the ArenaAllocator to deinit after each request
        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();
        const arena_allocator = arena.allocator();

        var buffer: [4096]u8 = undefined;

        const bytes_read = std.posix.recv(
            conn.stream.handle,
            &buffer,
            0,
        ) catch |err| {
            // error.WouldBlock is the timeout on Windows
            if (err != error.WouldBlock) {
                std.log.err("Socket recv error: {}", .{err});
            }
            return;
        };

        if (bytes_read == 0) return; // Client closed connection

        var timer = std.time.Timer.start() catch null;

        const req = parseRequest(arena_allocator, buffer[0..bytes_read]) catch |err| {
            // If we read something but couldn't parse it, log it
            std.log.err("HTTP parse error: {}", .{err});
            _ = handlers.badRequest(conn.stream.handle) catch {};
            return;
        };

        const status = route(req, conn.stream.handle, arena_allocator) catch |err| {
            std.log.err("Routing error: {}", .{err});
            return;
        };

        const duration = if (timer) |*t| t.read() else 0;
        logRequest(req.method, req.path, status, duration);
    }
}
