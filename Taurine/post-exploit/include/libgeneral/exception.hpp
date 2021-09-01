//
//  exception.hpp
//  libgeneral
//
//  Created by tihmstar on 09.03.18.
//  Copyright © 2018 tihmstar. All rights reserved.
//

#ifndef exception_hpp
#define exception_hpp

#include <string>

namespace tihmstar {
    class exception : public std::exception{
        const char *_commit_count_str;
        const char *_commit_sha_str;
        int _line;
        std::string _filename;
        char *_err;
    public:
        exception(const char *commit_count_str, const char *commit_sha_str, int line, const char *filename, const char *err ...);
        exception(const exception &cpy); //copy constructor
        virtual ~exception() override;
        
        /*
         -first lowest two bytes of code is sourcecode line
         -next two bytes is strlen of filename in which error happened
         */
        int code() const;
        
#if DEBUG
        virtual void dump() const;
#endif
    };
};

#endif /* exception_hpp */
