//
//  KernelRwWrapper.cc
//  Taurine
//
//  Created by CoolStar on 3/6/21
//

#include "KernelRwWrapper.h"
#include <mach/mach.h>
#include <libgeneral/macros.h>
#include "KernelRW.hpp"
#include "krw_daemonUser.h"
#include <sys/param.h>

static KernelRW *krw = NULL;
static mach_port_t krw_launchdPort = MACH_PORT_NULL;

#define PROC_PIDPATHINFO_SIZE  (MAXPATHLEN)
extern "C" int proc_pidpath(int pid, void * buffer, uint32_t  buffersize);

extern "C" bool isKernRwReady(bool forceNoHSP14){
    if (forceNoHSP14){
        return krw != NULL;
    }
    return (krw != NULL || MACH_PORT_VALID(krw_launchdPort));
}

extern "C" void initKernRw(bool forceNoHSP14){
    mach_error_t err = host_get_special_port(mach_host_self(), HOST_LOCAL_NODE, 14, &krw_launchdPort);
    if (!forceNoHSP14 && err == KERN_SUCCESS && MACH_PORT_VALID(krw_launchdPort)){
        debug("Using kernel r/w through launchd. Port: %x", krw_launchdPort);
        return;
    }
    try {
        debug("Failed to get kernel r/w through launchd. Trying fallback...");
        mach_port_t fakethread = 0;
        mach_port_t transmissionPort = 0;
        cleanup([&]{
            if (transmissionPort) {
                mach_port_destroy(mach_task_self(), transmissionPort); transmissionPort = MACH_PORT_NULL;
            }
            if (fakethread) {
                thread_terminate(fakethread);
                mach_port_destroy(mach_task_self(), fakethread); fakethread = MACH_PORT_NULL;
            }
        });
        kern_return_t kr = 0;
        
        retassure(!(kr = thread_create(mach_task_self(), &fakethread)), "Failed to create fake thread");
        
        //set known state
        retassure(!(kr = thread_set_exception_ports(fakethread, EXC_BREAKPOINT, MACH_PORT_NULL, EXCEPTION_DEFAULT, ARM_THREAD_STATE64)), "Failed to set exception port to MACH_PORT_NULL");

        //set magic state
        {
            arm_thread_state64_t state = {};
            mach_msg_type_number_t statecnt = ARM_THREAD_STATE64_COUNT;
            memset(&state, 0x41, sizeof(state));
            retassure(!(kr = thread_set_state(fakethread, ARM_THREAD_STATE64, (thread_state_t)&state, ARM_THREAD_STATE64_COUNT)), "Failed to set fake thread state");
        }

        //get transmission port
        {
            exception_mask_t masks[EXC_TYPES_COUNT] = {};
            mach_msg_type_number_t masksCnt = 0;
            mach_port_t eports[EXC_TYPES_COUNT] = {};
            exception_behavior_t behaviors[EXC_TYPES_COUNT] = {};
            thread_state_flavor_t flavors[EXC_TYPES_COUNT] = {};
            do {
                retassure(!(kr = thread_get_exception_ports(fakethread, EXC_BREAKPOINT, masks, &masksCnt, eports, behaviors, flavors)), "Failed to get thread exception port");
                transmissionPort = eports[0];
            }while(transmissionPort == MACH_PORT_NULL);
        }
        
        krw = new KernelRW();
        
        krw->handoffPrimitivePatching(transmissionPort);
        debug("KernelRw handoff done!");
    } catch (tihmstar::exception exception){
#if DEBUG
        exception.dump();
#endif
    }
}

extern "C" void shutdownUnsafeKernRw(void){
    delete krw;
    krw = NULL;
    //Don't need to shut down launchd port as that is safe
}

