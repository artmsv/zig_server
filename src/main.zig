const std = @import("std");

const net = std.net;
const Server = net.Server;
const Stream = net.Stream;
const Address = net.Address;

const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;

pub const io_mode = .evented;
// TCP Listener + HTTP protocol + handlers

pub fn main() !void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const address = try Address.resolveIp("127.0.0.1", 8080);
    var server = try address.listen(.{});
    defer server.deinit();

    std.debug.print("Starting: 127.0.0.1:8080\n\n", .{});

    while (true) {
        var connection = try server.accept();
        std.debug.print("Incoming: {}\n", .{connection.address});
        try handler(allocator, &connection.stream);
    }
}

fn handler(allocator: std.mem.Allocator, stream: *net.Stream) !void {
    defer stream.close();
    const first_line = try stream.reader().readUntilDelimiterAlloc(allocator, '\n', std.math.maxInt(usize));
    var first_line_iter = std.mem.split(u8, first_line, " ");

    const method = first_line_iter.next().?;
    const uri = first_line_iter.next().?;
    const version = first_line_iter.next().?;

    var headers = std.StringHashMap([]const u8).init(allocator);

    while (true) {
        const line = try stream.reader()
            .readUntilDelimiterAlloc(allocator, '\n', std.math.maxInt(usize));
        if (line.len == 1 and std.mem.eql(u8, line, "\r")) break;
        var line_iter = std.mem.split(u8, line, ":");
        const key = line_iter.next().?;
        var value = line_iter.next().?;
        if (value[0] == ' ') value = value[1..];
        try headers.put(key, value);
    }

    std.debug.print("method: {s}\nuri: {s}\nversion: {s}\n", .{
        method,
        uri,
        version,
    });

    var headers_iter = headers.iterator();

    std.debug.print("Headers:\n", .{});
    while (headers_iter.next()) |entry| {
        std.debug.print("{s}: {s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
}
