# Zstd Dictionary Compression Guide

## Overview

Dictionary compression improves compression ratios for small, similar data by learning common patterns. Particularly effective for:
- JSON/XML/log files with repeated structure
- Small files (< 100KB)
- Data with consistent schemas
- Protocol messages

**Performance gain examples:**
- Small JSON: 30-50% better compression
- Log files: 20-40% better compression
- Protocol buffers: 40-60% better compression

## When to Use Dictionaries

**Good use cases:**
- Compressing many similar small files
- Structured data (JSON, XML, CSV)
- Application logs with consistent format
- Network protocol messages
- Database rows with fixed schema

**Poor use cases:**
- Large files (> 1MB) - dictionary overhead not worth it
- Each file has unique structure
- Random binary data
- Already well-compressed data

## Dictionary APIs

### Simple API (One-Time Usage)

Use when compressing only once with a dictionary:

```c
// Compression
size_t compressedSize = ZSTD_compress_usingDict(
    dst, dstCapacity,
    src, srcSize,
    dict, dictSize,
    compressionLevel
);

// Decompression
size_t decompressedSize = ZSTD_decompress_usingDict(
    dst, dstCapacity,
    src, srcSize,
    dict, dictSize
);
```

**Drawback:** Dictionary is re-processed every call - very inefficient for multiple operations.

### Digested Dictionary API (Recommended)

Pre-process dictionary once, reuse many times:

```c
// 1. Create digested dictionary (do once)
ZSTD_CDict* cdict = ZSTD_createCDict(dict, dictSize, compressionLevel);
ZSTD_DDict* ddict = ZSTD_createDDict(dict, dictSize);

// 2. Compress many files
for (each file) {
    size_t compressedSize = ZSTD_compress_usingCDict(
        cctx,
        dst, dstCapacity,
        src, srcSize,
        cdict
    );
}

// 3. Decompress many files
for (each file) {
    size_t decompressedSize = ZSTD_decompress_usingDDict(
        dctx,
        dst, dstCapacity,
        src, srcSize,
        ddict
    );
}

// 4. Cleanup
ZSTD_freeCDict(cdict);
ZSTD_freeDDict(ddict);
```

**Critical rule:** Always pre-digest dictionaries for repeated use. Loading raw dictionaries kills performance.

### Context API (Advanced)

Load dictionary into reusable context:

```c
ZSTD_CCtx* cctx = ZSTD_createCCtx();

// Load dictionary into context
ZSTD_CCtx_loadDictionary(cctx, dict, dictSize);

// Or reference pre-digested dictionary
ZSTD_CCtx_refCDict(cctx, cdict);

// Compress multiple files
for (each file) {
    size_t result = ZSTD_compress2(cctx, dst, dstCapacity, src, srcSize);
}

ZSTD_freeCCtx(cctx);
```

**Benefits:**
- Dictionary stays loaded across operations
- Can combine with parameter settings
- Most flexible approach

## Creating Dictionaries

### Using Training Data

Best practice: Train dictionary from representative sample data

```bash
# Using zstd CLI tool
zstd --train samples/*.json -o dict.zstd

# With size constraint (max 100KB dictionary)
zstd --train --maxdict=102400 samples/*.log -o dict.zstd
```

### Programmatic Training

```c
// Prepare training samples
void* samplesBuffer;  // Concatenated samples
size_t* samplesSizes; // Array of individual sample sizes
unsigned nbSamples;   // Number of samples
size_t maxDictSize = 100 * 1024;  // 100KB

// Train dictionary
size_t dictSize = ZDICT_trainFromBuffer(
    dictBuffer, maxDictSize,
    samplesBuffer,
    samplesSizes, nbSamples
);

if (ZDICT_isError(dictSize)) {
    // Handle error
}

// Use trained dictionary
ZSTD_CDict* cdict = ZSTD_createCDict(dictBuffer, dictSize, compressionLevel);
```

### Training Data Guidelines

**Sample selection:**
- Use 100-1000 representative samples
- Total size: 100x larger than desired dictionary size
- Samples should be similar to production data
- Include edge cases and variations

**Dictionary size:**
- Small files (< 10KB): 10-50KB dictionary
- Medium files (10-100KB): 50-100KB dictionary
- Larger dictionaries rarely improve ratios

## Complete Example

