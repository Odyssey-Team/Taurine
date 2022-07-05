//
//  kernelPatchfinder.swift
//  Taurine15
//
//  Created by CoolStar on 3/24/22.
//

import Foundation
import MachO

public class KernelPatchfinder {
    private let fileHandle: FileHandle
    private let fileSize: UInt64
    
    private let textstrs: (section_64, Data)
    private let oslstrs: (section_64, Data)
    private let plkstrs: (section_64, Data)?
    
    private let textinsts: (section_64, Data)
    private let xnucore: (section_64, Data)
    private let prelink: (section_64, Data)?
    
    private let kernelBase: UInt64
    private let kernelSize: UInt64
    
    public init?(url: URL){
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        self.fileHandle = fileHandle
        
        fileSize = fileHandle.seekToEndOfFile()
        fileHandle.seek(toFileOffset: 0)
        
        let rawMachHdr = fileHandle.readData(ofLength: 32)
        let machHdr = rawMachHdr.withUnsafeBytes { $0.load(as: mach_header_64.self) }
        let hdr = UInt32(littleEndian: machHdr.magic)
        let cpu = UInt32(littleEndian: UInt32(bitPattern: machHdr.cputype))
        let ncmds = UInt32(littleEndian: machHdr.ncmds)
        
        guard hdr == MH_MAGIC_64,
              cpu == CPU_TYPE_ARM64 else {
                  return nil
        }
        
        var minAddr = UInt64(bitPattern: Int64(-1))
        var maxAddr = UInt64(0)
        
        var textstrs: (section_64, Data)?
        var oslstrs: (section_64, Data)?
        var plkstrs: (section_64, Data)?
        
        var textinsts: (section_64, Data)?
        var xnucore: (section_64, Data)?
        var prelink: (section_64, Data)?
        
        var segmentOffset = MemoryLayout<mach_header_64>.size
        for _ in 0..<ncmds {
            guard fileSize >= segmentOffset + 8 else {
                continue
            }
            
            fileHandle.seek(toFileOffset: UInt64(segmentOffset))
            let rawCmd = fileHandle.readData(ofLength: 8)
            let cmd = UInt32(littleEndian: rawCmd.withUnsafeBytes({ $0.load(fromByteOffset: 0, as: UInt32.self) }))
            let cmdSize = UInt32(littleEndian: rawCmd.withUnsafeBytes({ $0.load(fromByteOffset: 4, as: UInt32.self) }))
            defer { segmentOffset += Int(cmdSize) }
            
            if cmd == LC_SEGMENT_64 {
                fileHandle.seek(toFileOffset: UInt64(segmentOffset))
                
                let rawSegment = fileHandle.readData(ofLength: MemoryLayout<segment_command_64>.size)
                let segment = rawSegment.withUnsafeBytes { $0.load(as: segment_command_64.self) }
                if minAddr > segment.vmaddr,
                   segment.vmsize > 0 {
                    minAddr = segment.vmaddr
                }
                if maxAddr < segment.vmaddr + segment.vmsize,
                   segment.vmsize > 0 {
                    maxAddr = segment.vmaddr + segment.vmsize
                }
                let segNameMirror = Mirror(reflecting: segment.segname)
                let segName = segNameMirror.children.reduce("") { identifier, element in
                    guard let value = element.value as? Int8, value != 0 else { return identifier }
                    return identifier + String(UnicodeScalar(UInt8(value)))
                }
                let searchSegs = ["__TEXT", "__PRELINK_TEXT", "__TEXT_EXEC", "__PLK_TEXT_EXEC"]
                
                if searchSegs.contains(segName) {
                    var sectionOff = UInt64(segmentOffset) + UInt64(MemoryLayout.size(ofValue: segment))
                    for _ in 0..<segment.nsects {
                        fileHandle.seek(toFileOffset: sectionOff)
                        let sectionData = fileHandle.readData(ofLength: MemoryLayout<section_64>.size)
                        let section = sectionData.withUnsafeBytes({ $0.load(as: section_64.self) })
                        defer { sectionOff += UInt64(MemoryLayout.size(ofValue: section)) }
                        
                        let sectNameMirror = Mirror(reflecting: section.sectname)
                        let sectName = sectNameMirror.children.reduce("") { identifier, element in
                            guard let value = element.value as? Int8, value != 0 else { return identifier }
                            return identifier + String(UnicodeScalar(UInt8(value)))
                        }
                        
                        fileHandle.seek(toFileOffset: UInt64(section.offset))
                        autoreleasepool {
                            let sectData = fileHandle.readData(ofLength: Int(section.size))
                            if sectName == "__cstring" {
                                if segName == "__TEXT" {
                                    textstrs = (section, sectData)
                                } else if segName == "__PRELINK_TEXT" {
                                    plkstrs = (section, sectData)
                                }
                            }
                            if sectName == "__os_log" && segName == "__TEXT" {
                                oslstrs = (section, sectData)
                            }
                            if sectName == "__text" {
                                if segName == "__TEXT" || segName == "__PRELINK_TEXT" {
                                    textinsts = (section, sectData)
                                }
                                if segName == "__TEXT_EXEC" {
                                    xnucore = (section, sectData)
                                }
                                if segName == "__PLK_TEXT_EXEC" {
                                    prelink = (section, sectData)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        guard let textstrs = textstrs,
              let oslstrs = oslstrs,
              let textinsts = textinsts,
              let xnucore = xnucore else {
            return nil
        }
        self.textstrs = textstrs
        self.oslstrs = oslstrs
        self.plkstrs = plkstrs
        
        self.textinsts = textinsts
        self.xnucore = xnucore
        self.prelink = prelink
        
        self.kernelBase = minAddr
        self.kernelSize = maxAddr - minAddr
    }
    
    deinit {
        try? fileHandle.close()
    }
    
    struct Arm64Insn {
        let what: UInt32
        let mask: UInt32
        
        static let call = Arm64Insn(what: 0x94000000, mask: 0xFC000000)
        static let b = Arm64Insn(what: 0x14000000, mask: 0xFC000000)
        static let adrp = Arm64Insn(what: 0x90000000, mask: 0x9F000000)
        static let cmp = Arm64Insn(what: 0x7100001F, mask: 0x71C0001F)
    }
    
    private func step64(section: (section_64, Data), start: UInt64, len: UInt64, insn: Arm64Insn) -> ((section_64, Data), UInt64)?{
        let sectData = section.1
        
        for off in stride(from: start, to: start + len, by: 4){
            let x = sectData.withUnsafeBytes { $0.load(fromByteOffset: Int(off), as: UInt32.self) }
            if x & insn.mask == insn.what {
                return (section, off)
            }
        }
        return nil
    }
    
    private func step64_back(section: (section_64, Data), start: UInt64, len: UInt64, insn: Arm64Insn) -> ((section_64, Data), UInt64)?{
        let sectData = section.1
        guard start > len else {
            return nil
        }
        
        for off in stride(from: start - len, to: start, by: 4).reversed() {
            let x = sectData.withUnsafeBytes { $0.load(fromByteOffset: Int(off), as: UInt32.self) }
            if x & insn.mask == insn.what {
                return (section, off)
            }
        }
        return nil
    }
    
    private func signExtend64(imm: UInt64, off: UInt8) -> Int64 {
        var result = imm
        let signBit = (imm >> off) & 0x1
        for i in (off+1)..<64 {
            result |= (signBit << i)
        }
        return Int64(bitPattern: result)
    }
    
    private func addOffset(unsigned: UInt64, signed: Int64) -> UInt64 {
        return UInt64(bitPattern: Int64(bitPattern: unsigned) + signed)
    }
    
    private func asmHandleInternal(sect: section_64, off: UInt64, op: UInt32, reg: inout Int, value: inout [UInt64]) -> Bool {
        let reg = Int(op & 0x1F)
        
        if (op & 0x9F000000) == 0x90000000 {
            let adr = UInt64(((op & 0x60000000) >> 18) | ((op & 0xFFFFE0) << 8)) << 1
            let adrSigned = signExtend64(imm: adr, off: 32)
            value[reg] = addOffset(unsigned: (off & ~0xFFF) + sect.addr, signed: adrSigned)
        } else if (op & 0xFF000000) == 0x91000000 {
            let rn = Int((op >> 5) & 0x1F)
            let shift = (op >> 22) & 3
            var imm = UInt64(op >> 10) & 0xFFF
            if shift == 1 {
                imm <<= 12;
            } else {
                if shift > 1 {
                    return false //fatalError()
                }
            }
            //printf("%llx: ADD X%d, X%d, 0x%x\n", i, reg, rn, imm);
            value[reg] = value[rn] + imm
        } else if (op & 0xF9C00000) == 0xB9400000 {
            let rn = Int((op >> 5) & 0x1F)
            let imm = (UInt64(op >> 11) & 0x1FF) << 3
            //printf("%llx: LDR W%d, [X%d, 0x%x]\n", i, reg, rn, imm);
            value[reg] = value[rn] + imm    // XXX address, not actual value
        } else if (op & 0xF9C00000) == 0xB9000000 {
            let rn = Int((op >> 5) & 0x1F)
            let imm = (UInt64(op >> 11) & 0x1FF) << 3
            //printf("%llx: STR W%d, [X%d, 0x%x]\n", i, reg, rn, imm);
            value[rn] = value[rn] + imm    // XXX address, not actual val
        } else if (op & 0xF9C00000) == 0xF9400000 {
            let rn = Int((op >> 5) & 0x1F)
            let imm = (UInt64(op >> 10) & 0xFFF) << 3
            //printf("%llx: LDR X%d, [X%d, 0x%x]\n", i, reg, rn, imm);
            value[reg] = value[rn] + imm    // XXX address, not actual value
        } else if (op & 0xF9C00000) == 0xF9000000 {
            let rn = Int((op >> 5) & 0x1F)
            let imm = (UInt64(op >> 10) & 0xFFF) << 3
            //printf("%llx: STR X%d, [X%d, 0x%x]\n", i, reg, rn, imm);
            value[rn] = value[rn] + imm    // XXX address, not actual value
        } else if (op & 0x9F000000) == 0x10000000 {
            let adr = ((op & 0x60000000) >> 18) | ((op & 0xFFFFE0) << 8);
            //printf("%llx: ADR X%d, 0x%llx\n", i, reg, ((long long)adr >> 11) + i);
            value[reg] = (UInt64(adr) >> 11) + off
        } else if (op & 0xFF000000) == 0x58000000 {
            let adr = (UInt64(op) & 0xFFFFE0) >> 3;
            //printf("%llx: LDR X%d, =0x%llx\n", i, reg, adr + i);
            value[reg] = adr + off + sect.addr        // XXX address, not actual value
        }
        return true
    }
    
    private func calc64(section: (section_64, Data), start: UInt64, end: UInt64, which: Int) -> UInt64? {
        guard which <= 31 else {
            print("Invalid reg")
            return nil
        }
        
        let sect = section.0
        let sectData = section.1
        var value = [UInt64](repeating: 0, count: 32)
        
        let start = start & ~3
        let end = end & ~3
        
        for off in stride(from: start, to: end, by: 4) {
            let op = sectData.withUnsafeBytes { $0.load(fromByteOffset: Int(off), as: UInt32.self) }
            var reg = 0
            guard asmHandleInternal(sect: sect, off: off, op: op, reg: &reg, value: &value) else {
                continue
            }
        }
        return value[which]
    }
    
    private func findRaw(insts: [UInt32]) -> ((section_64, Data), UInt64)? {
        let sections: [(section_64, Data)]
        if let prelink = prelink {
            sections = [xnucore, prelink]
        } else {
            sections = [xnucore]
        }
        
        for section in sections {
            let sect = section.0
            let sectData = section.1
            
            let iterLen = UInt64(insts.count * MemoryLayout<UInt32>.size)
            guard sect.size > iterLen else {
                continue
            }
            
            for off in stride(from: UInt64(0), to: sect.size - iterLen, by: 4) {
                let cmp = sectData[Int(off)..<Int(off+iterLen)]
                    .withUnsafeBytes { readInsntsBytes in
                        insts.withUnsafeBytes { instsBytes in
                            return memcmp(readInsntsBytes.baseAddress, instsBytes.baseAddress, Int(iterLen))
                        }
                    }
                if cmp == 0 {
                    return (section, off)
                }
            }
        }
        return nil
    }
    
    private func findStr(str: String) -> ((section_64, Data), UInt64)? {
        guard let stringData = str.data(using: .utf8) else {
            return nil
        }
        
        let sections: [(section_64, Data)]
        if let plkstrs = plkstrs {
            sections = [textstrs, oslstrs, plkstrs]
        } else {
            sections = [textstrs, oslstrs]
        }
        
        for section in sections {
            let sectData = section.1
            
            if let subRange = sectData.range(of: stringData) {
                return (section, UInt64(sectData.startIndex.distance(to: subRange.lowerBound)))
            }
        }
        return nil
    }
    
    private func xref64_internal(section: (section_64, Data), start: UInt64, end: UInt64, what: UInt64) -> ((section_64, Data), UInt64)? {
        let sect = section.0
        let sectData = section.1
        var value = [UInt64](repeating: 0, count: 32)
        
        let start = start & ~3
        let end = end & ~3
        
        for off in stride(from: start, to: end, by: 4) {
            let op = sectData.withUnsafeBytes { $0.load(fromByteOffset: Int(off), as: UInt32.self) }
            var reg = 0
            guard asmHandleInternal(sect: sect, off: off, op: op, reg: &reg, value: &value) else {
                continue
            }
            
            if value[reg] == what && reg != 0x1f {
                return (section, off)
            }
        }
        
        return nil
    }
    
    private func xref64(what: UInt64) -> ((section_64, Data), UInt64)? {
        let sections: [(section_64, Data)]
        if let prelink = prelink {
            sections = [xnucore, prelink]
        } else {
            sections = [xnucore]
        }
        
        for section in sections {
            let sect = section.0
            if let ret = xref64_internal(section: section, start: 0, end: sect.size, what: what) {
                return ret
            }
        }
        return nil
    }
    
    private func findCsBlobResetCacheArmv8() -> ((section_64, Data), UInt64)? {
        return findRaw(insts: [
            0x885F7D09, //ldxr w9, [x8]
            0x11000929, //add w9, w9, #0x2
            0x880A7D09 //stxr w10, w9, [x8]
        ])
    }
    
    public func findCsBlobResetCacheArmv81() -> ((section_64, Data), UInt64)? {
        return findRaw(insts: [
            0x321F03E9, //orr w9, wzr, #0x2
            0xB829011F, //stadd w9, [x8]
            0xD65F03C0 //ret
        ])
    }
    
    public func findCsBlobResetCacheArmv81_2() -> ((section_64, Data), UInt64)? {
        return findRaw(insts: [
            0x52800049, //movz w9, #0x2
            0xB8290108, //ldadd w9, w8, [x8]
            0xD65F03C0 //ret
        ])
    }
    
    public func find_cs_blob_generation_count() -> UInt64? {
        if let findReset = findCsBlobResetCacheArmv8() ?? findCsBlobResetCacheArmv81() ?? findCsBlobResetCacheArmv81_2() {
            if let loadGenCount = step64_back(section: findReset.0, start: findReset.1, len: UInt64(5 * MemoryLayout<UInt32>.size), insn: Arm64Insn.adrp) {
                let csblobResetCache = calc64(section: loadGenCount.0, start: loadGenCount.1, end: loadGenCount.1 + UInt64(8 * MemoryLayout<UInt32>.size), which: 8)
                return csblobResetCache
            }
        }
        return nil
    }
}
