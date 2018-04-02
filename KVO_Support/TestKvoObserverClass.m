//
//  TestKvoObserverClass.m
//  KVO_Support
//
//  Created by qiancaox on 2018/4/2.
//  Copyright © 2018年 qiancaox. All rights reserved.
//

#import "TestKvoObserverClass.h"

@implementation TestKvoObserverClass

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    NSLog(@"%@", change);
}

- (void)dealloc
{
    NSLog(@"%@ dealloced", self);
}

@end
