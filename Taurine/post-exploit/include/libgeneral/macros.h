//
//  macros.h
//  libgeneral
//
//  Created by tihmstar on 03.05.19.
//  Copyright © 2019 tihmstar. All rights reserved.
//

#ifndef macros_h
#define macros_h

#include <assert.h>

#ifdef DEBUG //versioning
#    ifdef HAVE_CONFIG_H
#        include <config.h>
#    endif
#	ifndef VERSION_COMMIT_COUNT
#   	define VERSION_COMMIT_COUNT "Debug"
#	endif
#	ifndef VERSION_COMMIT_SHA
#   	define VERSION_COMMIT_SHA "Build: " __DATE__ " " __TIME__
#	endif
#else
#    ifdef HAVE_CONFIG_H
#        include <config.h>
#   endif
#endif

#ifndef PACKAGE_NAME
#define PACKAGE_NAME "PACKAGE_NAME_not_set"
#endif

#ifndef VERSION_MAJOR
#define VERSION_MAJOR "0"
#endif

#define VERSION_STRING PACKAGE_NAME " version: " VERSION_MAJOR "." VERSION_COMMIT_COUNT "-" VERSION_COMMIT_SHA


// ---- functions ----

#if DEBUG
#ifdef __cplusplus
extern "C" {
#endif
    extern void swiftDebug(const char *format, ...);
#ifdef __cplusplus
}
#endif

#define debug swiftDebug
#else
#define debug(x, ...)
#endif

#define safeFree(ptr) ({if (ptr) {free(ptr); ptr=NULL;}})
#define safeFreeCustom(ptr,func) ({if (ptr) {func(ptr); ptr=NULL;}})
#define safeFreeMachCustom(ptr,func) ({if (ptr) {func(ptr); ptr=MACH_PORT_NULL;}})
#define safeFreeConst(ptr) ({if(ptr){void *fbuf = (void*)ptr;ptr = NULL; free(fbuf);}})

#ifdef __cplusplus
#   define safeDelete(ptr) ({if (ptr) {delete ptr; ptr=NULL;}})
#endif

#ifdef __cplusplus
#include <functional>
#   ifndef NO_EXCEPT_ASSURE
#       define EXCEPT_ASSURE
#   endif
#endif


#ifdef EXCEPT_ASSURE
#include "exception.hpp"
//assure cpp
#   define retassure(cond, errstr ...) do{ if ((cond) == 0) throw tihmstar::EXPECTIONNAME(VERSION_COMMIT_COUNT, VERSION_COMMIT_SHA, __LINE__,__FILE__,errstr); } while(0)


// //more cpp assure
#   ifndef EXPECTIONNAME
#       define EXPECTIONNAME exception
#   endif


class guard{
    std::function<void()> _f;
public:
    guard(std::function<void()> cleanup) : _f(cleanup) {}
    guard(const guard&) = delete; //delete copy constructor
    guard(guard &&o) = delete; //move constructor
    
    ~guard(){_f();}
};
#define cleanup(f) guard _cleanup(f);

#else
//assure c
#   define assure(a) cassure(a)
#   define retassure(cond, errstr ...) cretassure(cond, errstr)
#   define reterror(estr ...) creterror(estr)

#endif

#endif /* macros_h */
