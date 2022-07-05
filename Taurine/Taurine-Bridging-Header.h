//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#include <stdint.h>
#import <mach/mach.h>
#import <sys/mount.h>
#import <sys/stat.h>
#import <sys/snapshot.h>
#include "cutils.h"
#include "signPAC.h"
#include "iokit.h"
#import "cicuta_virosa.h"
#import <xpc/xpc.h>
#include "jailbreak_daemonUser.h"

#define PROC_PIDPATHINFO_SIZE  (MAXPATHLEN)
int proc_pidpath(int pid, void * buffer, uint32_t  buffersize);

extern kern_return_t
bootstrap_look_up(mach_port_t bp, const char *service_name, mach_port_t *sp);

int csops(pid_t pid, uint32_t op, uint32_t *addr, uint32_t opt);

void ObjcTryCatch(void (^tryBlock)(void));

kern_return_t IORegistryEntrySetCFProperty(io_registry_entry_t, CFStringRef, CFTypeRef);

struct hfs_mount_args {
    char    *fspec;            /* block special device to mount */
    uid_t    hfs_uid;        /* uid that owns hfs files (standard HFS only) */
    gid_t    hfs_gid;        /* gid that owns hfs files (standard HFS only) */
    mode_t    hfs_mask;        /* mask to be applied for hfs perms  (standard HFS only) */
    u_int32_t hfs_encoding;    /* encoding for this volume (standard HFS only) */
    struct    timezone hfs_timezone;    /* user time zone info (standard HFS only) */
    int        flags;            /* mounting flags, see below */
    int     journal_tbuffer_size;   /* size in bytes of the journal transaction buffer */
    int        journal_flags;          /* flags to pass to journal_open/create */
    int        journal_disable;        /* don't use journaling (potentially dangerous) */
};

#include "KernelRwWrapper.h"

kern_return_t mach_vm_write(vm_map_t target_task, mach_vm_address_t address, const uint8_t *data, mach_msg_type_number_t dataCnt);
kern_return_t mach_vm_region(vm_map_t, mach_vm_address_t *, mach_vm_size_t *, vm_region_flavor_t, vm_region_info_t, mach_msg_type_number_t *, mach_port_t *);
kern_return_t mach_vm_read_overwrite(vm_map_t target_task, mach_vm_address_t address, mach_vm_size_t size, uint8_t *data, mach_vm_size_t *outsize);

#pragma pack(4)
typedef struct {
  mach_msg_header_t Head;
  mach_msg_body_t msgh_body;
  mach_msg_port_descriptor_t thread;
  mach_msg_port_descriptor_t task;
  NDR_record_t NDR;
} exception_raise_request; // the bits we need at least

typedef struct {
  mach_msg_header_t Head;
  NDR_record_t NDR;
  kern_return_t RetCode;
} exception_raise_reply;
#pragma pack()

//launchd functions (Thanks J)
extern int xpc_pipe_routine (xpc_object_t xpc_pipe, xpc_object_t inDict, xpc_object_t *reply);
extern char *xpc_strerror (int);

#define HANDLE_SYSTEM 0

// Some of the routine #s launchd recognizes. There are quite a few subsystems

#define ROUTINE_SUBMIT 100
#define ROUTINE_LOAD 0x320    // 800
#define ROUTINE_ENABLE 0x328
#define ROUTINE_DISABLE 0x329

#define ROUTINE_START        0x32d    // 813
#define ROUTINE_STOP        0x32e    // 814
#define ROUTINE_LIST        0x32f    // 815
