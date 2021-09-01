#ifndef PATCHFINDER64_H_
#define PATCHFINDER64_H_

int init_kernel(uint64_t kernel_base, const char *filename);
void term_kernel(void);

uint64_t find_cs_blob_generation_count();
uint64_t find_vm_map_remap();
uint64_t find_add_x0_x0_0x40_ret(void);
uint64_t find_bcopy(void);

#endif
