//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <mach/mach.h>
#import "krw_daemonUser.h"

extern kern_return_t
bootstrap_register(mach_port_t bp, const char *service_name, mach_port_t sp);

extern kern_return_t
bootstrap_look_up(mach_port_t bp, const char *service_name, mach_port_t *sp);
