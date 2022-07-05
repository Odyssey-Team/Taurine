//
//  extractKernel.swift
//  Taurine
//
//  Created by CoolStar on 3/16/21.
//

import Foundation

func findKernel() -> String? {
    print("Searching for running kernel...")
    guard let active = try? String(contentsOfFile: "/private/preboot/active") else {
        print("Unable to get active preboot")
        return nil
    }
    print("Found active preboot: \(active)")
    let kernelPath = "/private/preboot/\(active)/System/Library/Caches/com.apple.kernelcaches/kernelcache"
    guard FileManager.default.fileExists(atPath: kernelPath) else {
        print("Unable to find kernel (tried \(kernelPath))")
        return nil
    }
    return kernelPath
}

func getKernel() -> Bool {
    guard let rawKernelCachePath = findKernel() else {
        return false
    }
    let tmpKernelCachePath = "/tmp/kernelcache"
    let tmpKernelPath = "/tmp/kernel"
    
    try? FileManager.default.removeItem(atPath: tmpKernelCachePath)
    try? FileManager.default.removeItem(atPath: tmpKernelPath)
    
    do {
        try FileManager.default.copyItem(at: URL(fileURLWithPath: rawKernelCachePath),
                                           to: URL(fileURLWithPath: tmpKernelCachePath))
    } catch {
        print("Unable to copy kernelcache to tmp folder")
        return false
    }
    
    guard let asn1Parser = Asn1Parser(url: URL(fileURLWithPath: tmpKernelCachePath)) else {
        print("Unable to open kernelcache")
        return false
    }
    if asn1Parser.isIMG4() {
        guard asn1Parser.unwrapIMG4() else {
            print("Unable to unwrap kernelCache container")
            return false
        }
    }
    guard asn1Parser.isIM4P() else {
        print("kernelCache is not valid format")
        return false
    }
    guard asn1Parser.parseIM4P(outputPath: tmpKernelPath) else {
        print("Unable to extract kernelcache")
        return false
    }
    
    try? FileManager.default.removeItem(atPath: tmpKernelCachePath)
    guard FileManager.default.fileExists(atPath: tmpKernelPath) else {
        print("ASN1 parser succeeded but kernel not present???")
        return false
    }
    
    let kernelURL = URL(fileURLWithPath: tmpKernelPath)
    
    if let kernelInfo = unpackFat(url: kernelURL) {
        print("FAT binary detected. Extracting")
        
        guard kernelInfo.count >= 0 else {
            print("Kernel is FAT but no slices")
            return false
        }
        
        let offset = kernelInfo[0].offset
        let size = kernelInfo[0].size
        
        guard let fileHandle = try? FileHandle(forReadingFrom: kernelURL) else {
            return false
        }
        
        defer { try? fileHandle.close() }
        
        let fileSize = fileHandle.seekToEndOfFile()
        fileHandle.seek(toFileOffset: 0)
        
        guard offset + size <= fileSize else {
            print("Slice extends past end of file")
            return false
        }
        
        fileHandle.seek(toFileOffset: UInt64(offset))
        
        let outKernelURL = URL(fileURLWithPath: tmpKernelPath + "-thin")
        guard FileManager.default.createFile(atPath: tmpKernelPath + "-thin", contents: nil),
              let outFileHandle = try? FileHandle(forWritingTo: outKernelURL) else {
            print("Unable to open output handle")
            return false
        }
        defer { try? outFileHandle.close() }
        
        do {
            
            var writtenBytes = UInt32(0)
            while (writtenBytes < size){
                let chunkBytes = min(16384, size - writtenBytes)
                
                autoreleasepool {
                    let chunk = fileHandle.readData(ofLength: Int(chunkBytes))
                    outFileHandle.write(chunk)
                }
                writtenBytes += chunkBytes
            }
            
            try FileManager.default.removeItem(at: URL(fileURLWithPath: tmpKernelPath))
            try FileManager.default.moveItem(at: URL(fileURLWithPath: tmpKernelPath + "-thin"),
                                         to: URL(fileURLWithPath: tmpKernelPath))
            print("FAT extracted successfully")
        } catch {
            print("Error saving slice from FAT binary")
            return false
        }
    }
    
    return true
}
