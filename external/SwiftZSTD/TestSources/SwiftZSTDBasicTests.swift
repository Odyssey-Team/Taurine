//
//  SwiftZSTDBasicTests.swift
//
//  Created by Anatoli on 1/14/20.
//

import XCTest
@testable import SwiftZSTD

class SwiftZSTDBasicTests: XCTestCase {

    func testWithDictionary() {
        checkPlatform()
        
        if let dictData = getDictionary() {
            let origData = Data(bytes: [123, 231, 132, 100, 20, 10, 5, 2, 1])
            if let compData = compressWithDictionary(origData, dictData) {
                if let decompData = decompressWithDictionary(compData, dictData) {
                    XCTAssertEqual(decompData, origData,
                              "Decompressed data is different from original (using dictionary)")
                }
            }
        }
    }
    
    func testWithoutDictionary() {
        checkPlatform()
        
        let processor = ZSTDProcessor(useContext: true)
        
        let origData = Data(bytes: [3, 4, 12, 244, 32, 7, 10, 12, 13, 111, 222, 133])
        
        do {
            let compressedData = try processor.compressBuffer(origData, compressionLevel: 4)
            let decompressedData = try processor.decompressFrame(compressedData)
            XCTAssertEqual(decompressedData, origData,
                           "Decompressed data is different from original (not using dictionary")
        } catch ZSTDError.libraryError(let errStr) {
            XCTFail("Library error: \(errStr)")
        } catch ZSTDError.invalidCompressionLevel(let lvl){
            XCTFail("Invalid compression level: \(lvl)")
        } catch ZSTDError.decompressedSizeUnknown {
            XCTFail("Unknown decompressed size.")
        } catch  {
            XCTFail("Unknown error")
        }
    }
    
    private func checkPlatform() {
        #if os(OSX)
        print("TESTING ON macOS!")
        #elseif os(iOS)
        print("TESTING ON iOS!")
        #else
        XCTFail("BAD PLATFORM")
        #endif
    }
    
    private func getDictionary() -> Data? {
        var samples = [Data]()
        samples.append(Data(bytes: Array(10...250)))
        samples.append(Data(bytes: Array(repeating: 123, count: 100_000)))
        samples.append(Data(bytes: [1,3,4,7,11]))
        samples.append(Data(bytes: [0,0,1,1,5,5]))
        samples.append(Data(bytes: Array(100...240)))
        samples.append(Data(bytes: Array(repeating: 230, count: 100_000)))
        samples.append(Data(bytes: [10,30,40,70,110]))
        samples.append(Data(bytes: [10,20,10,1,15,50]))
        
        do {
            return try buildDictionary(fromSamples: samples)
        } catch ZDICTError.libraryError(let errStr) {
            XCTFail("Library error while creating dictionary: \(errStr)")
        } catch ZDICTError.unknownError {
            XCTFail("Unknown library error while creating dictionary.")
        } catch {
            XCTFail("Unknown error while creating dictionary.")
        }
        
        return nil
    }
    
    private func compressWithDictionary(_ dataIn: Data, _ dict: Data) -> Data? {
        // Note that we only check for the exceptions that can reasonably be
        // expected when compressing, excluding things like unknown decompressed size.
        if let dictProc = DictionaryZSTDProcessor(withDictionary: dict, andCompressionLevel: 4) {
            do {
                return try dictProc.compressBufferUsingDict(dataIn)
            } catch ZSTDError.libraryError(let errStr) {
                XCTFail("Library error while compressing data: \(errStr)")
            } catch ZSTDError.invalidCompressionLevel(let lvl){
                XCTFail("Invalid compression level: \(lvl)")
            } catch {
                XCTFail("Unknown error while compressing data.")
            }
            return nil
        } else {
            XCTFail("Could not create dictionary-based compressor.")
            return nil
        }
    }
    
    private func decompressWithDictionary(_ dataIn: Data, _ dict: Data) -> Data? {
        // We could have re-used the same DictionaryZSTDProcessor instance that was used
        // to compress the data.  Again, note that we only check for the exceptions that
        // can reasonably be expected when decompressing, excluding things like invalid
        // compression level.
        if let dictProc = DictionaryZSTDProcessor(withDictionary: dict, andCompressionLevel: 20) {
            do {
                return try dictProc.decompressFrameUsingDict(dataIn)
            } catch ZSTDError.libraryError(let errStr) {
                XCTFail("Library error while decompressing data: \(errStr)")
            } catch ZSTDError.decompressedSizeUnknown {
                XCTFail("Unknown decompressed size.")
            } catch {
                XCTFail("Unknown error while decompressing data.")
            }
            return nil
        } else {
            XCTFail("Could not create dictionary-based decompressor.")
            return nil
        }
    }
}
