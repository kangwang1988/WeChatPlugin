//
//  NKWCUtil.h
//  CLPDemo
//
//  Created by KyleWong on 3/28/16.
//  Copyright © 2016 KyleWong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NKWCUtil : NSObject
+ (BOOL)swizzerInstanceMethod:(Class)aClass selector:(SEL)aSelector1 withSelector:(SEL)aSelector2;
+ (BOOL)swizzerClassMethod:(Class)aClass selector:(SEL)aSelector1 withSelector:(SEL)aSelector2;
+ (void)dumpObjcClassesWithLog:(NSMutableString *)aLog;
+ (void)dumpObjcMethods:(Class)clz withLog:(NSMutableString *)aLog;
+ (NSString *)stringByEnsuringNotNil:(NSString *)aStr;
+ (void)log:(NSString *)format, ...;
@end
