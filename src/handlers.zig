const std = @import("std");
const sendResponse = @import("http/response.zig").sendResponse;
const getMimeType = @import("http/mime.zig").getMimeType;

pub fn staticFile(
    socket: std.posix.socket_t,
    path: []const u8,
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
        std.heap.page_allocator,
        "public/{s}",
        .{rel_path},
    );
    defer std.heap.page_allocator.free(full_path);

    var file = std.fs.cwd().openFile(full_path, .{}) catch {
        return sendResponse(
            socket,
            "404 Not Found",
            "text/plain",
            "Not Found",
        );
    };
    defer file.close();

    const content = try file.readToEndAlloc(
        std.heap.page_allocator,
        1024 * 1024,
    );
    defer std.heap.page_allocator.free(content);

    try sendResponse(
        socket,
        "200 OK",
        getMimeType(rel_path),
        content,
    );
}

pub fn hello(socket: std.posix.socket_t) !void {
    return sendResponse(
        socket,
        "200 OK",
        "text/plain",
        "Hello from Zig HTTP Server!",
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
