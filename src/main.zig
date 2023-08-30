const std = @import("std");
const print = std.debug.print;

const User = struct {
    id: i32,
    name: []u8,
    username: []u8,
    email: []u8,
    address: struct {
        street: []u8,
    },
};

fn jsonUnmarshal(comptime T: type, allocator: std.mem.Allocator, reader: anytype) !std.json.Parsed(T) {
    var tokenReader = std.json.reader(allocator, reader);
    defer tokenReader.deinit();

    return try std.json.parseFromTokenSource(T, allocator, &tokenReader, .{ .ignore_unknown_fields = true });
}

pub fn main() !void {
    var fixedBuffer: [1 << 16]u8 = undefined;

    var fba = std.heap.FixedBufferAllocator.init(&fixedBuffer);
    var allocator = fba.allocator();

    const uri = try std.Uri.parse("http://jsonplaceholder.typicode.com/users");

    var client: std.http.Client = .{ .allocator = allocator };
    defer client.deinit();

    var req = try client.request(.GET, uri, .{ .allocator = allocator }, .{});
    defer req.deinit();
    try req.start();
    try req.wait();

    if (req.response.status != .ok) {
        return error.RequestError;
    }

    var jsonResp = try jsonUnmarshal([]User, allocator, req.reader());
    defer jsonResp.deinit();

    const value = jsonResp.value;

    print("Result \n", .{});
    try std.json.stringify(&value, .{}, std.io.getStdOut().writer());
}
