const std = @import("std");
const zeptolibc = @cImport({
    @cInclude("zeptolibc/zeptolibc.h");
});

const alloc_align = std.mem.Alignment.of(usize);
const alloc_metadata_len = std.mem.alignForward(usize, @alignOf(usize), @sizeOf(usize));

pub var allocatorOpt:?std.mem.Allocator = null;
pub var writeFnOpt:?*const fn(data:[]const u8) void = null;

pub fn init(alloO: ?std.mem.Allocator, writeFnO:?* const fn(data:[]const u8) void) void {
    allocatorOpt = alloO;
    writeFnOpt = writeFnO;
}

pub export fn zepto_exit(code:c_int) void {
    _ = code;
    while (true) {}
}

pub export fn zepto_abort() void {
    while (true) {}
}

pub export fn zepto_strlen(s: [*:0]const u8) callconv(.c) usize {
    const result = std.mem.len(s);
    return result;
}

pub export fn zepto_memmove(dest: ?[*]u8, src: ?[*]const u8, n: usize) ?[*]u8 {
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

pub export fn zepto_strncmp(a: [*:0]const u8, b: [*:0]const u8, n: usize) callconv(.c) c_int {
    var i: usize = 0;
    while (a[i] == b[i] and a[0] != 0) : (i += 1) {
        if (i == n - 1) return 0;
    }
    return @as(c_int, @intCast(a[i])) -| @as(c_int, @intCast(b[i]));
}

pub export fn zepto_strchr(s: [*:0]const u8, char: c_int) callconv(.c) ?[*:0]const u8 {
    var next = s;
    while (true) : (next += 1) {
        if (next[0] == char) return next;
        if (next[0] == 0) return null;
    }
}

pub export fn zepto_strnlen(s: [*:0]const u8, max_len: usize) usize {
    var i: usize = 0;
    while (i < max_len and s[i] != 0) : (i += 1) {}
    return i;
}

pub export fn zepto_strncpy(s1: [*]u8, s2: [*:0]const u8, n: usize) callconv(.c) [*]u8 {
    const len = zepto_strnlen(s2, n);
    @memcpy(s1[0..len], s2);
    @memset(s1[len..][0 .. n - len], 0);
    return s1;
}

pub export fn zepto_memcpy(dst: [*]u8, src: [*]u8, size: usize) callconv(.c) [*]u8 {
    @memcpy(dst[0..@intCast(size)], src[0..@intCast(size)]);
    return dst;
}

pub export fn zepto_memset(dst: [*]u8, val: u8, size: usize) callconv(.c) [*]u8 {
    @memset(dst[0..@intCast(size)], val);
    return dst;
}

pub export fn zepto_sin(x: f64) callconv(.c) f64 {
    return @sin(x);
}
pub export fn zepto_cos(x: f64) callconv(.c) f64 {
    return @cos(x);
}
pub export fn zepto_acos(x: f64) callconv(.c) f64 {
    return std.math.acos(x);
}
pub export fn zepto_sqrt(x: f64) callconv(.c) f64 {
    return std.math.sqrt(x);
}
pub export fn zepto_pow(x: f64, y: f64) callconv(.c) f64 {
    return std.math.pow(f64, x, y);
}
pub export fn zepto_fabs(x: f64) callconv(.c) f64 {
    return @abs(x);
}
pub export fn zepto_floor(x: f64) callconv(.c) f64 {
    return @floor(x);
}
pub export fn zepto_ceil(x: f64) callconv(.c) f64 {
    return @ceil(x);
}
pub export fn zepto_fmod(x: f64, y: f64) callconv(.c) f64 {
    return @mod(x, y);
}

fn getGpaBuf(ptr: [*]u8) []align(@alignOf(usize)) u8 {
    const start = @intFromPtr(ptr) - alloc_metadata_len;
    const len = @as(*usize, @ptrFromInt(start)).*;
    return @alignCast(@as([*]u8, @ptrFromInt(start))[0..len]);
}

//fn term_malloc(size: usize, user: ?*anyopaque) callconv(.c) ?*anyopaque {
//    if (user) |userptr| {
//        const self: *ZVTerm = @ptrCast(@alignCast(userptr));
//        if (size == 0) {
//            return null;
//        }
//        const full_len = alloc_metadata_len + size;
//        const buf = self.allocator.alignedAlloc(u8, alloc_align, full_len) catch |err| switch (err) {
//            error.OutOfMemory => return null,
//        };
//        @as(*usize, @ptrCast(buf)).* = full_len;
//        const result = @as([*]align(@alignOf(usize)) u8, @ptrFromInt(@intFromPtr(buf.ptr) + alloc_metadata_len));
//        @memset(result[0..size], 0); // zero memory
//        return result;
//    } else {
//        return null;
//    }
//}
//
//fn getAllocBuf(ptr: [*]u8) []align(@alignOf(usize)) u8 {
//    const start = @intFromPtr(ptr) - alloc_metadata_len;
//    const len = @as(*usize, @ptrFromInt(start)).*;
//    return @alignCast(@as([*]u8, @ptrFromInt(start))[0..len]);
//}
//
//fn term_free(ptr: ?*anyopaque, user: ?*anyopaque) callconv(.c) void {
//    if (user) |userptr| {
//        const self: *ZVTerm = @ptrCast(@alignCast(userptr));
//        const p = ptr orelse return;
//        self.allocator.free(getAllocBuf(@ptrCast(p)));
//    }
//}

pub export fn zepto_malloc(size: usize) callconv(.c) ?[*]align(@alignOf(usize)) u8 {
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
        const result = @as([*]align(@alignOf(usize)) u8, @ptrFromInt(@intFromPtr(buf.ptr) + alloc_metadata_len));
        return result;
    } else {
        return null;
    }
}

