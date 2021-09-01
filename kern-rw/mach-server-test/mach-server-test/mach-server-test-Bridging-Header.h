//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <mach/mach.h>
#import <dispatch/dispatch.h>
#import "krw_daemonServer.h"

typedef boolean_t (*dispatch_mig_callback_t)(mach_msg_header_t *message, mach_msg_header_t *reply);
mach_msg_return_t dispatch_mig_server(dispatch_source_t ds, size_t maxmsgsz, dispatch_mig_callback_t callback);

extern kern_return_t
bootstrap_register(mach_port_t bp, const char *service_name, mach_port_t sp);

extern kern_return_t
bootstrap_look_up(mach_port_t bp, const char *service_name, mach_port_t *sp);
