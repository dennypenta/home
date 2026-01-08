---
argument-hint: [code, destination, func]
description: Port Go to Zig
---

## Process

### 1. Analyze Go Code
- Parse the Go function signature (receiver, parameters, return types)
- Identify method calls within the function body
- Map Go types to Zig equivalents
- Multiple returns → create a struct type

### 2. Read Destination File
- Use the Read tool to examine the target Zig file
- Identify the target struct (e.g., `MemBlock`)
- Find existing methods on that struct to avoid creating duplicates
- Look for existing type definitions

### 3. Generate Zig Code
Create the target function following these rules:

**Function Signature:**
- Convert receiver to `self: *StructName`
- Add `alloc: Allocator` if memory allocation is needed
- Convert parameters using type mappings
- Use error union return type (!ReturnType) for functions that can error, every function with an allocator returns an error
- If multiple return values, create a result struct

**Function Body:**
- Map method calls to Zig style:
  - Check if the method exists in the file
  - If it exists, call it; if not, create a stub
- Preserve the logic flow
- Create stub implementations for missing methods

**Stub Methods:**
- Create placeholder implementations for undefined methods
- Use underscore assignment (_ = param;) to silence unused parameter warnings
- Leave function bodies empty or with minimal placeholder logic
- Less comments is better

**Type Definitions:**
- Only create new types if you can infer them clearly
- Skip type definitions if uncertain

### 4. Output Format
- Insert the generated code at the appropriate location in the file
- Use proper Zig formatting and indentation
- Add the main function first, then stubs below it
- Group related code together

## Example

**Input:**
```go
func (ib *inmemoryBlock) MarshalUnsortedData(sb *storageBlock, firstItemDst, commonPrefixDst []byte, compressLevel int) ([]byte, []byte, uint32, marshalType) {
    ib.SortItems()
    return ib.marshalData(sb, firstItemDst, commonPrefixDst, compressLevel)
}
```

**Target:** `table.zig`, function `MemBlock.encodeUnsorted`

**Output:**
```zig
const EncodedMemBlock = struct {
    firstItem: []u8,
    commonPrefix: []u8,
    itemCount: u32,
    marshalType: MarshalType, // Only if MarshalType found in file
};

fn encodeUnsorted(
    self: *MemBlock,
    alloc: Allocator,
    sb: *StorageBlock,
    firstItemDst: []u8,
    commonPrefixDst: []u8,
    compressLevel: i64,
) !EncodedMemBlock {
    self.sortData(); // Found in file, so we call it
    return self.encode(alloc, sb, firstItemDst, commonPrefixDst, compressLevel);
}

fn encode(
    self: *MemBlock,
    alloc: Allocator,
    sb: *StorageBlock,
    firstItemDst: []u8,
    commonPrefixDst: []u8,
    compressLevel: i64,
) !EncodedMemBlock {
    _ = self;
    _ = alloc;
    _ = sb;
    _ = firstItemDst;
    _ = commonPrefixDst;
    _ = compressLevel;
    return EncodedMemBlock{
        .firstItem = &[_]u8{},
        .commonPrefix = &[_]u8{},
        .itemCount = 0,
        .marshalType = undefined,
    };
}
```

## Important Notes
- **DO NOT** make the code fully compilable - focus on structure
- **DO** create stubs for missing methods
- **DO** check the destination file for existing methods before creating stubs
- **DO** use proper Zig error handling (error union return type with !)
- **DO** silence unused parameters with underscore assignment (_ = param;)
- **SKIP** creating types you can't confidently infer
- Preserve the logical flow and structure of the original Go code

## Execution Steps
1. Read the destination Zig file $2 to understand existing code
2. Parse the Go code structure in $1
3. Generate the Zig equivalent in a function $3 with proper stubs

