#include <sys/resource.h>
#include "descriptors_utils.h"

void increase_limits(uint32_t limit)
{
    struct rlimit lim = {0};
    getrlimit(RLIMIT_NOFILE, &lim);
    lim.rlim_cur = limit;
    setrlimit(RLIMIT_NOFILE, &lim);
}
