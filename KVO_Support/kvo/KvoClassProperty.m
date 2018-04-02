//
//  KvoClassProperty.m
//  KVO_Support
//
//  Created by qiancaox on 2018/4/2.
//  Copyright © 2018年 qiancaox. All rights reserved.
//

#import "KvoClassProperty.h"

static const char kClassAssociatePropertyListKey = '\0';

KvoClassPropertyList class_getPropertyList(Class c)
{
    unsigned int outCount = 0;
    objc_property_t *propertyList = class_copyPropertyList(c, &outCount);
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:outCount];
    for (int i = 0; i < outCount; ++ i) {
        objc_property_t property_t = propertyList[i];
        KvoClassProperty *property = [KvoClassProperty cachedClassPropertyWithPropertyT:property_t];
        [array addObject:property];
    }
    free(propertyList);
    return array.copy;
}

void class_enumeratePropertyUsingBlock(Class c, EnumeratePropertyBlockType enumeration)
{
    KvoClassPropertyList propertyList = objc_getAssociatedObject(c, &kClassAssociatePropertyListKey);
    if (!propertyList) {
        propertyList = class_getPropertyList(c);
        objc_setAssociatedObject(c, &kClassAssociatePropertyListKey, propertyList, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [propertyList enumerateObjectsUsingBlock:^(KvoClassProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (enumeration) {
            enumeration(obj, idx, stop);
        }
    }];
}

@implementation KvoClassProperty

@synthesize property_t = _property_t;
@synthesize name = _name;
@synthesize setter = _setter;
@synthesize getter = _getter;

+ (instancetype)cachedClassPropertyWithPropertyT:(objc_property_t)property_t
{
    KvoClassProperty *property = objc_getAssociatedObject(self, property_t);
    if (property == nil) {
        property = [[self alloc] init];
        [property _setProperty_t:property_t];
        objc_setAssociatedObject(self, property_t, property, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return property;
}

- (void)_setProperty_t:(objc_property_t)property_t
{
    _property_t = property_t;
    
    // 1.属性名
    _name = @(property_getName(property_t));
    
    // 2.成员类型
    NSString *attrs = @(property_getAttributes(property_t));
    
    // 3.setter & getter
    NSArray *componentsAttrs = [attrs componentsSeparatedByString:@","];
    for (int i = 0; i < componentsAttrs.count; ++ i) {
        BOOL isSetterMethod = NO;
        SEL selector = [self _setterGetterFromAttrsCode:componentsAttrs[i] isSetterMethod:&isSetterMethod];
        
        // 4.如果重写了setter或getter
        if (selector) {
            if (isSetterMethod) {
                _setter = selector;
            }
            else {
                _getter = selector;
            }
        }
        
        // 跳出循环
        if (_setter && _getter) {
            break;
        }
    }
    
    // 5.检查setter或getter是否获取到，如果没有，则表示没有重写，需要自己获取setter和getter
    if (!_setter) {
        _setter = [self __setter];
    }
    if (!_getter) {
        _getter = [self __getter];
    }
}

- (SEL)_setterGetterFromAttrsCode:(NSString *)code isSetterMethod:(BOOL*)flag
{
    NSString *typeCode = [code substringToIndex:1];
    if ([typeCode isEqualToString:@"G"]) {
        *flag = NO;
        NSString *selectorName = [code substringWithRange:NSMakeRange(1, code.length-1)];
        return NSSelectorFromString(selectorName);
    }
    
    if ([typeCode isEqualToString:@"S"]) {
        NSString *semicolonCode = [code substringWithRange:NSMakeRange(code.length-1, 1)];
        if ([semicolonCode isEqualToString:@":"]) {
            *flag = YES;
            NSString *selectorName = [code substringWithRange:NSMakeRange(1, code.length-1)];
            return NSSelectorFromString(selectorName);
        }
    }
    return nil;
}

- (SEL)__setter
{
    NSString *firstWord = [[_name substringToIndex:1] uppercaseString];
    NSString *setterMid = [_name stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                                         withString:firstWord];
    
    NSString *setter = [NSString stringWithFormat:@"set%@:", setterMid];
    
    return NSSelectorFromString(setter);
}

- (SEL)__getter
{
    return NSSelectorFromString(_name);
}

@end
