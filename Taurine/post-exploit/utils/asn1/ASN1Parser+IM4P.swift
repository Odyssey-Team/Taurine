//
//  ASN1Parser+IM4P.swift
//  Taurine15
//
//  Created by CoolStar on 3/24/22.
//

import Foundation
import Accelerate
import Compression

extension Asn1Parser {
    public func isIM4P() -> Bool {
        isIM4P(entry: rootEntry)
    }
    
    public func isIM4P(entry: Asn1Entry) -> Bool {
        guard entry.tag.constructed,
              entry.tag.tagNumber == .sequence,
              entry.tag.tagClass == .universal,
              let subEntries = parseSequence(entry: entry),
              subEntries.count >= 4,
              self.parseString(entry: subEntries[0]) == "IM4P",
              self.parseString(entry: subEntries[1])?.count == 4,
              self.parseString(entry: subEntries[2]) != nil else {
                  return false
              }
        let payload = subEntries[3]
        guard !payload.tag.constructed,
              payload.tag.tagNumber == .octet,
              payload.tag.tagClass == .universal else {
                  return false
              }
        return true
    }
    
    private func decompressLZSS(payloadData: DataDesc, outputPath: String) -> Bool {
        try? FileManager.default.removeItem(atPath: outputPath)
        FileManager.default.createFile(atPath: outputPath, contents: nil, attributes: nil)
        guard let destination = FileHandle(forWritingAtPath: outputPath) else {
            return false
        }
        
        var currentOffset = payloadData.offset
        currentOffset += 12 //signature, compressType, adler32
        
        guard let uncompressedSizeRaw = self.readData(startOffset: currentOffset, sectionLength: 4) else {
            return false
        }
        
        currentOffset += 4 //uncompressedSize
        
        guard let compressedSizeRaw = self.readData(startOffset: currentOffset, sectionLength: 4) else {
            return false
        }
        currentOffset += 4 //compressedSize
        currentOffset += 4 //prelinkVersion
        currentOffset += 360 //padding
        
        let startOffset = currentOffset
        
        let uncompressedSize = UInt32(bigEndian: uncompressedSizeRaw.withUnsafeBytes { $0.load(as: UInt32.self) })
        let compressedSize = UInt64(UInt32(bigEndian: compressedSizeRaw.withUnsafeBytes { $0.load(as: UInt32.self) }))
        
        guard compressedSize < payloadData.len - (currentOffset - payloadData.offset) else {
            return false
        }
        
        var lzssDecoder = LZSSDecoder()
        
        let bufferCapacity = UInt64(0x4000)
        
        var compressedLen = UInt64(0)
        var bytesWritten = UInt64(0)
        while compressedLen < compressedSize {
            var sublen = bufferCapacity
            if currentOffset + sublen > startOffset + compressedSize {
                sublen = startOffset + compressedSize - currentOffset
            }
            defer {
                compressedLen += sublen
                currentOffset += sublen
            }
            guard let subdata = self.readData(startOffset: currentOffset, sectionLength: sublen) else {
                return false
            }
            if subdata.count == 0 {
                break
            }
            
            let subbytes = [UInt8](subdata)
            let uncompressedPartial = Data(lzssDecoder.decodePartial(subbytes))
            destination.write(uncompressedPartial)
            bytesWritten += UInt64(uncompressedPartial.count)
        }
        let finalData = Data(lzssDecoder.finalize())
        destination.write(finalData)
        bytesWritten += UInt64(finalData.count)
        
        destination.closeFile()
        
        return bytesWritten == uncompressedSize
    }
    
