//
//  KvoObserverInfo.m
//  KVO_Support
//
//  Created by qiancaox on 2018/4/2.
//  Copyright © 2018年 qiancaox. All rights reserved.
//

#import "KvoObserverInfo.h"

@implementation KvoObserverInfo

- (instancetype)initWithObserver:(NSObject *)observer property:(KvoClassProperty *)property block:(NSObjectKvoBlockType)block
{
    self = [super init];
    if (self) {
        self.observer = observer;
        self.property = property;
        self.block = block;
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"%@ dealloced", self);
}

@end
