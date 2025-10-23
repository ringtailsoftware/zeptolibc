const std = @import("std");
const zeptolibc = @import("zeptolibc");

const c = @cImport({
    @cInclude("main.c");
});

fn writeFn(data:[]const u8) void {
    var buf: [512]u8 = undefined;
    var w = std.fs.File.stdout().writer(&buf);
    const stdout = &w.interface;
    _ = stdout.write(data) catch 0;
    _ = stdout.flush() catch 0;
}

pub fn main() !void {
    var buffer: [4096]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    // init zepto with a memory allocator and a writer (for stdout and stderr)
    zeptolibc.init(allocator, writeFn);

    c.cmain();
}

