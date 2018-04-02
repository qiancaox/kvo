//
//  TestKvoClass.h
//  KVO_Support
//
//  Created by qiancaox on 2018/4/2.
//  Copyright © 2018年 qiancaox. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TestKvoClass : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign, getter=getAge, setter=_reloadAge:) int age;

@end
