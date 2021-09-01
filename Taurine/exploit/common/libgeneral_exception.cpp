
#include <libgeneral/macros.h>
#include <libgeneral/exception.hpp>
#include <string.h>
#include <stdarg.h>

using namespace tihmstar;

exception::exception(const char *commit_count_str, const char *commit_sha_str, int line, const char *filename, const char *err ...) :
    _commit_count_str(commit_count_str),
    _commit_sha_str(commit_sha_str),
    _line(line),
    _filename(filename),
    _err(NULL)
{
    va_list ap = {};
    va_start(ap, err);
    vasprintf(&_err, err, ap);
    va_end(ap);
};

exception::exception(const exception &e) :    //copy constructor
_commit_count_str(e._commit_count_str),
_commit_sha_str(e._commit_sha_str),
_line(e._line),
_filename(e._filename),
_err(NULL)
{
    if (e._err) {
        size_t len = strlen(e._err);
        _err = (char*)malloc(len+1);
        strncpy(_err, e._err, len);
        _err[len] = '\0';
    }
}

exception::~exception(){
    safeFree(_err);
}

int exception::code() const{
    return (_line << 16) | (int)(_filename.size());
}

#if DEBUG
void exception::dump() const{
    debug("[exception]:");
    debug("what=%s",_err);
    debug("code=%d",code());
    debug("line=%d",_line);
    debug("file=%s",_filename.c_str());
    debug("commit count=%s:",_commit_count_str);
    debug("commit sha  =%s:",_commit_sha_str);
}
#endif
