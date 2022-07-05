//
//  machoparse.swift
//  Taurine
//
//  Created by CoolStar on 3/31/20.
//  Copyright © 2020 coolstar. All rights reserved.
//

import Foundation
import MachO.dyld
import CommonCrypto

func parseMacho(path: String, symbol: String) -> [(UInt32, Bool)] {
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
        return []
    }
    
    let cpu = UInt32(littleEndian: data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self) })
    let ncmds = UInt32(littleEndian: data.withUnsafeBytes { $0.load(fromByteOffset: 16, as: UInt32.self) })
    
    guard cpu == 0x100000c else {
        return []
    }
    
    var symOff = UInt32(0)
    var strOff = UInt32(0)
    var indirectSymOff = UInt32(0)
    var nIndirectSyms = UInt32(0)
    
    var segmentOffset = 32
    for _ in 0..<ncmds {
        let cmd = UInt32(littleEndian: data.withUnsafeBytes({ $0.load(fromByteOffset: segmentOffset, as: UInt32.self) }))
        let cmdSize = UInt32(littleEndian: data.withUnsafeBytes({ $0.load(fromByteOffset: segmentOffset + 4, as: UInt32.self) }))
        defer { segmentOffset += Int(cmdSize) }
        
        if cmd == LC_SYMTAB {
            let parsedCmd = data.withUnsafeBytes({ $0.load( fromByteOffset: segmentOffset, as: symtab_command.self) })
            
            symOff = parsedCmd.symoff
            strOff = parsedCmd.stroff
        }
        
        if cmd == LC_DYSYMTAB {
            let parsedCmd = data.withUnsafeBytes({ $0.load( fromByteOffset: segmentOffset, as: dysymtab_command.self) })
            
            indirectSymOff = parsedCmd.indirectsymoff
            nIndirectSyms = parsedCmd.nindirectsyms
        }
    }
    
    guard symOff != 0,
        strOff != 0,
        indirectSymOff != 0,
        nIndirectSyms != 0 else {
            return []
    }
    
    var offsets: [(UInt32, Bool)] = []
    
    segmentOffset = 32
    for _ in 0..<ncmds {
        let cmd = UInt32(littleEndian: data.withUnsafeBytes({ $0.load(fromByteOffset: segmentOffset, as: UInt32.self) }))
        let cmdSize = UInt32(littleEndian: data.withUnsafeBytes({ $0.load(fromByteOffset: segmentOffset + 4, as: UInt32.self) }))
        defer { segmentOffset += Int(cmdSize) }
        
        if cmd == LC_SEGMENT_64 {
            var segment = data.withUnsafeBytes({ $0.load(fromByteOffset: segmentOffset, as: segment_command_64.self) })
            let segNameSz = MemoryLayout.size(ofValue: segment.segname)
            let segNameArr = withUnsafePointer(to: &segment.segname.0) {
                [Int8](UnsafeBufferPointer(start: $0, count: segNameSz))
            }
            guard let segNameRaw = String(bytes: segNameArr.map { UInt8($0) }, encoding: .utf8) else {
                continue
            }
            let segName = segNameRaw.components(separatedBy: "\0")[0]
            if segName == "__DATA" || segName == "__DATA_CONST" {
                var sectionOff = segmentOffset + MemoryLayout.size(ofValue: segment)
                for _ in 0..<segment.nsects {
                    var section = data.withUnsafeBytes({ $0.load(fromByteOffset: sectionOff, as: section_64.self) })
                    
                    let sectNameSz = MemoryLayout.size(ofValue: section.sectname)
                    let sectNameArr = withUnsafePointer(to: &section.sectname.0) {
                        [Int8](UnsafeBufferPointer(start: $0, count: sectNameSz))
                    }
                    guard let sectNameRaw = String(bytes: sectNameArr.map { UInt8($0) }, encoding: .utf8) else {
                        continue
                    }
                    let sectName = sectNameRaw.components(separatedBy: "\0")[0]
                    
                    if Int32(section.flags) & SECTION_TYPE == S_LAZY_SYMBOL_POINTERS ||
                        Int32(section.flags) & SECTION_TYPE == S_NON_LAZY_SYMBOL_POINTERS {
                        
                        let startIndex = section.reserved1
                        
                        var index = UInt32(0)
                        while index < UInt32(section.size / 8) {
                            defer { index += 1 }
                            
                            let symIndex = startIndex + index
                            let symtabIndex = UInt32(littleEndian: data.withUnsafeBytes({ $0.load(fromByteOffset: Int(indirectSymOff + (symIndex * 4)), as: UInt32.self) }))
                            
                            guard symtabIndex != INDIRECT_SYMBOL_ABS &&
                                symtabIndex != INDIRECT_SYMBOL_LOCAL &&
                                symtabIndex != (INDIRECT_SYMBOL_LOCAL | UInt32(INDIRECT_SYMBOL_ABS)) else {
                                continue
                            }
                            
                            let symbolOffset = Int(symOff) + Int(symtabIndex) * MemoryLayout<nlist_64>.size
                            let symtab = data.withUnsafeBytes({ $0.load(fromByteOffset: symbolOffset, as: nlist_64.self) })
                            guard symtab.n_un.n_strx != 0 else {
                                continue
                            }
                            
                            let stringOff = strOff + symtab.n_un.n_strx
                            let dataSlid = data.advanced(by: Int(stringOff))
                            guard let ptr = dataSlid.withUnsafeBytes({
                                    $0.bindMemory(to: UInt8.self)
                            }).baseAddress else {
                                continue
                            }
                            let str = String(decodingCString: ptr, as: UTF8.self)
                            if str == symbol {
                                let patchOffset = section.offset + (UInt32(index) * 8)
                                offsets.append((patchOffset, sectName.hasPrefix("__auth")))
                            }
                        }
                    }
                    sectionOff += MemoryLayout.size(ofValue: section)
                }
            }
        }
    }
    return offsets
}

