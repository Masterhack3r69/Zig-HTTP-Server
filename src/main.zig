const std = @import("std");
const parseRequest = @import("http/parser.zig").parseRequest;
const route = @import("router.zig").route;
const handlers = @import("handlers.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

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

    std.log.info("Listening on http://localhost:8080", .{});

    while (true) {
        const conn = try server.accept();
        try pool.spawn(handleConnection, .{ conn, allocator });
    }
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

        const req = parseRequest(arena_allocator, buffer[0..bytes_read]) catch |err| {
            // If we read something but couldn't parse it, log it
            std.log.err("HTTP parse error: {}", .{err});
            handlers.badRequest(conn.stream.handle) catch {};
            return;
        };

        std.log.info("{s} {s}", .{ req.method, req.path });

        route(req, conn.stream.handle, arena_allocator) catch |err| {
            std.log.err("Routing error: {}", .{err});
            return;
        };
    }
}
