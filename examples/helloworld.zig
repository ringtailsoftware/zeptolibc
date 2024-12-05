const std = @import("std");
const zeptolibc = @import("zeptolibc");

const c = @cImport({
    @cInclude("main.c");
});

pub fn main() !void {
    const writer = std.io.getStdOut().writer();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // init zepto with a memory allocator and a writer (for stdout and stderr)
    zeptolibc.init(allocator, writer);

    c.cmain();
}

