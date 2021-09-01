#pragma once
#include <mach/mach.h>
#define USER_DATA_ELEMENT_SIZEOF 32
#define DATA_VOUCHER_CONTENT_SIZE (168 - USER_DATA_ELEMENT_SIZEOF)

kern_return_t create_voucher(mach_voucher_attr_recipe_t recipe, ipc_voucher_t* voucher);
kern_return_t create_user_data_voucher_fast(uint64_t id, ipc_voucher_t* voucher);
mach_voucher_attr_recipe_data_t* create_recipe_for_user_data_voucher(uint64_t id);
kern_return_t destroy_voucher(ipc_voucher_t voucher);
