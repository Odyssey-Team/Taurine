//
//  main.swift
//  mach-client-test
//
//  Created by CoolStar on 2/27/21.
//

import Foundation

var server_port = mach_port_t(0)
guard bootstrap_look_up(bootstrap_port, "org.coolstar.krw-server-test", &server_port) == KERN_SUCCESS else {
    fatalError("Unable to allocate mach port")
}

/*var task = mach_port_t(0)
guard task_for_pid(mach_task_self_, pid_t(60926), &task) == KERN_SUCCESS else {
    fatalError("Unable to get task port")
}

var ports: thread_act_array_t?
var portsCount = mach_msg_type_number_t(0)
guard mach_ports_lookup(task, &ports, &portsCount) == KERN_SUCCESS else {
    fatalError("Unable to lookup ports")
}

guard let port = ports?.pointee else {
    fatalError("Unable to get port")
}

let server_port: mach_port_t = port*/

while true {
    repeat {
        let addr = UInt64.random(in: 0..<UInt64.max)
        var val32 = UInt32(0)
        guard krw_read32(server_port, addr, &val32) == KERN_SUCCESS else {
            fatalError("failed krw_read32")
        }
        print("read32 addr:", String(format: "0x%llx", addr) ,"val:", String(format: "0x%x",val32))
        
    } while false
    
    repeat {
        let addr = UInt64.random(in: 0..<UInt64.max)
        var val64 = UInt64(0)
        guard krw_read64(server_port, addr, &val64) == KERN_SUCCESS else {
            fatalError("failed krw_write64")
        }
        print("read64 addr:", String(format: "0x%llx", addr) ,"val:", String(format: "0x%llx",val64))
    } while false
    
    repeat {
        let addr = UInt64.random(in: 0..<UInt64.max)
        let val32 = UInt32.random(in: 0..<UInt32.max)
        print("write32 addr:", String(format: "0x%llx", addr) ,"val:", String(format: "0x%x",val32))
        guard krw_write32(server_port, addr, val32) == KERN_SUCCESS else {
            fatalError("failed krw_write32")
        }
    } while false
    
    repeat {
        let addr = UInt64.random(in: 0..<UInt64.max)
        let val64 = UInt64.random(in: 0..<UInt64.max)
        print("write64 addr:", String(format: "0x%llx", addr) ,"val:", String(format: "0x%llx",val64))
        guard krw_write64(server_port, addr, val64) == KERN_SUCCESS else {
            fatalError("failed krw_write64")
        }
    } while false
    
    sleep(1)
    
}
