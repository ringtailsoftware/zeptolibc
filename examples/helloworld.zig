const std = @import("std");
const zeptolibc = @import("zeptolibc");

const c = @cImport({
    @cInclude("main.c");
});

fn writeFn(data:[]const u8) void {
    _ = std.io.getStdOut().writer().write(data) catch 0;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // init zepto with a memory allocator and a writer (for stdout and stderr)
    zeptolibc.init(allocator, writeFn);

    c.cmain();
}

