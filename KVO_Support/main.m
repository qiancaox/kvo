//
//  main.m
//  KVO_Support
//
//  Created by qiancaox on 2018/3/26.
//  Copyright © 2018年 qiancaox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+kvo.h"
#import "TestKvoObserverClass.h"
#import "TestKvoClass.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        TestKvoClass *object = [[TestKvoClass alloc] init];
        
        TestKvoObserverClass *observer = [[TestKvoObserverClass alloc] init];
        
        [object addObserver:observer forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
        
        [object kvoObserver:observer forKeyPath:@"name" responsed:^(id  _Nonnull obj, id  _Nonnull oldValue, id  _Nonnull newValue, NSString * _Nonnull keyPath) {
            NSLog(@"%@     %@     %@     %@", obj, oldValue, newValue, keyPath);
        }];
        
        TestKvoObserverClass *observer1 = [[TestKvoObserverClass alloc] init];
        [object kvoObserver:observer1 forKeyPath:@"name" responsed:^(id  _Nonnull obj, id  _Nonnull oldValue, id  _Nonnull newValue, NSString * _Nonnull keyPath) {
            NSLog(@"%@     %@     %@     %@", obj, oldValue, newValue, keyPath);
        }];
        
        object.name = @"asdlfjl";
    }
    return 0;
}
