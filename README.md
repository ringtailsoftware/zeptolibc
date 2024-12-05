# ZeptoLibC

A few of the most essential libc functions needed when working with C code in Zig.

Much of the code is taken from [ziglibc](https://github.com/marler8997/ziglibc).

ZeptoLibC provides, among others:

 - `malloc()`, `calloc()`, `realloc()`, `free()`
 - `printf()`, `fprintf()`, `snprintf()`
 - `strcat()`, `strcpy()`, `strncmp()`, `strchr()`, `strncpy()`
 - `abs()`, `fabs()`, `sin()`, `cos()`, `sqrt()`, `pow()`, `floor()`, `ceil()`
 - `memcmp()`, `memset()`, `memmove()`

ZeptoLibC is not intended to implement the full C library and does the bare minimum to support I/O operations (just `printf()`). The aim is to allow simple porting of existing C code to freestanding/baremetal environments such as WASM and embedded systems.

All ZeptoLibC functions start with the prefix `zepto_`, eg. `zepto_malloc()` so as to not clash with any existing C functions. The file `zeptolibc.h` provides `#define`s for mapping `malloc()` -> `zepto_malloc()`.

# How to use

For a complete example, see https://github.com/ringtailsoftware/zeptolibc-example

First we add the library as a dependency in our `build.zig.zon` file.

zig fetch --save git+https://github.com/ringtailsoftware/zeptolibc.git

And we add it to `build.zig` file.
```zig
const zeptolibc_dep = b.dependency("zeptolibc", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("zeptolibc", zeptolibc_dep.module("zeptolibc"));
exe.addIncludePath(zeptolibc_dep.path("src/"));
```

# Usage:

Add `#include "zeptolibc.h"` to your C code.

```c
    #include "zeptolibc.h"

    void my_greeting(void) {
        printf("Hello world\n");
    }
```

Setup ZeptoLibC from Zig and call the C code.

`zeptolibc.init()` may be passed `null` for both writer and allocator. A `null` allocator will cause `malloc()` to always return `NULL`. A `null` writer will silently drop written data.

```zig
    const std = @import("std");
    const zeptolibc = @import("zeptolibc");

    const c = @cImport({
        @cInclude("greeting.c");
    });

    pub fn main() !void {
        const writer = std.io.getStdOut().writer();
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();

        // init zepto with a memory allocator and a writer (for stdout and stderr)
        zeptolibc.init(allocator, writer);

        c.my_greeting();
    }
```

