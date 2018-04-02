//
//  KvoClassProperty.h
//  KVO_Support
//
//  Created by qiancaox on 2018/4/2.
//  Copyright © 2018年 qiancaox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

NS_ASSUME_NONNULL_BEGIN

@interface KvoClassProperty : NSObject

/// Get the attribute wrapper object associated with the class object.
/// First, get the associated attribute package class, if not, initialize one.
+ (instancetype)cachedClassPropertyWithPropertyT:(objc_property_t)property_t;

@property (nonatomic, assign, readonly) objc_property_t property_t;

/// The property named.
@property (nonatomic, copy, readonly) NSString *name;

/// The setter selector of property.
@property (nonatomic, assign, readonly) SEL setter;

/// The getter selector of property.
@property (nonatomic, assign, readonly) SEL getter;

@end

typedef NSArray<KvoClassProperty*> * KvoClassPropertyList;
extern KvoClassPropertyList class_getPropertyList(Class c);

typedef void (^EnumeratePropertyBlockType)(KvoClassProperty * _Nonnull property, NSUInteger idx, BOOL* _Nonnull stop);
extern void class_enumeratePropertyUsingBlock(Class c, EnumeratePropertyBlockType enumeration);

NS_ASSUME_NONNULL_END