let CSSLOT_CODEDIRECTORY = 0
let CSSLOT_ALTERNATE_CODEDIRECTORIES = 0x1000
let CSSLOT_ALTERNATURE_CODEDIRECORY_MAX = 5
let CSSLOT_ALTERNATE_CODEDIRECTORY_LIMIT = CSSLOT_ALTERNATE_CODEDIRECTORIES + CSSLOT_ALTERNATURE_CODEDIRECORY_MAX
let CSMAGIC_CODEDIRECTORY = 0xfade0c02

let CS_HASHTYPE_SHA1 = 1
let CS_HASHTYPE_SHA256 = 2
let CS_HASHTYPE_SHA256_TRUNCATED = 3
let CS_HASHTYPE_SHA384 = 4

let CODEDIR_SIZE = 0x58

let CS_CDHASH_LEN = 20
let CS_HASH_MAX_SIZE = 48

func parseSuperblob(codedir: Data) -> [UInt8] {
    guard codedir.count >= 12 else {
        return []
    }
    let count = UInt32(bigEndian: codedir.withUnsafeBytes { $0.load(fromByteOffset: 8, as: UInt32.self) })
   
    var highestHash = 0
    var outputDigest = [UInt8]()
    
    var idxOff = 12
    for _ in 0..<count {
        defer { idxOff += 8 }
        
        guard codedir.count >= idxOff + 8 else {
            break
        }
        let type = UInt32(bigEndian: codedir.withUnsafeBytes { $0.load(fromByteOffset: idxOff, as: UInt32.self) })
        let offset = UInt32(bigEndian: codedir.withUnsafeBytes { $0.load(fromByteOffset: idxOff + 4, as: UInt32.self) })
        
        if type == CSSLOT_CODEDIRECTORY || (type >= CSSLOT_ALTERNATE_CODEDIRECTORIES && type < CSSLOT_ALTERNATE_CODEDIRECTORY_LIMIT) {
            guard codedir.count >= Int(offset) + CODEDIR_SIZE else {
                continue
            }
            let subblob = Data(codedir[offset..<offset + UInt32(CODEDIR_SIZE)])
            
            let magic = UInt32(bigEndian: subblob.withUnsafeBytes { $0.load(fromByteOffset: 0, as: UInt32.self) })
            let realsize = UInt32(bigEndian: subblob.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self) })
            
            if magic == CSMAGIC_CODEDIRECTORY {
                guard codedir.count >= offset + realsize else {
                    continue
                }
                
                let realsubblob = Data(codedir[offset..<offset + realsize])
                
                let hashType = Int(realsubblob.withUnsafeBytes { $0.load(fromByteOffset: 0x25, as: UInt8.self) })
                
                var digest = [UInt8](repeating: 0, count: CS_HASH_MAX_SIZE)
                
                switch hashType {
                case CS_HASHTYPE_SHA1:
                    realsubblob.withUnsafeBytes {
                        _ = CC_SHA1($0.baseAddress, CC_LONG(realsize), &digest)
                    }
                case CS_HASHTYPE_SHA256:
// swiftlint:disable:next no_fallthrough_only
                    fallthrough
                case CS_HASHTYPE_SHA256_TRUNCATED:
                    realsubblob.withUnsafeBytes {
                        _ = CC_SHA256($0.baseAddress, CC_LONG(realsize), &digest)
                    }
                case CS_HASHTYPE_SHA384:
                    realsubblob.withUnsafeBytes {
                        _ = CC_SHA384($0.baseAddress, CC_LONG(realsize), &digest)
                    }
                default:
                    continue
                }
                
                if hashType > highestHash {
                    highestHash = hashType
                    let finalDigest = digest[0..<CS_CDHASH_LEN]
                    outputDigest = [UInt8](finalDigest)
                }
            }
        }
    }
    
    //let hexBytes = outputDigest.map { String(format: "%02hhx", $0) }.joined()
    return outputDigest
}

