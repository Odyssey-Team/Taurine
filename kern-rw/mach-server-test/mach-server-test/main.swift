//
//  main.swift
//  mach-server-test
//
//  Created by CoolStar on 2/27/21.
//

import Foundation

var server_port = mach_port_t(0)
guard mach_port_allocate(mach_task_self_, MACH_PORT_RIGHT_RECEIVE, &server_port) == KERN_SUCCESS else {
    fatalError("Unable to allocate mach port")
}

let krwLock = DispatchSemaphore(value: 1)

let bootstrapErr = bootstrap_register(bootstrap_port, "org.coolstar.krw-server-test", server_port)
if bootstrapErr == KERN_SUCCESS {
  print(String(format: "Registered? %s", mach_error_string(bootstrapErr)))

/*guard mach_port_insert_right(mach_task_self_, server_port, server_port, mach_msg_type_name_t(MACH_MSG_TYPE_MAKE_SEND)) == KERN_SUCCESS else {
    fatalError("Unable to make send right")
}

let registerErr = mach_ports_register(mach_task_self_, &server_port, 1)
if registerErr == KERN_SUCCESS {
    print(String(format: "Registered? %s", mach_error_string(registerErr)))*/
    print("PID:",getpid())
    
    let queue = DispatchQueue.global(qos: .userInteractive)
    let server = DispatchSource.makeMachReceiveSource(port: server_port, queue: queue)
    server.setEventHandler {
        krwLock.wait()
        defer { krwLock.signal() }
        dispatch_mig_server(server as? DispatchSource, MemoryLayout<__RequestUnion__krw_kernrw_daemon_subsystem>.size, kernrw_daemon_server)
    }
    server.resume()
}

dispatchMain()
