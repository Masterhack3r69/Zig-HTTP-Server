const std = @import("std");
const Request = @import("http/request.zig").Request;
const handlers = @import("handlers.zig");

pub fn route(
    req: Request,
    socket: std.posix.socket_t,
) !void {
    if (std.mem.eql(u8, req.path, "/hello")) {
        return handlers.hello(socket);
    }

    // Everything else → static files
    return handlers.staticFile(socket, req.path);
}