```c
#include <zstd.h>
#include <stdlib.h>
#include <stdio.h>

void compress_many_with_dict(const char** files, int numFiles,
                              const void* dict, size_t dictSize) {
    // 1. Pre-digest dictionary
    ZSTD_CDict* cdict = ZSTD_createCDict(dict, dictSize, 3);
    if (!cdict) {
        fprintf(stderr, "Failed to create dictionary\n");
        return;
    }

    // 2. Create reusable context
    ZSTD_CCtx* cctx = ZSTD_createCCtx();

    // 3. Process each file
    for (int i = 0; i < numFiles; i++) {
        // Read file
        size_t srcSize;
        void* src = readFile(files[i], &srcSize);

        // Allocate output
        size_t dstCapacity = ZSTD_compressBound(srcSize);
        void* dst = malloc(dstCapacity);

        // Compress with dictionary
        size_t compressedSize = ZSTD_compress_usingCDict(
            cctx, dst, dstCapacity,
            src, srcSize,
            cdict
        );

        if (ZSTD_isError(compressedSize)) {
            fprintf(stderr, "Compression failed: %s\n",
                    ZSTD_getErrorName(compressedSize));
        } else {
            // Save compressed file
            writeFile(files[i], dst, compressedSize);
            printf("Compressed %s: %zu -> %zu bytes\n",
                   files[i], srcSize, compressedSize);
        }

        free(src);
        free(dst);
    }

    // 4. Cleanup
    ZSTD_freeCDict(cdict);
    ZSTD_freeCCtx(cctx);
}
```

## Dictionary Compression with Streaming

```c
// Create streaming context
ZSTD_CStream* cstream = ZSTD_createCStream();

// Reference pre-digested dictionary
ZSTD_CCtx_refCDict(cstream, cdict);

// Initialize stream
ZSTD_initCStream(cstream, 0);  // Level from dictionary

// Normal streaming operations...
ZSTD_compressStream2(cstream, &output, &input, ZSTD_e_continue);
```

## Dictionary Distribution

**Important:** Both compression and decompression need the same dictionary.

**Distribution strategies:**
1. **Embedded:** Include dictionary in application binary
2. **Separate file:** Ship dictionary file with application
3. **Header:** Prepend dictionary to compressed data (wasteful for multiple files)
4. **Versioned:** Support multiple dictionary versions for backward compatibility

**Verification:**
```c
// Get dictionary ID from compressed frame
unsigned dictID = ZSTD_getDictID_fromFrame(compressedData, compressedSize);

// Check if matches expected dictionary
unsigned expectedID = ZSTD_getDictID_fromCDict(cdict);
if (dictID != expectedID) {
    fprintf(stderr, "Dictionary mismatch!\n");
}
```

## Performance Comparison

Example with 1000 small JSON files (5KB each):

| Method | Time | Ratio | Throughput |
|--------|------|-------|------------|
| No dictionary | 1.0s | 2.5x | 5 MB/s |
| Simple API | 8.2s | 3.8x | 0.6 MB/s |
| Digested dict | 1.2s | 3.8x | 4.2 MB/s |

**Takeaway:** Pre-digested dictionaries achieve same ratio with minimal overhead.

## Advanced: Reference Prefix

Alternative to dictionaries for streaming:

```c
// Use previous data as prefix (LDM mode)
ZSTD_CCtx_refPrefix(cctx, previousData, previousSize);
```

**Use case:**
- Compressing continuous stream
- Each chunk references previous chunk
- More flexible than fixed dictionary
- Compatible with long distance matching (LDM)

## Common Pitfalls

1. **Re-creating dictionary each operation** → Use `ZSTD_createCDict()`
2. **Dictionary too large** → Diminishing returns after 100KB
3. **Dictionary too small** → Won't capture enough patterns
4. **Untrained dictionary** → Use representative samples
5. **Missing dictionary on decompression** → Corruption errors
6. **Dictionary version mismatch** → Decompression failures

## Dictionary Storage Format

Save trained dictionaries to disk:

```c
// Save dictionary
FILE* f = fopen("dict.zstd", "wb");
fwrite(dictBuffer, 1, dictSize, f);
fclose(f);

// Load dictionary
FILE* f = fopen("dict.zstd", "rb");
fseek(f, 0, SEEK_END);
size_t dictSize = ftell(f);
fseek(f, 0, SEEK_SET);
void* dictBuffer = malloc(dictSize);
fread(dictBuffer, 1, dictSize, f);
fclose(f);

// Use loaded dictionary
ZSTD_CDict* cdict = ZSTD_createCDict(dictBuffer, dictSize, level);
```

## Benchmarking Dictionary Effectiveness

```c
// Compress with and without dictionary
size_t sizeWithDict = ZSTD_compress_usingCDict(...);
size_t sizeWithoutDict = ZSTD_compress(...);

double improvement = ((double)sizeWithoutDict / sizeWithDict - 1.0) * 100;
printf("Dictionary improved compression by %.1f%%\n", improvement);
```

**Expected improvements:**
- Small structured data: 30-50%
- Logs: 20-40%
- Large files: 5-10%
- Random data: 0-5%
