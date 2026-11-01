## Code Style
- **Naming**: PascalCase for types/structs, camelCase for variables/fields and functions, but if a function returns a type - PascalCase
- **Comments**: TODO comments for future work, doc comments (///) for public API

## Imports

Never use in-place imports:

```zig
// BAD
var sink: @import("../store/query/Sink.zig") = .{};
defer sink.deinit(a);

// GOOD
const Sink = @import("../store/query/Sink.zig");
...
var sink: Sink = .{};
defer sink.deinit(a);
```

### Current zig version

@intCast, @bitCast take a single argument:

```zig
var a: u16 = 0xabcd; // runtime-known
_ = &a;
const b: u8 = @intCast(a);
_ = b;
```

std.ArrayList:

```zig
var list = try ArrayList(i8).initCapacity(a, 200); // OR ArrayList(i8).empty
defer list.deinit(a);
```

Use slices indexing and length properties instead of pointer arithmetic:

```zig
const arr: [5]u8 = [_]u8{1, 2, 3, 4, 5};
// GOOD
for (arr) |value, i| {
    try testing.expect(value == arr[index]);
    arr[i] += 1;
}
// BAD
for (arr) |*ptr, index| {
    try testing.expect(*ptr == arr[index]);
    ptr.* += 1;
}
```

### Test

Good test has multiple cases
```zig
test "bitsetIsEmpty" {
    const f = struct {
        fn f(alloc: Allocator, len: usize, set: []const usize, expectedEmpty: bool) !void {
            var bitset: std.bit_set.DynamicBitSetUnmanaged = try .initEmpty(alloc, len);
            defer bitset.deinit(alloc);

            for (set) |i| {
                bitset.set(i);
            }

            try testing.expectEqual(expectedEmpty, BlockQuery.bitsetIsEmpty(&bitset));
        }
    }.f;

    const alloc = testing.allocator;
    try f(alloc, 0, &.{}, true);
    try f(alloc, 1, &.{}, true);
    try f(alloc, 1, &.{0}, false);
    try f(alloc, 64, &.{42}, false);
    try f(alloc, 64, &.{}, true);
    try f(alloc, 129, &.{128}, false);
    try f(alloc, 128, &.{127}, false);
    try f(alloc, 127, &.{126}, false);
}
```

And has proper assertions comparing all the fields at once:

```zig
// GOOD
const h = Self.decode(encodeBuf[0..offset]);
try std.testing.expectEqualDeep(case.header, h);
// BAD
const h = Self.decode(encodeBuf[0..offset]);
try std.testing.expectEqual(case.header.sid, h.sid);
try std.testing.expectEqual(case.header.minTs, h.minTs);
try std.testing.expectEqual(case.header.maxTs, h.maxTs);
```

Assertions infer types implicitly:
```zig
// GOOD
try testing.expectEqual(1, calls);
// BAD
try testing.expectEqual(@as(usize, 1), calls);
```

### Memory management

Make sure first an ArrayList has enough space:

```zig
// GOOD
try self.garbage.ensureUnusedCapacity(alloc, 1);
...
self.garbage.appendAssumeCapacity(buf);
// BAD
try self.garbage.append(alloc, buf);
```
### Allocator.create

If an object is destroyed in the same scope there is no benefit to create it via allocator:
```zig
// GOOD
fn init() Object {
    return .{
        ...
    };
}

const obj = Object.init();
// BAD
fn init(alloc: Allocator) !Object {
    const self = try alloc.create(SkewedMergeFixture);
    errdefer alloc.destroy(self);
    ...
    return self;
}

var obj = try Object.init(alloc);
defer obj.deinit(alloc); // this is the reason
```

### Docs

Use zigdoc to validate the API of the used Zig version, e.g.:
- zigdoc std.ArrayList
- zigdoc std.mem.Allocator
- zigdoc std.http.Server


