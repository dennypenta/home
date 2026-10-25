# Zstd Streaming API Guide

## Overview

Use streaming API when:
- Source data doesn't fit in memory
- Decompressed size is unknown upfront
- Processing data incrementally (network streams, file chunks)
- Need fine-grained control over memory usage

## Compression Streaming

### Basic Streaming Compression

```c
// 1. Create stream context
ZSTD_CStream* cstream = ZSTD_createCStream();

// 2. Initialize with compression level
ZSTD_initCStream(cstream, compressionLevel);

// 3. Get recommended buffer sizes
size_t inBufSize = ZSTD_CStreamInSize();    // Recommended input buffer
size_t outBufSize = ZSTD_CStreamOutSize();  // Recommended output buffer

// 4. Allocate buffers
void* inBuf = malloc(inBufSize);
void* outBuf = malloc(outBufSize);

// 5. Compression loop
while (reading input) {
    // Read input chunk
    size_t toRead = fread(inBuf, 1, inBufSize, inputFile);

    ZSTD_inBuffer input = { inBuf, toRead, 0 };

    while (input.pos < input.size) {
        ZSTD_outBuffer output = { outBuf, outBufSize, 0 };

        // Compress chunk
        size_t remaining = ZSTD_compressStream2(cstream, &output, &input, ZSTD_e_continue);

        if (ZSTD_isError(remaining)) {
            // Handle error
        }

        // Write compressed output
        fwrite(outBuf, 1, output.pos, outputFile);
    }
}

// 6. Finalize stream
ZSTD_outBuffer output = { outBuf, outBufSize, 0 };
size_t remaining = ZSTD_compressStream2(cstream, &output, NULL, ZSTD_e_end);

while (remaining > 0) {
    fwrite(outBuf, 1, output.pos, outputFile);
    output.pos = 0;
    remaining = ZSTD_compressStream2(cstream, &output, NULL, ZSTD_e_end);
}

fwrite(outBuf, 1, output.pos, outputFile);

// 7. Cleanup
ZSTD_freeCStream(cstream);
free(inBuf);
free(outBuf);
```

### Streaming Compression Directives

`ZSTD_compressStream2()` uses directives to control behavior:

- **`ZSTD_e_continue`**: Normal compression, buffer more input
- **`ZSTD_e_flush`**: Flush internal buffers, make data available for decompression
- **`ZSTD_e_end`**: Finalize frame, close compression

**Flush semantics:**
- `ZSTD_e_flush`: Guarantees all input consumed and output flushed
- Use when need partial decompression before stream ends
- Creates valid frame boundaries for streaming decompression

## Decompression Streaming

### Basic Streaming Decompression

```c
// 1. Create decompression stream
ZSTD_DStream* dstream = ZSTD_createDStream();

// 2. Initialize
ZSTD_initDStream(dstream);

// 3. Get recommended buffer sizes
size_t inBufSize = ZSTD_DStreamInSize();
size_t outBufSize = ZSTD_DStreamOutSize();

// 4. Allocate buffers
void* inBuf = malloc(inBufSize);
void* outBuf = malloc(outBufSize);

// 5. Decompression loop
while (reading compressed input) {
    size_t toRead = fread(inBuf, 1, inBufSize, inputFile);

    ZSTD_inBuffer input = { inBuf, toRead, 0 };

    while (input.pos < input.size) {
        ZSTD_outBuffer output = { outBuf, outBufSize, 0 };

        // Decompress chunk
        size_t ret = ZSTD_decompressStream(dstream, &output, &input);

        if (ZSTD_isError(ret)) {
            fprintf(stderr, "Decompression error: %s\n", ZSTD_getErrorName(ret));
            // Handle error
            break;
        }

        // Write decompressed output
        fwrite(outBuf, 1, output.pos, outputFile);

        // ret == 0 means frame is complete
        if (ret == 0) {
            // Frame complete, can reset for next frame
            ZSTD_initDStream(dstream);
        }
    }
}

// 6. Cleanup
ZSTD_freeDStream(dstream);
free(inBuf);
free(outBuf);
```

### Return Value Semantics

`ZSTD_decompressStream()` returns:
- **0**: Frame complete, ready for next frame
- **> 0**: Minimum input bytes needed for progress (hint for buffering)
- **Error code**: Check with `ZSTD_isError()`

## Advanced Patterns

### Reusable Streaming Contexts

```c
ZSTD_CStream* cstream = ZSTD_createCStream();

// Compress multiple independent streams
for (each file) {
    ZSTD_initCStream(cstream, level);

    // Compression loop...

    // Context automatically ready for next file
}

ZSTD_freeCStream(cstream);
```

### Context Reset

```c
// Reset to clear state
ZSTD_CCtx_reset(cstream, ZSTD_reset_session_only);      // Keep parameters
ZSTD_CCtx_reset(cstream, ZSTD_reset_session_and_parameters);  // Full reset
```

