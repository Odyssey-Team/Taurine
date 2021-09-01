//
//  KernelRwWrapper.h
//  Taurine
//
//  Created by tihmstar on 27.02.21.
//

#ifndef KernelRwWrapper_h
#define KernelRwWrapper_h

#include <stdint.h>
#include <stdbool.h>
#include <mach/mach.h>
#include <unistd.h>

#ifdef __cplusplus
extern "C" {
#endif
extern uint64_t our_proc_kAddr;

void setHandoffSourcePid(int pid);

bool isKernRwReady(bool forceNoHSP14);

void initKernRw(bool forceNoHSP14);

void shutdownUnsafeKernRw(void);

void handoffUnsafeKernRw(pid_t spawnedPID, const char *processPath);

uint64_t rk64(uint64_t addr);
uint32_t rk32(uint64_t addr);
void wk32(uint64_t addr, uint32_t val);
void wk64(uint64_t addr, uint64_t val);
size_t kread(uint64_t addr, void *p, size_t sz);

bool getTaskSelfAddr(uint64_t *addr);

#ifdef __cplusplus
}
#endif

#endif /* KernelRwWrapper_h */

