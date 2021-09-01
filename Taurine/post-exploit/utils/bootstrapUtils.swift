//
//  bootstrapUtils.swift
//  Taurine
//
//  Created by CoolStar on 5/13/20.
//  Copyright © 2020 coolstar. All rights reserved.
//

import Foundation

func runCmdRaw(cmd: String, args: [String], preflight: Bool = false) -> Int32 {
    let argv: [UnsafeMutablePointer<CChar>?] = args.map { $0.withCString(strdup) }
    defer { for case let arg? in argv { free(arg) } }
    
    let envs = preflight ? ["PREFLIGHT=1"] : [""]
    
    let envp: [UnsafeMutablePointer<CChar>?] = envs.map { $0.withCString(strdup) }
    defer { for case let env? in envp { free(env) } }
    
    var pid = pid_t(0)
    var status = posix_spawn(&pid, cmd.cString(using: .utf8), nil, nil, argv + [nil], envp + [nil])
    if status == 0 {
        if waitpid(pid, &status, 0) == -1 {
            perror("waitpid")
        }
    } else {
        print("posix_spawn:", status)
    }
    return status
}

func testUnsandboxedExec() -> Int32 {
    runCmdRaw(cmd: "/taurine/jbexec", args: ["helloWorld"])
}

func runUnsandboxed(cmd: String) -> Int32 {
    runCmdRaw(cmd: "/taurine/jbexec", args: ["/bin/sh", "-c", cmd])
}

func preflightExecutable(exec: String) -> Int32 {
    runCmdRaw(cmd: "/taurine/jbexec", args: [exec], preflight: true)
}

func prepareUserspaceReboot(allProc: UInt64, kernelProc: UInt64, genCountAddr: UInt64) -> Int32 {
    unlink("/var/run/launchd-handoff.pid")
    
    let allProcStr = String(format: "0x%llx", allProc)
    let kernelProcStr = String(format: "0x%llx", kernelProc)
    let genCountAddrStr = String(format: "0x%llx", genCountAddr)
    
    let args = ["/taurine/launchjailbreak", "/taurine/jailbreakd"]
    let argv: [UnsafeMutablePointer<CChar>?] = args.map { $0.withCString(strdup) }
    defer { for case let arg? in argv { free(arg) } }
    
    let envs = ["allProc=\(allProcStr)","kernelProc=\(kernelProcStr)", "genCountAddr=\(genCountAddrStr)", "BOOTSTRAPREQUIRED=1", "SPLASH=2"]
    let envp: [UnsafeMutablePointer<CChar>?] = envs.map { $0.withCString(strdup) }
    defer { for case let env? in envp { free(env) } }
    
    var pid = pid_t(0)
    var status = posix_spawn(&pid, "/taurine/launchjailbreak", nil, nil, argv + [nil], envp + [nil])
    if status == 0 {
        if waitpid(pid, &status, 0) == -1 {
            perror("waitpid")
        }
    } else {
        print("posix_spawn:", status)
    }
    return status
}
