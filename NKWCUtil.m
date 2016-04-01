//
//  NKWCUtil.m
//  CLPDemo
//
//  Created by KyleWong on 3/28/16.
//  Copyright © 2016 KyleWong. All rights reserved.
//

#import "NKWCUtil.h"
#import <objc/runtime.h>

@implementation NKWCUtil
+ (BOOL)swizzerInstanceMethod:(Class)aClass selector:(SEL)aSelector1 withSelector:(SEL)aSelector2{
    Method m1 = class_getInstanceMethod(aClass, aSelector1);
    IMP imp1 = class_getMethodImplementation(aClass, aSelector1);
    const char * typeEncode1 = method_getTypeEncoding(m1);
    
    Method m2 = class_getInstanceMethod(aClass, aSelector2);
    IMP imp2 = class_getMethodImplementation(aClass, aSelector2);
    const char * typeEncode2 = method_getTypeEncoding(m2);
    if(class_addMethod(aClass, aSelector1, imp2, typeEncode2)){
        class_replaceMethod(aClass, aSelector2, imp1, typeEncode1);
    }
    else{
        method_exchangeImplementations(m1, m2);
    }
    return YES;
}

+ (BOOL)swizzerClassMethod:(Class)aClass selector:(SEL)aSelector1 withSelector:(SEL)aSelector2{
    Method m1 = class_getClassMethod(aClass, aSelector1);
    IMP imp1 = class_getMethodImplementation(aClass, aSelector1);
    const char * typeEncode1 = method_getTypeEncoding(m1);
    
    Method m2 = class_getClassMethod(aClass, aSelector2);
    IMP imp2 = class_getMethodImplementation(aClass, aSelector2);
    const char * typeEncode2 = method_getTypeEncoding(m2);
    Class cls = object_getClass(aClass);
    if(class_addMethod(cls, aSelector1, imp2, typeEncode2)){
        class_replaceMethod(cls, aSelector2, imp1, typeEncode1);
    }
    else{
        method_exchangeImplementations(m1, m2);
    }
    return YES;
}

+ (void)dumpObjcClassesWithLog:(NSMutableString *)aLog{
    int numClasses;
    Class * classes = NULL;
    
    classes = NULL;
    numClasses = objc_getClassList(NULL, 0);
    
    if (numClasses > 0 )
    {
        classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        for (int i = 0; i < numClasses; i++) {
            Class c = classes[i];
            [aLog appendString:[NSString stringWithFormat:@"@class:%s\n",class_getName(c)]];
            [self dumpObjcMethods:c withLog:aLog];
        }
        free(classes);
    }
}

+ (void)dumpObjcMethods:(Class)clz withLog:(NSMutableString *)aLog{
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(clz, &methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        [aLog appendString:[NSString stringWithFormat:@"@class:%s-@method:%s-@encoding:%s\n",class_getName(clz),
                            sel_getName(method_getName(method)),
                            method_getTypeEncoding(method)]];
    }
    free(methods);
}

+ (NSString *)stringByEnsuringNotNil:(NSString *)aStr{
    return aStr?aStr:@"";
}

+ (void)log:(NSString *)format, ...{
    va_list argumentList;
    va_start(argumentList, format);
    NSMutableString * message = [[NSMutableString alloc] initWithFormat:format arguments:argumentList];
//    NSLogv(message, argumentList);
    va_end(argumentList);
}
@end
