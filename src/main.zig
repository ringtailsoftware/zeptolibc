const std = @import("std");
const zeptolibc = @cImport({
    @cInclude("zeptolibc.h");
});

const alloc_align = 16;
const alloc_metadata_len = std.mem.alignForward(usize, alloc_align, @sizeOf(usize));

var allocatorOpt:?std.mem.Allocator = undefined;
var writeFnOpt:?*const fn(data:[]const u8) void = null;

pub fn init(alloO: ?std.mem.Allocator, writeFnO:?* const fn(data:[]const u8) void) void {
    allocatorOpt = alloO;
    writeFnOpt = writeFnO;
}

// NOTE: this is not a libc function, it's exported so it can be used
//       by vformat in libc.c
// buf must be at least 100 bytes
export fn _formatCInt(buf: [*]u8, value: c_int, base: u8) callconv(.C) usize {
    return std.fmt.formatIntBuf(buf[0..100], value, base, .lower, .{});
}
export fn _formatCUint(buf: [*]u8, value: c_uint, base: u8) callconv(.C) usize {
    return std.fmt.formatIntBuf(buf[0..100], value, base, .lower, .{});
}
export fn _formatCLong(buf: [*]u8, value: c_long, base: u8) callconv(.C) usize {
    return std.fmt.formatIntBuf(buf[0..100], value, base, .lower, .{});
}
export fn _formatCUlong(buf: [*]u8, value: c_ulong, base: u8) callconv(.C) usize {
    return std.fmt.formatIntBuf(buf[0..100], value, base, .lower, .{});
}
export fn _formatCLonglong(buf: [*]u8, value: c_longlong, base: u8) callconv(.C) usize {
    return std.fmt.formatIntBuf(buf[0..100], value, base, .lower, .{});
}
export fn _formatCUlonglong(buf: [*]u8, value: c_ulonglong, base: u8) callconv(.C) usize {
    return std.fmt.formatIntBuf(buf[0..100], value, base, .lower, .{});
}

export fn _fwrite_buf(ptr: [*]const u8, size: usize, stream: *zeptolibc.FILE) callconv(.C) usize {
    _ = stream;
    if (writeFnOpt) |writeFn| {
        writeFn(ptr[0..size]);
    }
    return size;
}

export fn zepto_exit(code:c_int) void {
    std.log.err("EXIT {d}\n", .{code});
    while (true) {}
}

export fn zepto_abort() void {
    std.log.err("ABORT\n", .{});
    while (true) {}
}

export fn zepto_strlen(s: [*:0]const u8) callconv(.C) usize {
    const result = std.mem.len(s);
    return result;
}

export fn zepto_memmove(dest: ?[*]u8, src: ?[*]const u8, n: usize) ?[*]u8 {
    if (@intFromPtr(dest) < @intFromPtr(src)) {
        var index: usize = 0;
        while (index != n) : (index += 1) {
            dest.?[index] = src.?[index];
        }
    } else {
        var index = n;
        while (index != 0) {
            index -= 1;
            dest.?[index] = src.?[index];
        }
    }

    return dest;
}

export fn zepto_strncmp(a: [*:0]const u8, b: [*:0]const u8, n: usize) callconv(.C) c_int {
    var i: usize = 0;
    while (a[i] == b[i] and a[0] != 0) : (i += 1) {
        if (i == n - 1) return 0;
    }
    return @as(c_int, @intCast(a[i])) -| @as(c_int, @intCast(b[i]));
}

export fn zepto_strchr(s: [*:0]const u8, char: c_int) callconv(.C) ?[*:0]const u8 {
    var next = s;
    while (true) : (next += 1) {
        if (next[0] == char) return next;
        if (next[0] == 0) return null;
    }
}

export fn zepto_print(msg: [*:0]const u8) callconv(.C) void {
    std.log.err("{s}", .{std.mem.span(msg)});
}

export fn zepto_strnlen(s: [*:0]const u8, max_len: usize) usize {
    var i: usize = 0;
    while (i < max_len and s[i] != 0) : (i += 1) {}
    return i;
}

export fn zepto_strncpy(s1: [*]u8, s2: [*:0]const u8, n: usize) callconv(.C) [*]u8 {
    const len = zepto_strnlen(s2, n);
    @memcpy(s1[0..len], s2);
    @memset(s1[len..][0 .. n - len], 0);
    return s1;
}

