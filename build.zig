const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const libc = b.addLibrary(.{
        .linkage = .static,
        .name = "zeptolibc",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .single_threaded = true,
        }),
    });

    libc.addIncludePath(b.path("include"));
    for (header_files) |header_name| {
        libc.installHeader(
            b.path(b.fmt("include/{s}", .{header_name})),
            header_name,
        );
    }

    libc.installHeadersDirectory(b.path("include/zeptolibc"), "zeptolibc", .{});

    const zeptolibc_mod = b.addModule("zeptolibc", .{
        .root_source_file = b.path("src/main.zig"),
    });
    zeptolibc_mod.addIncludePath(b.path("include"));
}

const header_files = [_][]const u8{
    "stdlib.h",
    "string.h",
    "inttypes.h",
    "string.h",
    "zeptolibc/zeptolibc.h",
};

