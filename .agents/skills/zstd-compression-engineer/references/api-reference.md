# Zstd Complete API Reference

## Core Compression Functions

### Simple API

```c
size_t ZSTD_compress(void* dst, size_t dstCapacity,
                     const void* src, size_t srcSize,
                     int compressionLevel);
```
Single-pass compression. Returns compressed size or error code.

**Parameters:**
- `compressionLevel`: 1-22, or `ZSTD_CLEVEL_DEFAULT` (3)
- Use `ZSTD_compressBound(srcSize)` to calculate required `dstCapacity`

```c
size_t ZSTD_decompress(void* dst, size_t dstCapacity,
                       const void* src, size_t compressedSize);
```
Single-pass decompression. Returns decompressed size or error code.

### Context-Based API

```c
ZSTD_CCtx* ZSTD_createCCtx(void);
void ZSTD_freeCCtx(ZSTD_CCtx* cctx);

size_t ZSTD_compressCCtx(ZSTD_CCtx* cctx,
                         void* dst, size_t dstCapacity,
                         const void* src, size_t srcSize,
                         int compressionLevel);
```
Reusable compression context for multiple operations.

```c
ZSTD_DCtx* ZSTD_createDCtx(void);
void ZSTD_freeDCtx(ZSTD_DCtx* dctx);

size_t ZSTD_decompressDCtx(ZSTD_DCtx* dctx,
                           void* dst, size_t dstCapacity,
                           const void* src, size_t compressedSize);
```
Reusable decompression context.

### Advanced API

```c
size_t ZSTD_compress2(ZSTD_CCtx* cctx,
                      void* dst, size_t dstCapacity,
                      const void* src, size_t srcSize);
```
Advanced compression with parameter control via `ZSTD_CCtx_setParameter()`.

## Streaming API

### Compression Streaming

```c
ZSTD_CStream* ZSTD_createCStream(void);
void ZSTD_freeCStream(ZSTD_CStream* zcs);

size_t ZSTD_initCStream(ZSTD_CStream* zcs, int compressionLevel);

size_t ZSTD_compressStream2(ZSTD_CStream* zcs,
                            ZSTD_outBuffer* output,
                            ZSTD_inBuffer* input,
                            ZSTD_EndDirective endOp);
```

**ZSTD_EndDirective values:**
- `ZSTD_e_continue`: Normal compression
- `ZSTD_e_flush`: Flush internal buffers
- `ZSTD_e_end`: Close frame

**Buffer structures:**
```c
typedef struct {
    void* dst;      // Destination buffer
    size_t size;    // Buffer capacity
    size_t pos;     // Current write position
} ZSTD_outBuffer;

typedef struct {
    const void* src;  // Source buffer
    size_t size;      // Data size
    size_t pos;       // Current read position
} ZSTD_inBuffer;
```

### Decompression Streaming

```c
ZSTD_DStream* ZSTD_createDStream(void);
void ZSTD_freeDStream(ZSTD_DStream* zds);

size_t ZSTD_initDStream(ZSTD_DStream* zds);

size_t ZSTD_decompressStream(ZSTD_DStream* zds,
                             ZSTD_outBuffer* output,
                             ZSTD_inBuffer* input);
```

**Return values:**
- `0`: Frame complete
- `> 0`: Hint for next input size
- Error code if `ZSTD_isError()` returns true

### Buffer Size Helpers

```c
size_t ZSTD_CStreamInSize(void);   // Recommended input buffer size (128KB)
size_t ZSTD_CStreamOutSize(void);  // Recommended output buffer size (128KB)
size_t ZSTD_DStreamInSize(void);   // Recommended decompression input (128KB)
size_t ZSTD_DStreamOutSize(void);  // Recommended decompression output (128KB)
```

## Dictionary API

### Simple Dictionary API

```c
size_t ZSTD_compress_usingDict(ZSTD_CCtx* cctx,
                               void* dst, size_t dstCapacity,
                               const void* src, size_t srcSize,
                               const void* dict, size_t dictSize,
                               int compressionLevel);

size_t ZSTD_decompress_usingDict(ZSTD_DCtx* dctx,
                                 void* dst, size_t dstCapacity,
                                 const void* src, size_t compressedSize,
                                 const void* dict, size_t dictSize);
```

### Pre-Digested Dictionary API