export fn zepto_memcpy(dst: [*]u8, src: [*]u8, size: c_int) callconv(.C) [*]u8 {
    @memcpy(dst[0..@intCast(size)], src[0..@intCast(size)]);
    return dst;
}

export fn zepto_memset(dst: [*]u8, val: u8, size: c_int) callconv(.C) [*]u8 {
    @memset(dst[0..@intCast(size)], val);
    return dst;
}

export fn zepto_sin(x: f64) callconv(.C) f64 {
    return @sin(x);
}
export fn zepto_cos(x: f64) callconv(.C) f64 {
    return @cos(x);
}
export fn zepto_sqrt(x: f64) callconv(.C) f64 {
    return std.math.sqrt(x);
}
export fn zepto_pow(x: f64, y: f64) callconv(.C) f64 {
    return std.math.pow(f64, x, y);
}
export fn zepto_fabs(x: f64) callconv(.C) f64 {
    return @abs(x);
}
export fn zepto_floor(x: f64) callconv(.C) f64 {
    return @floor(x);
}
export fn zepto_ceil(x: f64) callconv(.C) f64 {
    return @ceil(x);
}
export fn zepto_fmod(x: f64, y: f64) callconv(.C) f64 {
    return @mod(x, y);
}


fn getGpaBuf(ptr: [*]u8) []align(alloc_align) u8 {
    const start = @intFromPtr(ptr) - alloc_metadata_len;
    const len = @as(*usize, @ptrFromInt(start)).*;
    return @alignCast(@as([*]u8, @ptrFromInt(start))[0..len]);
}

export fn zepto_malloc(size: usize) callconv(.C) ?[*]align(alloc_align) u8 {
    if (size == 0) {
        return null;
    }
    if (allocatorOpt) |allocator| {
        const full_len = alloc_metadata_len + size;
        const buf = allocator.alignedAlloc(u8, alloc_align, full_len) catch |err| switch (err) {
            error.OutOfMemory => {
                return null;
            },
        };
        @as(*usize, @ptrCast(buf)).* = full_len;
        const result = @as([*]align(alloc_align) u8, @ptrFromInt(@intFromPtr(buf.ptr) + alloc_metadata_len));
        return result;
    } else {
        return null;
    }
}

export fn zepto_realloc(ptr: ?[*]align(alloc_align) u8, size: usize) callconv(.C) ?[*]align(alloc_align) u8 {
    if (allocatorOpt) |allocator| {
        const gpa_buf = getGpaBuf(ptr orelse {
            const result = zepto_malloc(size);
            return result;
        });
        if (size == 0) {
            allocator.free(gpa_buf);
            return null;
        }

        const gpa_size = alloc_metadata_len + size;
        if (allocator.rawResize(gpa_buf, std.math.log2(alloc_align), gpa_size, @returnAddress())) {
            @as(*usize, @ptrCast(gpa_buf.ptr)).* = gpa_size;
            return ptr;
        }

        const new_buf = allocator.reallocAdvanced(
            gpa_buf,
            gpa_size,
            @returnAddress(),
        ) catch |e| switch (e) {
            error.OutOfMemory => {
                return null;
            },
        };
        @as(*usize, @ptrCast(new_buf.ptr)).* = gpa_size;
        const result = @as([*]align(alloc_align) u8, @ptrFromInt(@intFromPtr(new_buf.ptr) + alloc_metadata_len));
        return result;
    } else {
        return null;
    }
}

export fn zepto_calloc(nmemb: usize, size: usize) callconv(.C) ?[*]align(alloc_align) u8 {
    const total = std.math.mul(usize, nmemb, size) catch {
        // TODO: set errno
        //errno = c.ENOMEM;
        return null;
    };
    const ptr = zepto_malloc(total) orelse return null;
    @memset(ptr[0..total], 0);
    return ptr;
}

pub export fn zepto_free(ptr: ?[*]align(alloc_align) u8) callconv(.C) void {
    if (allocatorOpt) |allocator| {
        const p = ptr orelse return;
        allocator.free(getGpaBuf(p));
    }
}

export fn zepto_abs(n:c_int) c_int {
    return @intCast(@abs(n));
}

