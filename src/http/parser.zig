const std = @import("std");
const Request = @import("request.zig").Request;

pub const ParseError = error{
    EmptyRequest,
    InvalidRequestLine,
};

pub fn parseRequest(buffer: []const u8) ParseError!Request {
    // Find first CRLF
    const line_end = std.mem.indexOf(u8, buffer, "\r\n") orelse return ParseError.EmptyRequest;

    const request_line = buffer[0..line_end];

    // Split by spaces
    var parts = std.mem.splitScalar(u8, request_line, ' ');

    const method = parts.next() orelse return ParseError.InvalidRequestLine;
    const path = parts.next() orelse return ParseError.InvalidRequestLine;
    const version = parts.next() orelse return ParseError.InvalidRequestLine;

    // Extra garbage = invalid
    if (parts.next() != null)
        return ParseError.InvalidRequestLine;

    return Request{
        .method = method,
        .path = path,
        .version = version,
    };
}