pub export fn zepto_realloc(ptr: ?[*]align(@alignOf(usize)) u8, size: usize) callconv(.c) ?[*]align(@alignOf(usize)) u8 {
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
        if (allocator.rawResize(gpa_buf, std.mem.Alignment.fromByteUnits(std.math.log2(@sizeOf(usize))), gpa_size, @returnAddress())) {
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
        const result = @as([*]align(@alignOf(usize)) u8, @ptrFromInt(@intFromPtr(new_buf.ptr) + alloc_metadata_len));
        return result;
    } else {
        return null;
    }
}

pub export fn zepto_calloc(nmemb: usize, size: usize) callconv(.c) ?[*]align(@alignOf(usize)) u8 {
    const total = std.math.mul(usize, nmemb, size) catch {
        // TODO: set errno
        //errno = c.ENOMEM;
        return null;
    };
    if (total == 0) {
        return null;
    }
    const ptr = zepto_malloc(total) orelse return null;
    @memset(ptr[0..total], 0);
    return ptr;
}

pub export fn zepto_free(ptr: ?[*]align(@alignOf(usize)) u8) callconv(.c) void {
    if (allocatorOpt) |allocator| {
        const p = ptr orelse return;
        allocator.free(getGpaBuf(p));
    }
}

pub export fn zepto_abs(n:c_int) c_int {
    return @intCast(@abs(n));
}

// try to append some data into &buf[bufOff]
fn tryAppendBuf(buf:[*:0]u8, size:usize, bufOff:*usize, data:[]const u8) bool {
    if (bufOff.* + data.len > size-1) {   // room to null terminate
        return false;
    } else {
        for (0..data.len) |i| {
            buf[i + bufOff.*] = data[i];
        }
        bufOff.* += data.len;
        return true;
    }
}

