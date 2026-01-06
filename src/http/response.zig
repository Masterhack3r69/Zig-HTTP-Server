const std = @import("std");

pub fn sendHeaders(
    socket: std.posix.socket_t,
    status: []const u8,
    content_type: []const u8,
    content_length: usize,
) !void {
    var header_buf: [512]u8 = undefined;

    const header = try std.fmt.bufPrint(
        &header_buf,
        "HTTP/1.1 {s}\r\n" ++
            "Content-Length: {}\r\n" ++
            "Content-Type: {s}\r\n" ++
            "Connection: keep-alive\r\n" ++
            "\r\n",
        .{ status, content_length, content_type },
    );

    _ = try std.posix.send(socket, header, 0);
}

pub fn sendResponse(
    socket: std.posix.socket_t,
    status: []const u8,
    content_type: []const u8,
    body: []const u8,
) !void {
    try sendHeaders(socket, status, content_type, body.len);

    if (body.len > 0) {
        _ = try std.posix.send(socket, body, 0);
    }
}
