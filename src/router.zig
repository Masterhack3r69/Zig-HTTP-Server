const std = @import("std");
const Request = @import("http/request.zig").Request;
const handlers = @import("handlers.zig");

pub fn route(
    req: Request,
    socket: std.posix.socket_t,
    allocator: std.mem.Allocator,
) !u16 {
    if (std.mem.eql(u8, req.path, "/hello")) {
        return try handlers.hello(socket);
    }

    if (std.mem.eql(u8, req.path, "/echo")) {
        return try handlers.echo(socket, req);
    }

    // Everything else → static files
    return try handlers.staticFile(socket, req.path, allocator);
}