struct SliceInfo {
    let cpuType: UInt32
    let cpuSubtype: UInt32
    let offset: UInt32
    let size: UInt32
    let machOType: UInt32
}

func unpackFat(url: URL) -> [SliceInfo]? {
    guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
        return nil
    }
    
    defer { try? fileHandle.close() }
    
    let fileSize = fileHandle.seekToEndOfFile()
    fileHandle.seek(toFileOffset: 0)
    
    guard fileSize >= 8 else {
        return nil
    }
    
    var slices: [SliceInfo] = []
    
    let fileHeader = fileHandle.readData(ofLength: 8)
    let fat_hdr = UInt32(bigEndian: fileHeader.withUnsafeBytes { $0.load(fromByteOffset: 0, as: UInt32.self) })
    guard fat_hdr == FAT_MAGIC || fat_hdr == FAT_MAGIC_64 else {
        return nil
    }
    
    let nfatarch = UInt32(bigEndian: fileHeader.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self) })
    
    var fatOffset = 8
    
    let fatArchSz = MemoryLayout<fat_arch>.size
    for _ in 0..<nfatarch {
        defer { fatOffset += fatArchSz }
        
        guard fileSize >= fatOffset + fatArchSz else {
            continue
        }
        
        fileHandle.seek(toFileOffset: UInt64(fatOffset))
        let archData = fileHandle.readData(ofLength: fatArchSz)
        let arch = archData.withUnsafeBytes { $0.load(as: fat_arch.self) }
        
        let cputype = UInt32(bigEndian: UInt32(arch.cputype))
        let subtype = UInt32(bigEndian: UInt32(arch.cpusubtype))
        let offset = UInt32(bigEndian: arch.offset)
        let size = UInt32(bigEndian: arch.size)
        
        guard offset % 4 == 0,
              fileSize >= offset + 12 else {
            continue //both 32 and 64 bit should have this
        }
        
        fileHandle.seek(toFileOffset: UInt64(offset + 12))
        let fileTypeData = fileHandle.readData(ofLength: 4)
        let fileType = UInt32(littleEndian: fileTypeData.withUnsafeBytes { $0.load(as: UInt32.self) } )
        
        slices.append(SliceInfo(cpuType: cputype, cpuSubtype: subtype, offset: offset, size: size, machOType: fileType))
    }
    return slices
}

