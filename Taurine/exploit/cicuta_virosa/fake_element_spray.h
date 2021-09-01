#pragma once
#include <stdint.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <errno.h>

#define FAKE_ELEMENT_MAGIC_BASE 0x4242424200000000
#define IPV6_USE_MIN_MTU 42
#define IPV6_PKTINFO 46

void init_fake_element_spray(uint32_t e_size, uint32_t count);
void fake_element_spray_set_e_size(uint32_t e_size);
void fake_element_spray_set_pktopts(uint64_t pktopts);
void perform_fake_element_spray(void);
void release_all_fake_element_spray(void);
int perform_fake_element_spray_cleanup(uint64_t v1, uint64_t v2);
void release_fake_element_spray_at(uint32_t index);
void shutdown_fake_element_spray(void);
void set_fake_queue_chain_for_fake_element_spray(uint64_t next, uint64_t prev);
