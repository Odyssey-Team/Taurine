import Foundation

func getKqueueForPid(pid: pid_t) -> Int32 {
    let kq = kqueue()
    guard kq != -1 else {
        return -1
    }
    
    var ke = kevent()

    ke.ident = UInt(pid)
    ke.filter = Int16(EVFILT_PROC)
    ke.flags = UInt16(EV_ADD)
    ke.fflags = UInt32(NOTE_EXIT_DETAIL)
    ke.data = 0
    ke.udata = nil

    let rc = kevent(kq, &ke, 1, nil, 0, nil)
    guard rc >= 0 else {
        return -1
    }
    return kq
}

var standardError = FileHandle.standardError

#if DEBUG
@_cdecl("swiftDebug_internal")
func swiftDebug(str: UnsafePointer<CChar>?){
    guard let str = str else {
        return
    }
    let swiftString = String(cString: str)
    print(swiftString, to: &standardError)
}
#endif

func startAmfid() {
    let dict = xpc_dictionary_create(nil, nil, 0)
    
    xpc_dictionary_set_uint64(dict, "subsystem", 3)
    xpc_dictionary_set_uint64(dict, "handle", UInt64(HANDLE_SYSTEM))
    xpc_dictionary_set_uint64(dict, "routine", UInt64(ROUTINE_START))
    xpc_dictionary_set_uint64(dict, "type", 1)
    xpc_dictionary_set_string(dict, "name", "com.apple.MobileFileIntegrity")
    
    var outDict: xpc_object_t?
    let rc = xpc_pipe_routine(xpc_bootstrap_pipe(), dict, &outDict)
    if rc == 0,
        let outDict = outDict {
        let rc2 = Int32(xpc_dictionary_get_int64(outDict, "error"))
        if rc2 != 0 {
            return
        }
    } else if rc != 0 {
        return
    }
}

var forgeryStarted = false
func startPACForgery(electra: Electra){
    if !isArm64e(){
        return
    }
    
    if forgeryStarted {
        return
    }
    forgeryStarted = true
    
    let offsets = Offsets.shared
    let our_task_addr = rk64ptr(electra.our_proc + offsets.proc.task)
    let launchd_proc = electra.launchd_proc
    
    let signOracle = signPAC_initSigningOracle()
    var signPac: [signPac_data] = []
    var thread_jop_pid_offset = UInt64(0)
    let pac_testSym = findSymbol("posix_spawn")
    let pac_compare = signPtr(pac_testSym, 0)
    if isArm64e() {
        let our_jop_pid = rk64(our_task_addr + offsets.task.jop_pid)
        
        let launchd_task = rk64ptr(launchd_proc + offsets.proc.task)
        let launchd_jop_pid = rk64(launchd_task + offsets.task.jop_pid)
        
        let signThreadPort = electra.findPort(port: signOracle)
        let signThread = rk64ptr(signThreadPort + offsets.ipc_port.ip_kobject)
        
        for i in 0..<170 {
            let test_rd = rk64(signThread + UInt64(i * 8))
            if test_rd == our_jop_pid {
                thread_jop_pid_offset = UInt64(i * 8)
                break
            }
        }
        
        guard thread_jop_pid_offset != 0 else {
            return
        }
        
        signPac.append(signPac_data(ptr: pac_testSym, context: 0))
        
        signPac_signPointers(&signPac, 1)
        
        wk64(signThread + thread_jop_pid_offset, launchd_jop_pid)
        
        while signPac[0].ptr == pac_compare {
            signPac = []
            signPac.append(signPac_data(ptr: pac_testSym, context: 0))
            
            signPac_signPointers(&signPac, 1)
        }
    }
}

func procName(pid: pid_t) -> String? {
    var path_buffer = [UInt8](repeating: 0, count: 4096)
    let ret = proc_pidpath(pid, &path_buffer, 4096)
    if ret < 0 {
        return nil
    }
    
    let pathStr = String(cString: path_buffer)
    return pathStr
}

let MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT = UInt32(6)
memorystatus_control(MEMORYSTATUS_CMD_SET_JETSAM_TASK_LIMIT, getpid(), 0, nil, 0)

initKernRw(false)
guard isKernRwReady(false) else {
    exit(5)
}

let electra: Electra
if let kernelProcCStr = getenv("kernelProc") {
    let kernelProc = strtoull(kernelProcCStr, nil, 16)
    electra = Electra()
    
    print(String(format: "got kernelProc: 0x%llx", kernelProc), to: &standardError)
} else {
    exit(5)
}

electra.populate_procs() //gets us TF_PLATFORM and launchd_proc
startPACForgery(electra: electra)

while true {
    while queryDaemon(daemonLabel: "com.apple.MobileFileIntegrity") <= 0 {
        startAmfid()
        sleep(1)
    }

    let amfidPid = pid_t(queryDaemon(daemonLabel: "com.apple.MobileFileIntegrity"))
    while procName(pid: amfidPid) != "/usr/libexec/amfid" {
        usleep(1000)
    }

    let amfidtakeover = AmfidTakeover(electra: electra)
    amfidtakeover.takeoverAmfid(amfid_pid: UInt32(amfidPid))
    
    shutdownUnsafeKernRw()

    sleep(1)
    try? String(format: "%d", getpid()).write(toFile: "/var/run/amfidebilitate.pid", atomically: false, encoding: .utf8)
    
    let kq = getKqueueForPid(pid: amfidPid)
    var ke = kevent()
    let rc = kevent(kq, nil, 0, &ke, 1, nil)
    if rc > 0 {
        print("amfid exited. Restarting it...", to: &standardError)
        close(kq)
        
        amfidtakeover.cleanupAmfidTakeover()
        startAmfid()
    }
}