pub export fn zepto_vsnprintf(str:[*:0]u8, size:usize, format: [*:0]const u8, ap:*std.builtin.VaList) c_int {
    if (std.mem.span(format).len == 0) @panic("null fmt");

    var bufOff:usize = 0;

    var skip_idx: usize = undefined;
    for (std.mem.span(format), 0..) |byte, i| {
        if (i == skip_idx) {
            continue;
        }
        if (byte != '%') {
            if (!tryAppendBuf(str, size, &bufOff, &.{byte})) return @intCast(bufOff);
            continue;
        }
        const c = format[i + 1] & 0xff;
        skip_idx = i + 1;
        if (c == 0) break;

        var buf:[32]u8 = undefined;

        switch (c) {
            'd' => {
                const s = std.fmt.bufPrint(&buf, "{d}", .{@cVaArg(ap, c_int)}) catch &.{};
                if (!tryAppendBuf(str, size, &bufOff, s)) return @intCast(bufOff);
            },
            'x' => {
                const s = std.fmt.bufPrint(&buf, "{x}", .{@cVaArg(ap, usize)}) catch &.{};
                if (!tryAppendBuf(str, size, &bufOff, s)) return @intCast(bufOff);
            },
            'p' => {
                const s = std.fmt.bufPrint(&buf, "{p}", .{@cVaArg(ap, *usize)}) catch &.{};
                if (!tryAppendBuf(str, size, &bufOff, s)) return @intCast(bufOff);
            },
            's' => {
                const s = std.mem.span(@cVaArg(ap, [*:0]const u8));
                if (!tryAppendBuf(str, size, &bufOff, s)) return @intCast(bufOff);
            },
            '%' => {
                if (!tryAppendBuf(str, size, &bufOff, &.{'%'})) return @intCast(bufOff);
            },
            else => {
                // Print unknown % sequence to draw attention.
                if (!tryAppendBuf(str, size, &bufOff, &.{'%', c})) return @intCast(bufOff);
            },
        }
    }

    str[bufOff] = 0;

    return @intCast(bufOff);
}

pub export fn zepto_snprintf(str:[*:0]u8, size:usize, format: [*:0]const u8, ...) c_int {
    var ap = @cVaStart();
    const result = zepto_vsnprintf(str, size, format, &ap);
    @cVaEnd(&ap);
    return result;
}

//https://github.com/binarycraft007/xv6-riscv-zig/blob/2ed6f50360e2a199866915ef5bb3222b911b5076/src/kernel/log.zig#L57
//extern int zepto_fprintf(FILE *, const char * format, ...);
pub export fn zepto_fprintf(stream:*zeptolibc.FILE, format: [*:0]const u8, ...) c_int {
    _ = stream;
    var written:usize = 0;
    if (writeFnOpt) |writeFn| {
        if (std.mem.span(format).len == 0) @panic("null fmt");

        var ap = @cVaStart();
        var skip_idx: usize = undefined;
        for (std.mem.span(format), 0..) |byte, i| {
            if (i == skip_idx) {
                continue;
            }
            if (byte != '%') {
                writeFn(&.{byte});
                written += 1;
                continue;
            }
            const c = format[i + 1] & 0xff;
            skip_idx = i + 1;
            if (c == 0) break;

            var buf:[32]u8 = undefined;

            switch (c) {
                'd' => {
                    const s = std.fmt.bufPrint(&buf, "{d}", .{@cVaArg(&ap, c_int)}) catch &.{};
                    writeFn(s);
                    written += s.len;
                },
                'x' => {
                    const s = std.fmt.bufPrint(&buf, "{x}", .{@cVaArg(&ap, usize)}) catch &.{};
                    writeFn(s);
                    written += s.len;
                },
                'p' => {
                    const s = std.fmt.bufPrint(&buf, "{p}", .{@cVaArg(&ap, *usize)}) catch &.{};
                    writeFn(s);
                    written += s.len;
                },
                's' => {
                    const s = std.mem.span(@cVaArg(&ap, [*:0]const u8));
                    writeFn(s);
                    written += s.len;
                },
                '%' => {
                    writeFn(&.{'%'});
                    written += 1;
                },
                else => {
                    // Print unknown % sequence to draw attention.
                    writeFn(&.{'%'});
                    writeFn(&.{c});
                    written += 2;
                },
            }
        }
        @cVaEnd(&ap);
    }
    return @intCast(written);
}


