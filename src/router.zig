const std = @import("std");
const Request = @import("http/request.zig").Request;
const handlers = @import("handlers.zig");

pub fn route(
    req: Request,
    socket: std.posix.socket_t,
    allocator: std.mem.Allocator,
) !void {
    if (std.mem.eql(u8, req.path, "/hello")) {
        return handlers.hello(socket);
    }

    if (std.mem.eql(u8, req.path, "/echo")) {
        return handlers.echo(socket, req);
    }

    // Everything else → static files
    return handlers.staticFile(socket, req.path, allocator);
}
