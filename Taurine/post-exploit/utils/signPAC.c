//
//  signPAC.c
//  Taurine
//
//  Created by CoolStar on 3/3/21.
//

#include "signPAC.h"
#if __arm64e__
#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <unistd.h>
#include <pthread.h>

//gadget state
// 0 = started
// 1 = waiting for sign / sign completed
// 2 = loaded array to sign
// 3 = exiting

static pthread_t signPac_signThread;

static bool signPac_signThreadRunning = false;
static pthread_mutex_t signPac_signThreadRunningLock = PTHREAD_MUTEX_INITIALIZER;

static volatile mach_port_t signPac_signMachThread = MACH_PORT_NULL;
static volatile unsigned int signPac_gadgetState = 0;
static volatile struct signPac_data *signPac_signPtrs = NULL;
static volatile unsigned int signPac_signPtrsCount = 0;

__attribute__((naked))
static void signPac_signingFunction(unsigned int *gadgetState,
                                    struct signPac_data **signPac_signPtrs,
                             unsigned int *signPac_signPtrCount,
                                    void *alwaysNull3,
                                    void *alwaysNull4,
                                    void *alwaysNull5,
                                    void *alwaysNull6,
                                    void *alwaysNull7){
    //can use x0 -> x7 for arguments
    //can use x9 -> x15 for temporary registers
    //copy x0 -> x2 to x9 -> x11
    
    //can use up to x15 safely without messing with the stack
    
    __asm__ volatile (
                      "mov x9, x0\n" //x0 - x2 get clobbered for sleep
                      "mov x10, x1\n"
                      "mov x11, x2\n"
                      
                      "mov w0, #1\n" //mark as ready
                      "str w0, [x9, #0]\n"
                      
                      "adr x12, #0\n" //x12 is now a repeat pointer
                      "add x12, x12, #0x8\n"
                      
                      "mov x0, #0\n" //load state -- repeat pointer points here
                      "ldr w0, [x9, #0]\n"
                      
                      "mov x1, #3\n" //3 is the maximum
                      "cmp x0, x1\n" //cmp x0 and x1
                      "b.ls #8\n" //go to switch if state is valid
                      "brk #0x69\n" //crash since invalid state
                      
                      "lsl x0, x0, #2\n"
                      "adr x1, #12\n" //get address of this + 12
                      "add x0, x0, x1\n"
                      "br x0\n" //jump to right state
                      
                      "brk #0x42\n" //state 0 (invalid...)
                      "b #24\n" //state 1
                      "b #44\n" //state 2
                      "nop\n" //state 3
                      
                      //state 3 (exit)
                      "mov w0, #0\n" //mark as exited
                      "str w0, [x9, #0]\n"
                      "ret\n"
                      
                      //state 1 (sleep and repeat)
                      "mov x0, #0\n" //MACH_PORT_NULL
                      "mov x1, #2\n" //SWITCH_OPTION_WAIT
                      "mov x2, #100\n" //100 ms
                      "movn x16, #0x3c\n"
                      "svc #0x80\n"
                      "br x12\n"
                      
                      //state 2 sign
                      "ldr x1, [x10, #0]\n" //x1 = signPac_data *data
                      "ldr w2, [x11]\n" //w2 = count
                      
                      "adr x13, #0\n" //x13 is now a repeat pointer for signing
                      "add x13, x13, #12\n"
                      
                      "mov x14, #0\n" //start sign loop
                      
                      "cmp w14, w2\n" //check if we finished signing -- signing repeat pointer points here
                      "b.ne #16\n"
                      
                      "mov x0, #1\n" //set to state 1
                      "str w0, [x9, #0]\n"
                      "br x12\n" //we're done here
                      
                      "lsl x0, x14, #4\n"
                      "add x0, x0, x1\n" //grab the signPac_data struct
                      
                      "ldr x3, [x0, #0]\n" //grab ptr
                      "ldr x4, [x0, #8]\n" //grab context
                      
                      "xpaci x3\n" //strip PAC from ptr
                      "pacia x3, x4\n" //sign pointer
                      "str x3, [x0, #0]\n"
                      
                      "add w14, w14, #1\n"
                      "br x13"
                      );
}

static void *signPac_signingThread(void *arg){
    signPac_signMachThread = mach_thread_self();
    
    signPac_signingFunction((unsigned int *)&signPac_gadgetState,
                            (struct signPac_data **)&signPac_signPtrs,
                            (unsigned int *)&signPac_signPtrsCount,
                            NULL,
                            NULL,
                            NULL,
                            NULL,
                            NULL);
    printf("Gadget Returned OK: %d\n", signPac_gadgetState);
    return NULL;
}

mach_port_t signPAC_initSigningOracle(void){
    pthread_mutex_lock(&signPac_signThreadRunningLock);
    if (signPac_signThreadRunning){
#if DEBUG
        fprintf(stderr, "Can't init signThread twice!!! Terminate it first!\n");
        abort();
#endif
    }
    
    signPac_gadgetState = 0;
    
    pthread_create(&signPac_signThread, NULL, signPac_signingThread, NULL);
    signPac_signThreadRunning = true;
    
    while (signPac_gadgetState != 1){
#if DEBUG
        printf("Waiting for signing gadget..\n");
#endif
        usleep(100 * 1000);
    }
#if DEBUG
    printf("Signing gadget ready...\n");
#endif
    
    pthread_mutex_unlock(&signPac_signThreadRunningLock);
    
    return signPac_signMachThread;
}

void signPac_signPointers(struct signPac_data *data, unsigned int count){
    pthread_mutex_lock(&signPac_signThreadRunningLock);
    if (!signPac_signThreadRunning){
#if DEBUG
        fprintf(stderr, "Need to initialize signThread first!!!\n");
        abort();
#endif
    }
    
    while (signPac_gadgetState != 1) {
#if DEBUG
        printf("Waiting for gadget to idle...\n");
#endif
        usleep(100 * 1000);
    }
    
    signPac_signPtrs = (volatile struct signPac_data *)data;
    signPac_signPtrsCount = count;
    
    signPac_gadgetState = 2;
    
    while (signPac_gadgetState != 1) {
#if DEBUG
        printf("Waiting for gadget to finish...\n");
#endif
        usleep(100 * 1000);
    }
    
    pthread_mutex_unlock(&signPac_signThreadRunningLock);
}

void signPac_destroySigningOracle(void){
    pthread_mutex_lock(&signPac_signThreadRunningLock);
    if (!signPac_signThreadRunning){
#if DEBUG
        fprintf(stderr, "Can't destroy a signThread that doesn't exist!!!\n");
        abort();
#endif
    }
    
    while (signPac_gadgetState != 1) {
#if DEBUG
        printf("Waiting for gadget to idle...\n");
#endif
        usleep(100 * 1000);
    }
    
    signPac_gadgetState = 3;
    
    while (signPac_gadgetState != 0) {
#if DEBUG
        printf("Waiting for gadget to exit...\n");
#endif
        usleep(100 * 1000);
    }
    
    pthread_join(signPac_signThread, NULL);
    
    pthread_mutex_unlock(&signPac_signThreadRunningLock);
}
#else
mach_port_t signPAC_initSigningOracle(void){
    //Nop
    return MACH_PORT_NULL;
}

void signPac_signPointers(struct signPac_data *data, unsigned int count){
    //Nop
}

void signPac_destroySigningOracle(void){
    //Nop
}
#endif
