//
//  NSObject+kvo.h
//  KVO_Support
//
//  Created by qiancaox on 2018/4/2.
//  Copyright © 2018年 qiancaox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KvoObserverInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (kvo)

/// Add observer for object.
/// @param  observer    The observer instance.
/// @param  propertyName    The observed attribute must be the object type.
/// @param  block   The callback, replaced '-(void)observeValueForKeyPath:ofObject:change:context:'.
- (void)kvoObserver:(NSObject *)observer forKeyPath:(NSString * _Nonnull)propertyName responsed:(NSObjectKvoBlockType)block;

@end

NS_ASSUME_NONNULL_END
