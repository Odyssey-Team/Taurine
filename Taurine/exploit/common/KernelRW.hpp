//
//  KernelRW.hpp
//  Taurine
//
//  Created by tihmstar on 27.02.21.
//

#ifndef KernelRW_hpp
#define KernelRW_hpp

#include <stdint.h>
#include <mach/mach.h>
#include <vector>
#include <functional>
#include <mutex>

class KernelRW{
public:
    struct patch{
        uint64_t where;
        uint64_t what;
    };
private:
    uint64_t _task_self_addr;
    mach_port_t _IOSurfaceRoot;
    mach_port_t _IOSurfaceRootUserClient;
    mach_port_t _context_read_port;
    mach_port_t _context_write_port;

    uint32_t _IOSurface_id_write;

    uint64_t _kernel_base_addr;
    uint64_t _kernel_proc_addr;
    uint64_t _all_proc_addr;
    uint64_t _context_write_context_addr;
    patch _backup;

    std::mutex _rw_lock;
public:
    KernelRW();
    ~KernelRW();

    patch getPrimitivepatches(std::function<uint64_t(uint64_t)> kread64, uint64_t machTaskSelfAddr); //no kernel RW
    void handoffPrimitivePatching(mach_port_t transmissionPort); //no kernel RW

    void doRemotePrimitivePatching(mach_port_t transmissionPort, uint64_t dstTaskAddr); //requires kernel RW
    
#ifdef MAINAPP
    void setOffsets(uint64_t kernelBase, uint64_t kernProc, uint64_t allProc);
#endif

#ifdef PSPAWN
    void getOffsets(uint64_t *kernelBase, uint64_t *kernProc, uint64_t *allProc);
#endif

    uint32_t kread32(uint64_t where);
    uint64_t kread64(uint64_t where);
    void kwrite32(uint64_t where, uint32_t what);
    void kwrite64(uint64_t where, uint64_t what);

    size_t kreadbuf(uint64_t where, void *p, size_t size);
    size_t kwritebuf(uint64_t where, const void *p, size_t size);

    unsigned long kstrlen(uint64_t where);

    uint64_t getKobjAddrForPort(mach_port_t port);
    
    uint64_t getTaskSelfAddr(void);
};

#endif /* KernelRW_hpp */
