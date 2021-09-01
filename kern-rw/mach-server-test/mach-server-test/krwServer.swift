//
//  krwServer.swift
//  mach-server-test
//
//  Created by CoolStar on 2/27/21.
//

@_cdecl("krw_read32")
func read32(server_port: mach_port_t, kaddr: UInt64, val: UnsafeMutablePointer<UInt32>, audit_token: audit_token_t) -> kern_return_t {
    val.pointee = UInt32.random(in: 1..<256)
    print("read32 addr:", String(format: "0x%llx", kaddr) ,"val:", String(format: "0x%x",val.pointee))
    return KERN_SUCCESS
}

@_cdecl("krw_read64")
func read64(server_port: mach_port_t, kaddr: UInt64, val: UnsafeMutablePointer<UInt64>, audit_token: audit_token_t) -> kern_return_t {
    val.pointee = UInt64.random(in: 0x424242424240..<0x42424242424242)
    print("read64 addr:", String(format: "0x%llx", kaddr) ,"val:", String(format: "0x%llx",val.pointee))
    return KERN_SUCCESS
}

@_cdecl("krw_write32")
func write32(server_port: mach_port_t, kaddr: UInt64, val: UInt32, audit_token: audit_token_t) -> kern_return_t {
    print("write64 addr:", String(format: "0x%llx", kaddr) ,"val:", String(format: "0x%x",val))
    return KERN_SUCCESS
}

@_cdecl("krw_write64")
func write64(server_port: mach_port_t, kaddr: UInt64, val: UInt64, audit_token: audit_token_t) -> kern_return_t {
    print("write64 addr:", String(format: "0x%llx", kaddr) ,"val:", String(format: "0x%llx",val))
    return KERN_SUCCESS
}
