const std = @import("std");

const net = std.net;
// const StreamServer = net.Stream;
const Server = net.Server;
const Stream = net.Stream;
const Address = net.Address;

pub const io_mode = .evented;
// TCP Listener + HTTP protocol + handlers

pub fn main() !void {
    const address = try Address.resolveIp("127.0.0.1", 8080);
    var server = try address.listen(.{});
    defer server.deinit();

    std.debug.print("Starting: 127.0.0.1:8080\n\n", .{});

    while (true) {
        var connection = try server.accept();
        std.debug.print("Incoming: {}\n", .{connection.address});
        try handler(&connection.stream);
    }
}

fn handler(stream: *net.Stream) !void {
    defer stream.close();
    try stream.writer().print("Hello world from zig", .{});
}
