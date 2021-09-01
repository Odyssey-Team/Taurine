#import <mach/mach.h>
#import <sys/event.h>
#import <xpc/xpc.h>
#import "cutils.h"
#import "signPAC.h"
#import "KernelRwWrapper.h"

int csops(pid_t pid, unsigned int ops, uint32_t *useraddr, size_t usersize);

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

extern mach_port_t tfpzero;

kern_return_t mach_vm_allocate(vm_map_t target, mach_vm_address_t *address, mach_vm_size_t size, int flags);
kern_return_t mach_vm_write(vm_map_t target_task, mach_vm_address_t address, const uint8_t *data, mach_msg_type_number_t dataCnt);
kern_return_t mach_vm_region(vm_map_t, mach_vm_address_t *, mach_vm_size_t *, vm_region_flavor_t, vm_region_info_t, mach_msg_type_number_t *, mach_port_t *);
kern_return_t mach_vm_read_overwrite(vm_map_t target_task, mach_vm_address_t address, mach_vm_size_t size, uint8_t *data, mach_vm_size_t *outsize);

int memorystatus_control(uint32_t comand, pid_t pid, uint32_t flags, void *buffer, size_t buffersize);

//launchd functions (Thanks J)
extern int xpc_pipe_routine (xpc_object_t xpc_pipe, xpc_object_t inDict, xpc_object_t *reply);
extern char *xpc_strerror (int);

#define HANDLE_SYSTEM 0

// Some of the routine #s launchd recognizes. There are quite a few subsystems

#define ROUTINE_SUBMIT 100
#define ROUTINE_ENABLE 0x328
#define ROUTINE_DISABLE 0x329

#define ROUTINE_START        0x32d    // 813
#define ROUTINE_STOP        0x32e    // 814
#define ROUTINE_LIST        0x32f    // 815

#define PROC_PIDPATHINFO_MAXSIZE  (1024)
int proc_pidpath(pid_t pid, void *buffer, uint32_t buffersize);