extern "C" void handoffUnsafeKernRw(pid_t spawnedPID, const char *processPath){
    if (!krw){
        debug("Not using fallback kernel r/w. Not handing off");
        return;
    }
    try {
        debug("handoffKernRw");

        mach_port_t spawnedTaskPort = MACH_PORT_NULL;
        mach_port_t exceptionPort = MACH_PORT_NULL;
        mach_port_t trasmissionPort = MACH_PORT_NULL;
        cleanup([&]{
            if (trasmissionPort) {
                mach_port_destroy(mach_task_self(), trasmissionPort); trasmissionPort = MACH_PORT_NULL;
            }
            if (exceptionPort) {
                mach_port_destroy(mach_task_self(), exceptionPort); exceptionPort = MACH_PORT_NULL;
            }
            if (spawnedTaskPort) {
                mach_port_destroy(mach_task_self(), spawnedTaskPort); spawnedTaskPort = MACH_PORT_NULL;
            }
        });
        kern_return_t kret = KERN_SUCCESS;
        exception_mask_t masks[EXC_TYPES_COUNT] = {};
        mach_msg_type_number_t masksCnt = 0;
        mach_port_t eports[EXC_TYPES_COUNT] = {};
        exception_behavior_t behaviors[EXC_TYPES_COUNT] = {};
        thread_state_flavor_t flavors[EXC_TYPES_COUNT] = {};
        
        if (processPath) {
            for (int i=0; i<200; i++) {
                char path[PROC_PIDPATHINFO_SIZE+1] = {};
                if (int pathLen = proc_pidpath(spawnedPID, path, sizeof(path))){
                    if (strncmp(path, processPath, pathLen) == 0) {
                        debug("Got process! '%s'",path);
                        break;
                    }else{
                        debug("Got process '%s' but need '%s', waiting...",path,processPath);
                    }
                }else{
                    debug("proc_pidpath failed with error=%d (%s)",errno,strerror(errno));
                }
                usleep(1000);
            }
        }
        
        for (int i=0; i<200; i++) {
            if (!(kret = task_for_pid(mach_task_self(), spawnedPID, &spawnedTaskPort))) break;
            usleep(1000);
        }
        retassure(!kret, "Failed to get task_for_pid(%d) with error=0x%08x",spawnedPID,kret);
        debug("got task_for_pid");

        
        retassure(!(kret = task_get_exception_ports(spawnedTaskPort, EXC_BREAKPOINT, masks, &masksCnt, eports, behaviors, flavors)), "Failed to get old exception port");
        exceptionPort = eports[0];
        
        retassure(!(kret = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &trasmissionPort)),"Failed to alloc trasmissionPort");
        retassure(!(kret = mach_port_insert_right(mach_task_self(), trasmissionPort, trasmissionPort, MACH_MSG_TYPE_MAKE_SEND)),"Failed to insert send right to trasmissionPort");

        //find takeThread
        {
            bool haveSetPort = false;
            while (!haveSetPort) {
                thread_act_array_t threads = NULL;
                cleanup([&]{
                    if (threads) {
                        _kernelrpc_mach_vm_deallocate_trap(mach_task_self(), (mach_vm_address_t)threads, PAGE_SIZE); threads = NULL;
                    }
                });
                mach_msg_type_number_t threadsCount = {};
                for (int i=0; i<200; i++) {
                    if (!(kret = task_threads(spawnedTaskPort, &threads, &threadsCount))) break;
                    usleep(1000);
                }
                retassure(!kret, "Failed to get remote thread list");

                for (int i=0; i<threadsCount; i++) {
                    arm_thread_state64_t state = {};
                    mach_msg_type_number_t statecnt = ARM_THREAD_STATE64_COUNT;
                    retassure(!(kret = thread_get_state(threads[i], ARM_THREAD_STATE64, (thread_state_t)&state, &statecnt)), "Failed to get remote thread state");
                    if (state.__x[0] == 0x4141414141414141){
                        haveSetPort = true;
                        retassure(!(kret = thread_set_exception_ports(threads[i], EXC_BREAKPOINT, trasmissionPort, EXCEPTION_DEFAULT, ARM_THREAD_STATE64)), "Failed to set exception port");
                        break;
                    }
                }
                if (!haveSetPort) {
                    usleep(1000);
                }
            }
        }
        
        {
            uint64_t spawnedTaskAddr = krw->getKobjAddrForPort(spawnedTaskPort);
            debug("spawnedTaskAddr=0x%016llx",spawnedTaskAddr);
            krw->doRemotePrimitivePatching(trasmissionPort, spawnedTaskAddr);
        }
        debug("done kernel rw handoff");
    } catch (tihmstar::exception ex){
#if DEBUG
        ex.dump();
#endif
    }
}

extern "C" uint64_t rk64(uint64_t addr){
    if (krw){
        return krw->kread64(addr);
    } else if (MACH_PORT_VALID(krw_launchdPort)){
        uint64_t val64 = 0;
        kern_return_t ret = krw_read64(krw_launchdPort, addr, &val64);
        if (ret == KERN_SUCCESS){
            return val64;
        } else {
            debug("[e] error reading kernel @%llu", addr);
        }
    }
    return 0;
}

extern "C" uint32_t rk32(uint64_t addr){
    if (krw){
        return krw->kread32(addr);
    } else if (MACH_PORT_VALID(krw_launchdPort)){
        uint32_t val32 = 0;
        kern_return_t ret = krw_read32(krw_launchdPort, addr, &val32);
        if (ret == KERN_SUCCESS){
            return val32;
        } else {
            debug("[e] error reading kernel @0x%llu", addr);
        }
    }
    return 0;
}

extern "C" void wk64(uint64_t addr, uint64_t val){
    if (krw){
        krw->kwrite64(addr, val);
    } else if (MACH_PORT_VALID(krw_launchdPort)){
        kern_return_t ret = krw_write64(krw_launchdPort, addr, val);
        if (ret != KERN_SUCCESS){
            debug("[e] error writing kernel @0x%llu", addr);
        }
    }
}

extern "C" void wk32(uint64_t addr, uint32_t val){
    if (krw){
        krw->kwrite32(addr, val);
    } else if (MACH_PORT_VALID(krw_launchdPort)){
        kern_return_t ret = krw_write32(krw_launchdPort, addr, val);
        if (ret != KERN_SUCCESS){
            debug("[e] error writing kernel @0x%llu", addr);
        }
    }
}

extern "C" size_t kread(uint64_t addr, void *p, size_t size){
    if (krw){
        return krw->kreadbuf(addr, p, size);
    } else if (MACH_PORT_VALID(krw_launchdPort)){
        size_t remainder = size % 4;
        if (remainder == 0)
            remainder = 4;
        size_t tmpSz = size + (4 - remainder);
        if (size == 0)
            tmpSz = 0;
        
        uint32_t *dstBuf = (uint32_t *)p;
        
        size_t alignedSize = (size & ~0b11);
        for (int i = 0; i < alignedSize; i+=4){
            dstBuf[i/4] = rk32(addr + i);
        }
        if (size > alignedSize) {
            uint32_t r = rk32(addr + alignedSize);
            memcpy(((uint8_t*)p)+alignedSize, &r, size-alignedSize);
        }
    }
    return 0;
}

extern "C" bool getTaskSelfAddr(uint64_t *addr){
    if (!addr){
        return false;
    }
    if (krw){
         *addr = krw->getTaskSelfAddr();
         return true;
    } else if (MACH_PORT_VALID(krw_launchdPort)){
        kern_return_t ret = krw_taskSelfAddr(krw_launchdPort, addr);
        if (ret != KERN_SUCCESS){
            debug("[e] error getting task self addr %s (0x%x)", mach_error_string(ret), ret);
            return false;
        }
        return true;
    }
    return false;
    return false;
}
