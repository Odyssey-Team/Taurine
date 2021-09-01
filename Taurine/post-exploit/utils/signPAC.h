//
//  signPAC.h
//  Taurine
//
//  Created by CoolStar on 3/3/21.
//

#import <mach/mach.h>

#ifndef signPAC_h
#define signPAC_h

struct signPac_data {
    uint64_t ptr;
    uint64_t context;
};

mach_port_t signPAC_initSigningOracle(void);
void signPac_signPointers(struct signPac_data *data, unsigned int count);
void signPac_destroySigningOracle(void);

#endif /* signPAC_h */
