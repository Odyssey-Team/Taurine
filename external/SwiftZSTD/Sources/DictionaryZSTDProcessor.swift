//
//  DictionaryZSTDProcessor.swift
//
//  Created by Anatoli on 12/6/16.
//  Copyright © 2016 Anatoli Peredera. All rights reserved.
//

import Foundation

/**
 * A class to compress a buffer into a frame or to decompress a frame using a 
 * dictionary previously built from a set of samples.
 */
public class DictionaryZSTDProcessor
{
    let commonProcessor : ZSTDProcessorCommon
    
    let dict : Data
    let compLevel : Int32
    
    // We need these boolean properties to check if a dictionary exists when
    // deinitializing.  Otherwise, checking for a computed property like decompDict
    // will actually cause a dictionary digest to be created, an expensive operation.
    var haveCDict = false
    var haveDDict = false
    
    var compDict : OpaquePointer? {
        struct Junk { static var retVal : OpaquePointer? = nil }
        if Junk.retVal == nil {
            Junk.retVal = dict.withUnsafeBytes({ (p: UnsafeRawBufferPointer) -> OpaquePointer? in
                haveCDict = true
                return ZSTD_createCDict(p.baseAddress, dict.count, compLevel)
            })
            
        }
        return Junk.retVal
    }

    var decompDict : OpaquePointer? {
        struct Junk { static var retVal : OpaquePointer? = nil }
        if Junk.retVal == nil {
            Junk.retVal = dict.withUnsafeBytes { (p : UnsafeRawBufferPointer) -> OpaquePointer? in
                haveDDict = true
                return ZSTD_createDDict(p.baseAddress, dict.count)
            }
        }
        return Junk.retVal
    }

    /**
     * Initialize using a dictionary and compression level.
     *
     * Compression level must be 1-22, levels >= 20 to be used with caution.
     *
     * - parameter  withDictionary: a Data instance containing the dictionary
     * - parameter  andCompressionLevel:  compression level
     */
    public init?(withDictionary: Data, andCompressionLevel: Int32)
    {
        guard isValidCompressionLevel(andCompressionLevel) else {
            return nil
        }
        
        commonProcessor = ZSTDProcessorCommon(useContext: true)
        dict = withDictionary
        compLevel = andCompressionLevel
    }
    
    deinit {
        if (haveCDict) { ZSTD_freeCDict(compDict) }
        if (haveDDict) { ZSTD_freeDDict(decompDict) }
    }
        
    /**
     * Compress a buffer using the dictionary and compression level specified at 
     * initialization time.
     * 
     * - parameter dataIn : input Data
     * - returns: compressed frame
     */
    public func compressBufferUsingDict(_ dataIn : Data) throws -> Data
    {
        return try commonProcessor.compressBufferCommon(dataIn, compressFrameHelper)
    }

    /**
     * A private helper passed to commonProcessor.compressBufferCommon().
     *
     * No checking is performed on compDict.  If it is nil or was not produced by
     * the ZSTD library, the call is going to crash.  However, even if an arbitrary
     * dictionary buffer was provided to the library, the resulting dictionary digest will
     * work, but with questionable performance.
     */
    private func compressFrameHelper(dst : UnsafeMutableRawPointer,
                               dstCapacity : Int,
                               src : UnsafeRawPointer,
                               srcSize : Int) -> Int {
        return ZSTD_compress_usingCDict(commonProcessor.compCtx, dst, dstCapacity, src, srcSize, compDict)
    }
    
    /**
     * Decompress a frame that resulted from a previous compression of a buffer by ZSTD
     * using the dictionary associated with this instance.
     *
     * - parameter dataIn: frame to be decompressed
     * - returns: a Data instance wrapping the decompressed buffer
     */
    public func decompressFrameUsingDict(_ dataIn : Data) throws -> Data
    {
        return try commonProcessor.decompressFrameCommon(dataIn, decompressFrameHelper)
    }

    /**
     * A private helper passed to commonProcessor.decompressFrameCommon().
     *
     * No checking is performed on decompDict.  If it is nil or was not produced by
     * the ZSTD library, the call is going to crash.  However, even if an arbitrary
     * dictionary buffer was provided to the library, the resulting dictionary digest will 
     * work, but with questionable performance.
     */
    private func decompressFrameHelper(dst : UnsafeMutableRawPointer,
                               dstCapacity : Int,
                               src : UnsafeRawPointer, srcSize : Int) -> Int {
        return ZSTD_decompress_usingDDict(commonProcessor.decompCtx, dst, dstCapacity, src, srcSize, decompDict)
    }
}
