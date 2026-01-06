const std = @import("std");
const Request = @import("request.zig").Request;

pub const Header = @import("request.zig").Header;

pub const ParseError = error{
    EmptyRequest,
    InvalidRequestLine,
    InvalidHeader,
};

pub fn parseRequest(allocator: std.mem.Allocator, buffer: []const u8) !Request {
    // Find the end of the header block (\r\n\r\n)
    const header_end = std.mem.indexOf(u8, buffer, "\r\n\r\n") orelse return ParseError.EmptyRequest;
    const header_block = buffer[0..header_end];
    const body = buffer[header_end + 4 ..];

    var lines = std.mem.splitSequence(u8, header_block, "\r\n");

    // 1. Request Line
    const request_line = lines.next() orelse return ParseError.EmptyRequest;
    var parts = std.mem.splitScalar(u8, request_line, ' ');

    const method = parts.next() orelse return ParseError.InvalidRequestLine;
    const path = parts.next() orelse return ParseError.InvalidRequestLine;
    const version = parts.next() orelse return ParseError.InvalidRequestLine;

    // 2. Headers
    var headers = std.ArrayListUnmanaged(Header){};
    while (lines.next()) |line| {
        if (line.len == 0) continue;

        const colon_idx = std.mem.indexOf(u8, line, ": ") orelse continue;
        const name = line[0..colon_idx];
        const value = line[colon_idx + 2 ..];

        try headers.append(allocator, .{
            .name = name,
            .value = value,
        });
    }

    return Request{
        .method = method,
        .path = path,
        .version = version,
        .headers = try headers.toOwnedSlice(allocator),
        .body = body,
    };
}