```c
ZSTD_CDict* ZSTD_createCDict(const void* dict, size_t dictSize,
                             int compressionLevel);
void ZSTD_freeCDict(ZSTD_CDict* cdict);

size_t ZSTD_compress_usingCDict(ZSTD_CCtx* cctx,
                                void* dst, size_t dstCapacity,
                                const void* src, size_t srcSize,
                                const ZSTD_CDict* cdict);

ZSTD_DDict* ZSTD_createDDict(const void* dict, size_t dictSize);
void ZSTD_freeDDict(ZSTD_DDict* ddict);

size_t ZSTD_decompress_usingDDict(ZSTD_DCtx* dctx,
                                  void* dst, size_t dstCapacity,
                                  const void* src, size_t compressedSize,
                                  const ZSTD_DDict* ddict);
```

### Context Dictionary Loading

```c
size_t ZSTD_CCtx_loadDictionary(ZSTD_CCtx* cctx,
                                const void* dict, size_t dictSize);

size_t ZSTD_CCtx_refCDict(ZSTD_CCtx* cctx, const ZSTD_CDict* cdict);

size_t ZSTD_CCtx_refPrefix(ZSTD_CCtx* cctx,
                           const void* prefix, size_t prefixSize);
```

Corresponding decompression functions:
```c
size_t ZSTD_DCtx_loadDictionary(ZSTD_DCtx* dctx,
                                const void* dict, size_t dictSize);

size_t ZSTD_DCtx_refDDict(ZSTD_DCtx* dctx, const ZSTD_DDict* ddict);

size_t ZSTD_DCtx_refPrefix(ZSTD_DCtx* dctx,
                           const void* prefix, size_t prefixSize);
```

## Parameter Control

### Compression Parameters

```c
typedef enum {
    ZSTD_c_compressionLevel,    // 1-22, default 3
    ZSTD_c_windowLog,           // 10-31, memory usage scaling
    ZSTD_c_hashLog,             // 6-26, hash table size
    ZSTD_c_chainLog,            // 6-28, match chain length
    ZSTD_c_searchLog,           // 1-26, search depth
    ZSTD_c_minMatch,            // 3-7, minimum match length
    ZSTD_c_targetLength,        // 0-999, match finding limit
    ZSTD_c_strategy,            // ZSTD_strategy enum
    ZSTD_c_checksumFlag,        // 0-1, add checksum
    ZSTD_c_nbWorkers,           // Multi-threading
    ZSTD_c_jobSize,             // Job size for threading
    // ... many more parameters
} ZSTD_cParameter;

size_t ZSTD_CCtx_setParameter(ZSTD_CCtx* cctx,
                              ZSTD_cParameter param,
                              int value);
```

### Strategy Selection

```c
typedef enum {
    ZSTD_fast = 1,
    ZSTD_dfast = 2,
    ZSTD_greedy = 3,
    ZSTD_lazy = 4,
    ZSTD_lazy2 = 5,
    ZSTD_btlazy2 = 6,
    ZSTD_btopt = 7,
    ZSTD_btultra = 8,
    ZSTD_btultra2 = 9
} ZSTD_strategy;
```

**Strategy guide:**
- `fast/dfast`: Maximum speed, lower ratio
- `greedy/lazy`: Balanced
- `btopt/btultra`: Maximum compression, slower

### Decompression Parameters

```c
typedef enum {
    ZSTD_d_windowLogMax,        // Memory limit
    ZSTD_d_stableOutBuffer,     // Output buffer reuse hint
    // ... more parameters
} ZSTD_dParameter;

size_t ZSTD_DCtx_setParameter(ZSTD_DCtx* dctx,
                              ZSTD_dParameter param,
                              int value);
```

## Frame Inspection

### Frame Header Info

```c
unsigned long long ZSTD_getFrameContentSize(const void* src, size_t srcSize);
```
Returns:
- Decompressed size if available
- `ZSTD_CONTENTSIZE_UNKNOWN` if size not in frame header
- `ZSTD_CONTENTSIZE_ERROR` if invalid frame

```c
size_t ZSTD_findFrameCompressedSize(const void* src, size_t srcSize);
```
Returns size of first complete frame in buffer.

```c
unsigned ZSTD_getDictID_fromFrame(const void* src, size_t srcSize);
```
Returns dictionary ID required for decompression (0 if none).

```c
unsigned ZSTD_getDictID_fromCDict(const ZSTD_CDict* cdict);
unsigned ZSTD_getDictID_fromDDict(const ZSTD_DDict* ddict);
```

## Error Handling

```c
unsigned ZSTD_isError(size_t code);
```
Returns non-zero if `code` represents an error.

```c
const char* ZSTD_getErrorName(size_t code);
```
Returns human-readable error description.

```c
ZSTD_ErrorCode ZSTD_getErrorCode(size_t code);
```
Converts size_t error to enum for comparison.