### Streaming with Parameters

```c
ZSTD_CStream* cstream = ZSTD_createCStream();

// Set parameters before initialization
ZSTD_CCtx_setParameter(cstream, ZSTD_c_compressionLevel, 5);
ZSTD_CCtx_setParameter(cstream, ZSTD_c_windowLog, 23);
ZSTD_CCtx_setParameter(cstream, ZSTD_c_checksumFlag, 1);

// Then initialize
ZSTD_initCStream(cstream, 0);  // Level ignored when using setParameter
```

### Streaming with Dictionaries

```c
// Pre-create dictionary
ZSTD_CDict* cdict = ZSTD_createCDict(dictBuffer, dictSize, compressionLevel);

// Reference in streaming context
ZSTD_CCtx_refCDict(cstream, cdict);

// Normal streaming operations...

ZSTD_freeCDict(cdict);
```

## Buffer Management

### Recommended Sizes

```c
// Input buffer size (optimal for streaming)
size_t inSize = ZSTD_CStreamInSize();   // Typically 128KB

// Output buffer size (guaranteed to hold any compressed block)
size_t outSize = ZSTD_CStreamOutSize(); // Typically 128KB
```

**Benefits of using recommended sizes:**
- Optimal performance
- Guaranteed progress (no stalls)
- Minimal memory waste

### Custom Buffer Sizes

Can use any buffer sizes, but:
- Too small: Performance degradation, more function calls
- Too large: Memory waste
- Recommended sizes are empirically optimized

## Error Handling in Streaming

```c
size_t result = ZSTD_compressStream2(cstream, &output, &input, ZSTD_e_continue);

if (ZSTD_isError(result)) {
    const char* errMsg = ZSTD_getErrorName(result);
    ZSTD_ErrorCode errCode = ZSTD_getErrorCode(result);

    // Context is in undefined state
    // Must reset before reuse
    ZSTD_CCtx_reset(cstream, ZSTD_reset_session_and_parameters);

    // Handle error
}
```

## Performance Considerations

**Streaming vs Simple API:**
- Simple API: Faster for small data (< 1MB)
- Streaming API: Better for large data, constant memory

**Optimization tips:**
- Reuse stream contexts across operations
- Use recommended buffer sizes
- Minimize `ZSTD_e_flush` usage (impacts compression ratio)
- Pre-allocate buffers outside loops

## Common Patterns

### Network Streaming

```c
// Compress data for network transmission
ZSTD_CStream* cstream = ZSTD_createCStream();
ZSTD_initCStream(cstream, 3);

while (reading from network) {
    ZSTD_inBuffer input = { networkBuffer, bytesReceived, 0 };

    while (input.pos < input.size) {
        ZSTD_outBuffer output = { outputBuffer, outputSize, 0 };
        ZSTD_compressStream2(cstream, &output, &input, ZSTD_e_continue);

        // Send compressed data
        send(socket, outputBuffer, output.pos, 0);
    }
}

// Flush on connection close
ZSTD_outBuffer output = { outputBuffer, outputSize, 0 };
ZSTD_compressStream2(cstream, &output, NULL, ZSTD_e_end);
send(socket, outputBuffer, output.pos, 0);
```

### File Processing

```c
// Process large file in chunks
FILE* fin = fopen("large.bin", "rb");
FILE* fout = fopen("large.zst", "wb");

ZSTD_CStream* cstream = ZSTD_createCStream();
ZSTD_initCStream(cstream, 5);

size_t const buffInSize = ZSTD_CStreamInSize();
size_t const buffOutSize = ZSTD_CStreamOutSize();
void* buffIn = malloc(buffInSize);
void* buffOut = malloc(buffOutSize);

size_t read;
while ((read = fread(buffIn, 1, buffInSize, fin))) {
    ZSTD_inBuffer input = { buffIn, read, 0 };

    while (input.pos < input.size) {
        ZSTD_outBuffer output = { buffOut, buffOutSize, 0 };
        ZSTD_compressStream2(cstream, &output, &input, ZSTD_e_continue);
        fwrite(buffOut, 1, output.pos, fout);
    }
}

// Finalize
ZSTD_outBuffer output = { buffOut, buffOutSize, 0 };
size_t remaining = ZSTD_compressStream2(cstream, &output, NULL, ZSTD_e_end);
while (remaining) {
    fwrite(buffOut, 1, output.pos, fout);
    output.pos = 0;
    remaining = ZSTD_compressStream2(cstream, &output, NULL, ZSTD_e_end);
}
fwrite(buffOut, 1, output.pos, fout);

// Cleanup
free(buffIn);
free(buffOut);
ZSTD_freeCStream(cstream);
fclose(fin);
fclose(fout);
```
