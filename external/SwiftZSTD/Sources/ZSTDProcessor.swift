//
//  ZSTDProcessor.swift
//
//  Created by Anatoli on 12/06/16.
//  Copyright © 2016 Anatoli Peredera. All rights reserved.
//

import Foundation

/**
 * Class that supports compression/decompression of an in-memory buffer without using
 * a dictionary.  A compression/decompression context can be used optionally to speed
 * up processing of multiple buffers.
 */
public class ZSTDProcessor
{
    let commonProcessor : ZSTDProcessorCommon
    var currentCL : Int32 = 0
    
    /**
     * Initializer.
     *
     * - paremeter useContext : true if use of context is desired
     */
    public init(useContext : Bool = false)
    {
        commonProcessor = ZSTDProcessorCommon(useContext: useContext)
    }
    
    /**
     * Compress a buffer. Input is sent to the C API without copying by using the 
     * Data.withUnsafeBytes() method.  The C API places the output straight into the newly-
     * created Data instance, which is possible because there are no other references
     * to the instance at this point, so calling withUnsafeMutableBytes() does not trigger
     * a copy-on-write.
     * 
     * - parameter dataIn : input Data
     * - parameter compressionLevel : must be 1-22, levels >= 20 to be used with caution
     * - returns: compressed frame
     */
    public func compressBuffer(_ dataIn : Data, compressionLevel : Int32) throws -> Data
    {
        guard isValidCompressionLevel(compressionLevel) else {
            throw ZSTDError.invalidCompressionLevel(cl: compressionLevel)
        }
        currentCL = compressionLevel

        return try commonProcessor.compressBufferCommon(dataIn, compressFrameHelper)
    }

    /**
     * A private helper passed to commonProcessor.compressBufferCommon().
     */
    private func compressFrameHelper(dst : UnsafeMutableRawPointer,
                               dstCapacity : Int,
                               src : UnsafeRawPointer,
                               srcSize : Int) -> Int {
        if commonProcessor.compCtx != nil {
            return ZSTD_compressCCtx(commonProcessor.compCtx, dst, dstCapacity, src, srcSize, currentCL);
        } else {
            return ZSTD_compress(dst, dstCapacity, src, srcSize, currentCL)
        }
    }
    
    /**
     * Decompress a frame that resulted from a previous compression of a buffer by a call
     * to compressBuffer().
     *
     * - parameter dataIn: frame to be decompressed
     * - returns: a Data instance wrapping the decompressed buffer
     */
    public func decompressFrame(_ dataIn : Data) throws -> Data
    {
        return try commonProcessor.decompressFrameCommon(dataIn, decompressFrameHelper)
    }
    
    /**
     * A private helper passed to commonProcessor.decompressFrameCommon().
     */
    private func decompressFrameHelper(dst : UnsafeMutableRawPointer,
                               dstCapacity : Int,
                               src : UnsafeRawPointer, srcSize : Int) -> Int {
        if commonProcessor.decompCtx != nil {
            return ZSTD_decompressDCtx(commonProcessor.decompCtx, dst, dstCapacity, src, srcSize);
        } else {
            return ZSTD_decompress(dst, dstCapacity, src, srcSize)
        }
    }
}