```c
typedef enum {
    ZSTD_error_no_error,
    ZSTD_error_GENERIC,
    ZSTD_error_prefix_unknown,
    ZSTD_error_version_unsupported,
    ZSTD_error_frameParameter_unsupported,
    ZSTD_error_frameParameter_windowTooLarge,
    ZSTD_error_corruption_detected,
    ZSTD_error_checksum_wrong,
    ZSTD_error_dictionary_corrupted,
    ZSTD_error_dictionary_wrong,
    ZSTD_error_dictionaryCreation_failed,
    ZSTD_error_parameter_unsupported,
    ZSTD_error_parameter_outOfBound,
    ZSTD_error_tableLog_tooLarge,
    ZSTD_error_maxSymbolValue_tooLarge,
    ZSTD_error_maxSymbolValue_tooSmall,
    ZSTD_error_stage_wrong,
    ZSTD_error_init_missing,
    ZSTD_error_memory_allocation,
    ZSTD_error_workSpace_tooSmall,
    ZSTD_error_dstSize_tooSmall,
    ZSTD_error_srcSize_wrong,
    ZSTD_error_dstBuffer_null,
    // ... more error codes
} ZSTD_ErrorCode;
```

## Context Management

### Context Reset

```c
typedef enum {
    ZSTD_reset_session_only,              // Keep parameters
    ZSTD_reset_parameters,                // Reset parameters only
    ZSTD_reset_session_and_parameters     // Full reset
} ZSTD_ResetDirective;

size_t ZSTD_CCtx_reset(ZSTD_CCtx* cctx, ZSTD_ResetDirective reset);
size_t ZSTD_DCtx_reset(ZSTD_DCtx* dctx, ZSTD_ResetDirective reset);
```

### Thread Pool Management

```c
ZSTD_threadPool* ZSTD_createThreadPool(size_t numThreads);
void ZSTD_freeThreadPool(ZSTD_threadPool* pool);

size_t ZSTD_CCtx_refThreadPool(ZSTD_CCtx* cctx, ZSTD_threadPool* pool);
```

## Utility Functions

### Bounds Calculation

```c
size_t ZSTD_compressBound(size_t srcSize);
```
Maximum compressed size guarantee for given input size.

### Version Info

```c
unsigned ZSTD_versionNumber(void);
const char* ZSTD_versionString(void);
```

### Compression Level Bounds

```c
int ZSTD_minCLevel(void);  // Minimum level (typically negative)
int ZSTD_maxCLevel(void);  // Maximum level (typically 22)
int ZSTD_defaultCLevel(void);  // Default level (3)
```

## Dictionary Training

```c
#include <zdict.h>

size_t ZDICT_trainFromBuffer(void* dictBuffer, size_t dictBufferCapacity,
                             const void* samplesBuffer,
                             const size_t* samplesSizes,
                             unsigned nbSamples);
```

Train dictionary from sample data.

```c
unsigned ZDICT_isError(size_t errorCode);
const char* ZDICT_getErrorName(size_t errorCode);
```

## Memory Management

### Custom Allocator

```c
typedef struct {
    void* (*malloc)(void* opaque, size_t size);
    void (*free)(void* opaque, void* address);
    void* opaque;
} ZSTD_customMem;

ZSTD_CCtx* ZSTD_createCCtx_advanced(ZSTD_customMem customMem);
ZSTD_DCtx* ZSTD_createDCtx_advanced(ZSTD_customMem customMem);
```

### Memory Usage Estimation

```c
size_t ZSTD_estimateCCtxSize(int compressionLevel);
size_t ZSTD_estimateDCtxSize(void);
size_t ZSTD_estimateCStreamSize(int compressionLevel);
size_t ZSTD_estimateDStreamSize(size_t windowSize);
```

## Advanced Features

### Sequence Producer API

For custom match-finding algorithms (advanced users only).

### Block-Level API

Direct access to zstd blocks for specialized use cases.

### Prefix Compression

```c
size_t ZSTD_CCtx_refPrefix_advanced(ZSTD_CCtx* cctx,
                                    const void* prefix, size_t prefixSize,
                                    ZSTD_dictContentType_e dictContentType);
```

### Long Distance Matching

```c
ZSTD_CCtx_setParameter(cctx, ZSTD_c_enableLongDistanceMatching, 1);
ZSTD_CCtx_setParameter(cctx, ZSTD_c_ldmHashLog, 20);
ZSTD_CCtx_setParameter(cctx, ZSTD_c_ldmMinMatch, 64);
```

Useful for data with distant repetitions (large window size).

## Official Documentation

Complete API manual: https://facebook.github.io/zstd/doc/api_manual_latest.html
