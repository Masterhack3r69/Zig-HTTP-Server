const std = @import("std");

pub const Request = struct {
    method: []const u8,
    path: []const u8,
    version: []const u8,
};