func getPreferredSlice(path: String, machOffset: inout Int) -> Bool {
    let url = URL(fileURLWithPath: path)
    guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
        return false
    }
    
    defer { try? fileHandle.close() }
    
    let fileSize = fileHandle.seekToEndOfFile()
    fileHandle.seek(toFileOffset: 0)
    
    guard fileSize >= 8 else {
        return false
    }
    
    machOffset = 0
    
    if let fatInfo = unpackFat(url: url)?.filter({ $0.cpuType == CPU_TYPE_ARM64 }) {
        guard !fatInfo.isEmpty else {
            return false
        }
        
        for slice in fatInfo where
            slice.machOType != fatInfo[0].machOType { //enforce all arm64/arm64e slices have the same type
            return false
        }
        
        let machOType = fatInfo[0].machOType
        
        let preferredCPUSubtypes: [UInt32]
        let preferredCPUSubtypesMask: [UInt32]
        
        if isArm64e() {
            if machOType == MH_EXECUTE {
                preferredCPUSubtypes = [CPU_SUBTYPE_PTRAUTH_ABI | UInt32(CPU_SUBTYPE_ARM64E),
                                        CPU_SUBTYPE_PTRAUTH_ABI | UInt32(CPU_SUBTYPE_ARM64E),
                                        UInt32(CPU_SUBTYPE_ARM_V8)]
                preferredCPUSubtypesMask = [0xffffffff,
                                            CPU_SUBTYPE_PTRAUTH_ABI | ~CPU_SUBTYPE_MASK,
                                            ~CPU_SUBTYPE_MASK]
            } else {
                preferredCPUSubtypes = [CPU_SUBTYPE_PTRAUTH_ABI | UInt32(CPU_SUBTYPE_ARM64E),
                                        UInt32(CPU_SUBTYPE_ARM64E),
                                        UInt32(CPU_SUBTYPE_ARM_V8)]
                preferredCPUSubtypesMask = [0xffffffff,
                                            ~CPU_SUBTYPE_MASK,
                                            ~CPU_SUBTYPE_MASK]
            }
        } else {
            preferredCPUSubtypes = [UInt32(CPU_SUBTYPE_ARM_V8)]
            preferredCPUSubtypesMask = [~CPU_SUBTYPE_MASK]
        }
        
        for (preferredCPUSubtype, preferredCPUSubtypeMask) in zip(preferredCPUSubtypes, preferredCPUSubtypesMask) {
            for slice in fatInfo {
                let subtype = slice.cpuSubtype & preferredCPUSubtypeMask
                if subtype & preferredCPUSubtypeMask == preferredCPUSubtype ||
                    (preferredCPUSubtype == CPU_SUBTYPE_ARM_V8 && subtype == CPU_SUBTYPE_ARM64_ALL) {
                    machOffset = Int(slice.offset)
                    break
                }
            }
            if machOffset != 0 {
                break
            }
        }
    }
    
    guard machOffset % 4 == 0 else {
        return false
    }
    guard fileSize >= machOffset + 32 else {
        return false
    }
    
    fileHandle.seek(toFileOffset: UInt64(machOffset))
    let data = fileHandle.readData(ofLength: 8)
    let hdr = UInt32(littleEndian: data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: UInt32.self) })
    let cpu = UInt32(littleEndian: data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self) })
    
    guard hdr == MH_MAGIC_64,
          cpu == 0x100000c else {
        return false
    }
    return true
}

func getCodeSignatureBlobDyldCache(path: String) -> Data? {
    let url = URL(fileURLWithPath: path)
    guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
        return nil
    }
    
    defer { try? fileHandle.close() }
    
    let fileSize = fileHandle.seekToEndOfFile()
    fileHandle.seek(toFileOffset: UInt64(0))
    
    guard fileSize >= 104 else { //minimum size of dyld_cache_header
        return nil
    }
    
    let dyldSharedCacheMagic = fileHandle.readData(ofLength: 16)
    guard let dyldSharedCacheMagicStr = String(data: dyldSharedCacheMagic, encoding: .utf8) else {
        return nil
    }
    guard dyldSharedCacheMagicStr.hasPrefix("dyld_v"),
          dyldSharedCacheMagicStr.contains("arm64") else {
        return nil
    }
    
    fileHandle.seek(toFileOffset: 40) //codeSignatureOffset + codeSignatureSize
    let codeSignatureInfo = fileHandle.readData(ofLength: 16)
    
    let codeSignatureOffset = UInt64(littleEndian: codeSignatureInfo.withUnsafeBytes { $0.load(as: UInt64.self) })
    let codeSignatureSize = UInt64(littleEndian: codeSignatureInfo.withUnsafeBytes { $0.load(as: UInt64.self) })
    
    guard codeSignatureOffset + codeSignatureSize > fileSize else {
        return nil
    }
    
    fileHandle.seek(toFileOffset: codeSignatureOffset)
    
    return fileHandle.readData(ofLength: Int(codeSignatureSize))
}

