//
//  KvoObserverInfo.h
//  KVO_Support
//
//  Created by qiancaox on 2018/4/2.
//  Copyright © 2018年 qiancaox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KvoClassProperty.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^NSObjectKvoBlockType)(id obj, id oldValue, id newValue, NSString *keyPath);

@interface KvoObserverInfo : NSObject

- (instancetype)initWithObserver:(NSObject *)observer property:(KvoClassProperty *)property block:(NSObjectKvoBlockType)block;

@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, strong) KvoClassProperty *property;
@property (nonatomic, copy) NSObjectKvoBlockType block;

@end

NS_ASSUME_NONNULL_END
