const std = @import("std");
const sendResponse = @import("http/response.zig").sendResponse;
const sendHeaders = @import("http/response.zig").sendHeaders;
const getMimeType = @import("http/mime.zig").getMimeType;

pub fn staticFile(
    socket: std.posix.socket_t,
    path: []const u8,
    allocator: std.mem.Allocator,
) !void {
    // Prevent path traversal
    if (std.mem.indexOf(u8, path, "..") != null) {
        return sendResponse(
            socket,
            "403 Forbidden",
            "text/plain",
            "Forbidden",
        );
    }

    // Map "/" → "/index.html"
    const rel_path = if (std.mem.eql(u8, path, "/"))
        "index.html"
    else
        path[1..]; // remove leading "/"

    const full_path = try std.fmt.allocPrint(
        allocator,
        "public/{s}",
        .{rel_path},
    );
    // Note: No need to defer free(full_path) as we are using an ArenaAllocator

    var file = std.fs.cwd().openFile(full_path, .{}) catch {
        return sendResponse(
            socket,
            "404 Not Found",
            "text/plain",
            "Not Found",
        );
    };
    defer file.close();

    const stat = try file.stat();

    try sendHeaders(
        socket,
        "200 OK",
        getMimeType(rel_path),
        stat.size,
    );

    var buf: [4096]u8 = undefined;
    while (true) {
        const bytes_read = try file.read(&buf);
        if (bytes_read == 0) break;
        _ = try std.posix.send(socket, buf[0..bytes_read], 0);
    }
}

pub fn hello(socket: std.posix.socket_t) !void {
    return sendResponse(
        socket,
        "200 OK",
        "text/plain",
        "Hello from Zig HTTP Server!",
    );
}

pub fn echo(socket: std.posix.socket_t, req: @import("http/request.zig").Request) !void {
    return sendResponse(
        socket,
        "200 OK",
        "text/plain",
        req.body,
    );
}

pub fn badRequest(socket: std.posix.socket_t) !void {
    return sendResponse(
        socket,
        "400 Bad Request",
        "text/plain",
        "Bad Request",
    );
}
