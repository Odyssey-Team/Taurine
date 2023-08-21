//
//  krw.m
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/08/10.
//

#import <Foundation/Foundation.h>
#include "KernelRwWrapper.h"
#import "libkfd.h"

static uint64_t _kfd = 0;
static uint64_t _self_task = 0;
static uint64_t _self_proc = 0;
static uint64_t _kslide = 0;

static uint64_t kread64(uint64_t where) {
    uint64_t out;
    kread_(_kfd, where, &out, sizeof(uint64_t));
    return out;
}

static void kwrite64(uint64_t where, uint64_t what) {
    u64 _buf[1] = {};
    _buf[0] = what;
    kwrite_((u64)(_kfd), &_buf, where, sizeof(u64));
}

static uint64_t get_selftask(void) {
    return _self_task;
}

static uint64_t get_selfproc(void) {
    return _self_proc;
}

static uint64_t get_kslide(void) {
    return _kslide;
}

static void set_selftask(void) {
    _self_task = ((struct kfd*)_kfd)->info.kernel.current_task;
}

static void set_selfproc(void) {
    _self_proc = ((struct kfd*)_kfd)->info.kernel.current_proc;
}

static void set_kslide(void) {
    _kslide = ((struct kfd*)_kfd)->info.kernel.kernel_slide;
}

static void do_kclose(void)
{
    kclose(_kfd);
}

uint64_t do_kopen(uint64_t puaf_pages, uint64_t puaf_method, uint64_t kread_method, uint64_t kwrite_method)
{
    _kfd = kopen(puaf_pages, puaf_method, kread_method, kwrite_method);//kopen_intermediate(puaf_pages, puaf_method, kread_method, kwrite_method);
    set_selfproc();
    set_selftask();
    set_kslide();
    our_proc_kAddr = get_selfproc();
    usleep(10000);
    initKernRw(get_selftask(), kread64, kwrite64);
    printf("isKernRwReady: %d\n", isKernRwReady());
    if(isKernRwReady()) {
        usleep(10000);
        do_kclose();
    }
    return _kfd;
}

static void do_kread(uint64_t kaddr, void* uaddr, uint64_t size)
{
    kread_(_kfd, kaddr, uaddr, size);
}

static void do_kwrite(void* uaddr, uint64_t kaddr, uint64_t size)
{
    kwrite_(_kfd, uaddr, kaddr, size);
}

static uint64_t get_kernproc(void) {
    return ((struct kfd*)_kfd)->info.kernel.kernel_proc;
}

static uint8_t kread8(uint64_t where) {
    uint8_t out;
    kread_(_kfd, where, &out, sizeof(uint8_t));
    return out;
}
static uint32_t kread16(uint64_t where) {
    uint16_t out;
    kread_(_kfd, where, &out, sizeof(uint16_t));
    return out;
}
static uint32_t kread32(uint64_t where) {
    uint32_t out;
    kread_(_kfd, where, &out, sizeof(uint32_t));
    return out;
}

static void kwrite8(uint64_t where, uint8_t what) {
    uint8_t _buf[8] = {};
    _buf[0] = what;
    _buf[1] = kread8(where+1);
    _buf[2] = kread8(where+2);
    _buf[3] = kread8(where+3);
    _buf[4] = kread8(where+4);
    _buf[5] = kread8(where+5);
    _buf[6] = kread8(where+6);
    _buf[7] = kread8(where+7);
    kwrite_((u64)(_kfd), &_buf, where, sizeof(u64));
}

static void kwrite16(uint64_t where, uint16_t what) {
    u16 _buf[4] = {};
    _buf[0] = what;
    _buf[1] = kread16(where+2);
    _buf[2] = kread16(where+4);
    _buf[3] = kread16(where+6);
    kwrite_((u64)(_kfd), &_buf, where, sizeof(u64));
}

static void kwrite32(uint64_t where, uint32_t what) {
    u32 _buf[2] = {};
    _buf[0] = what;
    _buf[1] = kread32(where+4);
    kwrite_((u64)(_kfd), &_buf, where, sizeof(u64));
}

static void kreadbuf(uint64_t kaddr, void* output, size_t size)
{
    uint64_t endAddr = kaddr + size;
    uint32_t outputOffset = 0;
    unsigned char* outputBytes = (unsigned char*)output;
    
    for(uint64_t curAddr = kaddr; curAddr < endAddr; curAddr += 4)
    {
        uint32_t k = kread32(curAddr);

        unsigned char* kb = (unsigned char*)&k;
        for(int i = 0; i < 4; i++)
        {
            if(outputOffset == size) break;
            outputBytes[outputOffset] = kb[i];
            outputOffset++;
        }
        if(outputOffset == size) break;
    }
}
