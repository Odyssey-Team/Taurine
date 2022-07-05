//
//  ASN1Parser.swift
//  Taurine15
//
//  Created by CoolStar on 3/24/22.
//

import Foundation

class Asn1Parser {
    enum TagClass: Int {
        case universal = 0
        case application
        case contextSpecific
        case priv
    }

    enum TagNumber: Int {
        case endOfContext = 0
        case boolean
        case integer
        case bit
        case octet
        case null
        case object
        case object2
        case external
        case real
        case enumerated
        case embedded
        case utf8string
        case relativeOid
        case reserved1
        case reserved2
        case sequence
        case set
        case numericString
        case printableString
        case t161sString
        case videoTexString
        case ia5String
        case utcTime
        case generalizedTime
        case graphicString
        case visibleString
        case generalString
        case universalString
        case character
        case bmpString
        
        case priv = 0xff
    }

    struct Asn1Tag {
        let tagNumber: TagNumber //5
        let constructed: Bool //1
        let tagClass: TagClass //2
        
        init(byte: UInt8){
            tagNumber = TagNumber(rawValue: Int(byte & 0x1f)) ?? TagNumber.priv
            constructed = ((byte >> 5) & 0x1) == 1
            tagClass = TagClass(rawValue: Int(byte >> 6) & 0x3) ?? TagClass.priv
        }
    }

    struct DataDesc {
        let offset: UInt64
        let len: UInt64
    }

    struct Asn1Entry {
        let tag: Asn1Tag
        let data: DataDesc
        let len: UInt64
    }
    
    private let fileHandle: FileHandle
    private let fileSize: UInt64
    
    private var rootEntryRaw: Asn1Entry?
    public var rootEntry: Asn1Entry {
        get {
            rootEntryRaw!
        }
    }
    
    init?(url: URL){
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        self.fileHandle = fileHandle
        
        fileSize = fileHandle.seekToEndOfFile()
        fileHandle.seek(toFileOffset: 0)
        
        guard let rootEntries = parseSection(startOffset: 0, sectionLength: fileSize),
              rootEntries.count == 1 else {
            return nil
        }
        rootEntryRaw = rootEntries[0]
    }
    
    public func readData(startOffset: UInt64, sectionLength: UInt64) -> Data? {
        let sectionEnd = startOffset + sectionLength
        guard sectionEnd <= fileSize else {
#if DEBUG
            print("ASN1 Parse error: Invalid section")
#endif
            return nil
        }
        fileHandle.seek(toFileOffset: startOffset)
        return fileHandle.readData(ofLength: Int(sectionLength))
    }
    
    private func parseSection(startOffset: UInt64, sectionLength: UInt64) -> [Asn1Entry]? {
        var fileOffset = startOffset
        let sectionEnd = startOffset + sectionLength
        guard sectionEnd <= fileSize else {
#if DEBUG
            print("ASN1 Parse error: Invalid section")
#endif
            return nil
        }
        
        var entries: [Asn1Entry] = []
        while fileOffset < sectionEnd {
            guard fileOffset + 2 <= sectionEnd else {
#if DEBUG
                print("ASN1 Parse error: failed to get header")
#endif
                return nil
            }
            fileHandle.seek(toFileOffset: fileOffset)
            
            let startIndex = fileOffset
            
            let rawTag = fileHandle.readData(ofLength: 1)[0]
            fileOffset += 1
            let tag = Asn1Tag(byte: rawTag)
            
            var len = UInt64(0)
            var val = fileHandle.readData(ofLength: 1)[0]
            fileOffset += 1
            if val & 0x80 == 0 {
                len = UInt64(val)
            } else if val != 0x80 {
                let numOctets = Int(val & 0x7f)
                for _ in 0..<numOctets {
                    len <<= 8
                    guard fileOffset + 1 <= sectionEnd else {
#if DEBUG
                        print("ASN1 Parse error: failed to get fixed len")
#endif
                        return nil
                    }
                    val = fileHandle.readData(ofLength: 1)[0]
                    fileOffset += 1
                    len |= UInt64(val) & 0xff
                }
            } else {
#if DEBUG
                print("ASN1 Parse warning: Indefinite length untested. Parsing may fail")
#endif
                //Indefinite length. Scan until 2 zero bytes
                let scanStartOffset = fileOffset
                var rawData: Data?
                while rawData == nil || (rawData?[0] != 0 && rawData?[1] != 0) {
                    guard fileOffset + 2 <= sectionEnd else {
#if DEBUG
                        print("ASN1 Parse error: failed to get indef len")
#endif
                        return nil
                    }
                    fileHandle.seek(toFileOffset: fileOffset)
                    rawData = fileHandle.readData(ofLength: 2)
                    fileOffset += 1
                }
                fileOffset -= 1
                len = fileOffset - scanStartOffset
                
                fileOffset = scanStartOffset
                fileHandle.seek(toFileOffset: fileOffset)
            }
            
            let dataDesc = DataDesc(offset: fileOffset, len: len)
            entries.append(Asn1Entry(tag: tag, data: dataDesc, len: fileOffset + len - startIndex))
            fileOffset += len
        }
        return entries
    }
}

extension Asn1Parser {
    public func isSequence(entry: Asn1Entry) -> Bool {
        entry.tag.tagNumber == .sequence
    }
    
    public func parseSequence(entry: Asn1Entry) -> [Asn1Entry]? {
        guard isSequence(entry: entry) else {
            return nil
        }
        return self.parseSection(startOffset: entry.data.offset, sectionLength: entry.data.len)
    }
}

extension Asn1Parser {
    public func isString(entry: Asn1Entry) -> Bool {
        entry.tag.tagNumber == .ia5String || entry.tag.tagNumber == .octet
    }
    public func parseString(entry: Asn1Entry) -> String? {
        guard isString(entry: entry),
              let data = self.readData(startOffset: entry.data.offset, sectionLength: entry.data.len) else {
            return nil
        }
        guard let str = String(data: data, encoding: .utf8),
              str.count == entry.data.len else {
            return nil
        }
        return str
    }
}

extension Asn1Parser {
    public func isInteger(entry: Asn1Entry) -> Bool {
        entry.tag.tagNumber == .integer || entry.tag.tagNumber == .boolean
    }
    
    public func parseInteger(entry: Asn1Entry) -> UInt64? {
        guard isInteger(entry: entry),
              entry.data.len <= MemoryLayout<UInt64>.size,
              let data = self.readData(startOffset: entry.data.offset, sectionLength: entry.data.len) else {
            return nil
        }
        var ret = UInt64(0)
        for i in 0..<Int(entry.data.len) {
            ret <<= 8
            ret |= UInt64(data[i] & 0xFF)
        }
        return ret
    }
}

extension Asn1Parser {
    public func isIMG4() -> Bool {
        guard rootEntry.tag.constructed,
              rootEntry.tag.tagNumber == .sequence,
              rootEntry.tag.tagClass == .universal else {
                  return false
              }
        guard let subEntries = parseSequence(entry: rootEntry),
              let firstEntry = subEntries.first,
              parseString(entry: firstEntry) == "IMG4" else {
                  return false
              }
        return true
    }
    public func unwrapIMG4() -> Bool {
        guard isIMG4(),
              let subEntries = parseSequence(entry: rootEntry),
              subEntries.count >= 2 else {
                  return false
              }
        let payload = subEntries[1]
        guard isIM4P(entry: payload) else {
            return false
        }
        rootEntryRaw = payload
        return true
    }
}
