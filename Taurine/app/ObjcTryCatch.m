//
//  ObjcTryCatch.m
//  Odyssey
//
//  Created by CoolStar on 7/1/20.
//  Copyright © 2020 coolstar. All rights reserved.
//

#import <Foundation/Foundation.h>

void ObjcTryCatch(void (^tryBlock)(void)){
    @try {
        tryBlock();
    }
    @catch (NSException *exception){
        
    }
    @finally {
        
    }
}