func getCodeSignatureBlob(path: String, isDylib: inout Bool, machOffset: inout Int, machSubtype: inout UInt32) -> Data? {
    guard getPreferredSlice(path: path, machOffset: &machOffset) else {
        if let blob = getCodeSignatureBlobDyldCache(path: path) {
            isDylib = true //dyld shared cache should always be treated as dylib
            machOffset = 0
            machSubtype = UInt32(bitPattern: CPU_SUBTYPE_ANY)
            return blob
        }
        return nil
    }
    
    let url = URL(fileURLWithPath: path)
    guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
        return nil
    }
    
    defer { try? fileHandle.close() }
    
    let fileSize = fileHandle.seekToEndOfFile()
    fileHandle.seek(toFileOffset: UInt64(machOffset))
    
    let rawMachHdr = fileHandle.readData(ofLength: 32)
    let machHdr = rawMachHdr.withUnsafeBytes { $0.load(as: mach_header_64.self) }
    let hdr = UInt32(littleEndian: machHdr.magic)
    let cpu = UInt32(littleEndian: UInt32(bitPattern: machHdr.cputype))
    let subtype = UInt32(littleEndian: UInt32(bitPattern: machHdr.cpusubtype))
    let filetype = UInt32(littleEndian: machHdr.filetype)
    let ncmds = UInt32(littleEndian: machHdr.ncmds)
    
    guard hdr == MH_MAGIC_64,
        cpu == 0x100000c else {
        return nil
    }
    machSubtype = subtype
    
    isDylib = (filetype != MH_EXECUTE)
    
    var segmentOffset = machOffset + 32
    for _ in 0..<ncmds {
        guard fileSize >= segmentOffset + 8 else {
            continue
        }
        
        fileHandle.seek(toFileOffset: UInt64(segmentOffset))
        let rawCmd = fileHandle.readData(ofLength: 8)
        let cmd = UInt32(littleEndian: rawCmd.withUnsafeBytes({ $0.load(fromByteOffset: 0, as: UInt32.self) }))
        let cmdSize = UInt32(littleEndian: rawCmd.withUnsafeBytes({ $0.load(fromByteOffset: 4, as: UInt32.self) }))
        defer { segmentOffset += Int(cmdSize) }
        
        if cmd == LC_CODE_SIGNATURE {
            let loadCmdSize = MemoryLayout<load_command>.size
            guard fileSize >= segmentOffset + loadCmdSize + 8 else {
                continue
            }
            
            fileHandle.seek(toFileOffset: UInt64(segmentOffset + loadCmdSize))
            let rawSegment = fileHandle.readData(ofLength: 8)
            let off_cd = UInt32(machOffset) + UInt32(littleEndian: rawSegment.withUnsafeBytes({ $0.load(fromByteOffset: 0, as: UInt32.self) }))
            let size_cs = UInt32(littleEndian: rawSegment.withUnsafeBytes({ $0.load(fromByteOffset: 4, as: UInt32.self) }))
            
            guard fileSize >= off_cd + size_cs else {
                continue
            }
            
            fileHandle.seek(toFileOffset: UInt64(off_cd))
            return fileHandle.readData(ofLength: Int(size_cs))
        }
    }
    
    return nil
}

func getCodeSignature(path: String) -> [UInt8] {
    var isDylib: Bool = false
    var machOffset: Int = 0
    var machSubtype: UInt32 = 0
    guard let data = getCodeSignatureBlob(path: path, isDylib: &isDylib, machOffset: &machOffset, machSubtype: &machSubtype) else {
        return []
    }
    return parseSuperblob(codedir: data)
}
