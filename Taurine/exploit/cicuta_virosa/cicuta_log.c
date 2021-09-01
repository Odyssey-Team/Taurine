#include "cicuta_log.h"
#include <stdlib.h>
#include <stdarg.h>

void cicuta_log(const char* format, ...)
{
    char *msg = NULL;
    va_list ap;
    va_start(ap, format);
    vasprintf(&msg, format, ap);
    printf("%s\n", msg);
    va_end(ap);
    free(msg);
}
