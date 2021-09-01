# SwiftZSTD
Swift Wrapper around ZSTD Compression Library

Compression and de-compression of in-memory buffers is supported, with or without a context or a dictionary.  Buffers are represented by Data instances.  To be decompressed by this code, a buffer must be a complete frame with decompressed size encoded in it and retrievable using ZSTD_getDecompressedSize().  

This is actually a fairly useful implementation.  Experimentation shows that even fairly large files (100s of MB),when compressed using the zstd utility provided with the C library, end up in a single frame, which is easily decompressible by this Swift code if read into memory as one piece!

Streaming compression and decompression is also supported, but not with a dictionary, as streaming operations that use a dictionary are experimental in the underlying C library.

The relevant ZSTD C code has been added to the repository since it is compiled as part of the Xcode project.  See https://github.com/facebook/zstd for additional information, including licensing.

The wrapper is packaged as a framework and includes the ZSTD C code as part of the target.  Other approaches could have been used, e.g. the ZSTD lib could have been packaged as an external library, static or dynamic.  