    private func decompressBVX2(payloadData: DataDesc, expectedLen: UInt64, outputPath: String) -> Bool {
        try? FileManager.default.removeItem(atPath: outputPath)
        FileManager.default.createFile(atPath: outputPath, contents: nil, attributes: nil)
        guard let destination = FileHandle(forWritingAtPath: outputPath) else {
            return false
        }
        
        var bytesWritten = 0
        
        let bufferCapacity = UInt64(0x4000)
        let outputFilter = try? OutputFilter(
            .decompress,
            using: .lzfse,
            bufferCapacity: Int(bufferCapacity),
            writingTo: { data in
                if let data = data {
                    destination.write(data)
                    bytesWritten += data.count
                }
            })
        var currentOffset = payloadData.offset
        var uncompressedLen = UInt64(0)
        while uncompressedLen < payloadData.len {
            var sublen = bufferCapacity
            if currentOffset + sublen > payloadData.offset + payloadData.len {
                sublen = payloadData.offset + payloadData.len - currentOffset
            }
            defer {
                uncompressedLen += sublen
                currentOffset += sublen
            }
            guard let subdata = self.readData(startOffset: currentOffset, sectionLength: sublen) else {
                return false
            }
            if subdata.count == 0 {
                break
            }
            
            do {
                try outputFilter?.write(subdata)
            } catch {
                break
            }
        }
        
        try? outputFilter?.finalize()
        destination.closeFile()
        return bytesWritten == expectedLen
    }
    
    public func parseIM4P(outputPath: String) -> Bool {
        parseIM4P(entry: rootEntry, outputPath: outputPath)
    }
    
    public func parseIM4P(entry: Asn1Entry, outputPath: String) -> Bool {
        guard isIM4P() else {
            return false
        }
        guard let subEntries = parseSequence(entry: entry),
              subEntries.count >= 4 else {
                  return false
              }
        let payload = subEntries[3]
        guard payload.data.len >= 9 else {
            return false
        }
        guard let lzssHdr = "complzss".data(using: .utf8),
              let bvx2Hdr = "bvx2".data(using: .utf8) else {
                  return false
              }
        
        guard let dataStart = self.readData(startOffset: payload.data.offset, sectionLength: 9) else {
            return false
        }
        if dataStart.range(of: lzssHdr)?.startIndex == dataStart.startIndex {
            print("ASN1 Parse: Detected lzss.")
            return self.decompressLZSS(payloadData: payload.data, outputPath: outputPath)
        } else if dataStart.range(of: bvx2Hdr)?.startIndex == dataStart.startIndex {
            print("ASN1 Parse: Detected bvx2")
            
            guard subEntries.count >= 5 else {
                return false
            }
            var compressingSequence = subEntries[4]
            if !compressingSequence.tag.constructed,
               compressingSequence.tag.tagNumber == .octet,
               compressingSequence.tag.tagClass == .universal {
                guard subEntries.count >= 6 else {
                    return false
                }
                compressingSequence = subEntries[5]
            }
            
            guard let compressingSubEntries = self.parseSequence(entry: compressingSequence),
                  compressingSubEntries.count >= 2 else {
                      return false
                  }
            let versionTag = compressingSubEntries[0]
            let sizeTag = compressingSubEntries[1]
            
            guard !versionTag.tag.constructed,
                  !sizeTag.tag.constructed,
                  versionTag.tag.tagNumber == .integer,
                  sizeTag.tag.tagNumber == .integer,
                  versionTag.tag.tagClass == .universal,
                  sizeTag.tag.tagClass == .universal else {
                      return false
                  }
            
            guard parseInteger(entry: versionTag) == 1 else {
                print("ASN1 Parse error: Unexpected Compression Number")
                return false
            }
            guard let unpackedLen = parseInteger(entry: sizeTag) else {
                return false
            }
            return decompressBVX2(payloadData: payload.data, expectedLen: unpackedLen, outputPath: outputPath)
        } else {
            print("ASN1 Parse: Assuming uncompressed")
            
            try? FileManager.default.removeItem(atPath: outputPath)
            FileManager.default.createFile(atPath: outputPath, contents: nil, attributes: nil)
            guard let destination = FileHandle(forWritingAtPath: outputPath) else {
                return false
            }
            
            let bufferCapacity = UInt64(0x4000)
            
            var currentOffset = payload.data.offset
            var uncompressedLen = UInt64(0)
            while uncompressedLen < payload.data.len {
                var sublen = bufferCapacity
                if currentOffset + sublen > payload.data.offset + payload.data.len {
                    sublen = payload.data.offset + payload.data.len - currentOffset
                }
                defer {
                    uncompressedLen += sublen
                    currentOffset += sublen
                }
                
                guard let subdata = self.readData(startOffset: currentOffset, sectionLength: sublen) else {
                    return false
                }
                destination.write(subdata)
            }
            
            destination.closeFile()
            return true
        }
    }
}
