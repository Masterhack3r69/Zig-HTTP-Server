const std = @import("std");
const parseRequest = @import("http/parser.zig").parseRequest;
const route = @import("router.zig").route;
const handlers = @import("handlers.zig");

pub fn main() !void {
    const address = try std.net.Address.parseIp("0.0.0.0", 8080);

    var server = try address.listen(.{
        .reuse_address = true,
    });
    defer server.deinit();

    std.log.info("Listening on http://localhost:8080", .{});

    while (true) {
        var conn = try server.accept();
        defer conn.stream.close();

        var buffer: [4096]u8 = undefined;

        const bytes_read = try std.posix.recv(
            conn.stream.handle,
            &buffer,
            0,
        );
        if (bytes_read == 0) continue;

        const req = parseRequest(buffer[0..bytes_read]) catch {
            try handlers.badRequest(conn.stream.handle);
            continue;
        };

        try route(req, conn.stream.handle);
    }
}
