//
//  NSObject+kvo.m
//  KVO_Support
//
//  Created by qiancaox on 2018/4/2.
//  Copyright © 2018年 qiancaox. All rights reserved.
//

#import "NSObject+kvo.h"

static const char kKvoPropertyAttributesAssociateKey = '\0';
static NSString * const kGenerateKvoClassPrefix = @"KvoGenerate_";
static const char kKvoShouldRemoveObserverAssociateKey = '\0';

static Class kvo_class(id self, SEL _cmd)
{
    return class_getSuperclass(object_getClass(self));
}

static BOOL class_hasSelector(Class c, SEL aSelector)
{
    unsigned int outCount = 0;
    Method* methodList = class_copyMethodList(c, &outCount);
    for (int i = 0; i < outCount; ++ i) {
        SEL thisSelector = method_getName(methodList[i]);
        if (thisSelector == aSelector) {
            free(methodList);
            return YES;
        }
    }
    
    free(methodList);
    return NO;
}

static void kvo_setter(id self, SEL _cmd, id newValue)
{
    // 1.获取之前添加kvo时的包装类
    __block KvoClassProperty *property = nil;
    __block NSArray *observers = nil;
    NSMutableDictionary *attrs = objc_getAssociatedObject(self, &kKvoPropertyAttributesAssociateKey);
    [attrs enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSArray *  _Nonnull array, BOOL * _Nonnull stop) {
        [array enumerateObjectsUsingBlock:^(KvoObserverInfo *  _Nonnull observerInfo, NSUInteger idx, BOOL * _Nonnull stop) {
            if (observerInfo.property.setter == _cmd) {
                property = observerInfo.property;
            }
            *stop = YES;
        }];
        
        if (property != nil) {
            observers = array;
            *stop = YES;
        }
    }];
    
    struct objc_super super_c = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    
    // 2.获取修改之前的value，如果两个值相等，则返回
    id (*objc_msgSendSuperGetter) (struct objc_super*, SEL) = (void*)objc_msgSendSuper;
    id oldValue = objc_msgSendSuperGetter(&super_c, property.getter);
    if ([oldValue isEqual:newValue]) {
        return;
    }
    
    // 3.调用原始类的setter方法
    id (*objc_msgSendSuperSetter) (struct objc_super*, SEL, id) = (void*)objc_msgSendSuper;
    objc_msgSendSuperSetter(&super_c, _cmd, newValue);
    
    // 4.实现block回调
    [observers enumerateObjectsUsingBlock:^(KvoObserverInfo *  _Nonnull observerInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        if (observerInfo.block) {
            observerInfo.block(self, oldValue, newValue, property.name);
        }
    }];
}

@implementation NSObject (kvo)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method dealloc = class_getInstanceMethod(self, NSSelectorFromString(@"dealloc"));
        Method dealloc_ = class_getInstanceMethod(self, @selector(_dealloc));
        method_exchangeImplementations(dealloc, dealloc_);
    });
}

- (void)_dealloc
{
    if ([objc_getAssociatedObject(self, &kKvoShouldRemoveObserverAssociateKey) boolValue]) {
        [self.kvoPropertyAttributes removeAllObjects];
        NSLog(@"%@ dealloced", self);
    }
}

- (void)kvoObserver:(NSObject *)observer forKeyPath:(NSString *)propertyName responsed:(NSObjectKvoBlockType)block
{
    KvoClassProperty *property = [self _classHasPropertyWithName:propertyName];
    if (property == nil) {
        return;
    }
    
    if ([self _hasAllreadyAddObserveKeyPath:observer property:property responsed:block]) {
        return;
    }
    
    Class kvoClass = [self _generateKvoClass];
    
    // 1.如果派生类没有setter方法，则添加，并将setter方法的实现指向kvo_setter
    if (!class_hasSelector(kvoClass, property.setter)) {
        const char* types = method_getTypeEncoding(class_getInstanceMethod(self.class, property.setter));
        class_addMethod(kvoClass, property.setter, (IMP)kvo_setter, types);
        // 2.isa-swizzing  将self的isa指针指向派生类kvoClass
        object_setClass(self, kvoClass);
    }
    
    // 3.设置在dealloc时需要清除观察者
    objc_setAssociatedObject(self, &kKvoShouldRemoveObserverAssociateKey, @(YES), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (KvoClassProperty *)_classHasPropertyWithName:(NSString *)name
{
    __block KvoClassProperty *t = nil;
    class_enumeratePropertyUsingBlock(self.class, ^(KvoClassProperty * _Nonnull property, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([name isEqualToString:property.name]) {
            t = property;
            *stop = YES;
        }
    });
    return t;
}

- (BOOL)_hasAllreadyAddObserveKeyPath:(NSObject *)observer property:(KvoClassProperty *)property responsed:(NSObjectKvoBlockType)block
{
    NSMutableArray *array = self.kvoPropertyAttributes[property.name];
    if (!array) {
        array = [NSMutableArray array];
        [self.kvoPropertyAttributes setValue:array forKey:property.name];
    }
    __block BOOL isAllreadyAddObserveKeyPath = NO;
    [array enumerateObjectsUsingBlock:^(KvoObserverInfo *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.observer == observer && [obj.property.name isEqualToString:property.name]) {
            isAllreadyAddObserveKeyPath = YES;
        }
    }];
    
    if (!isAllreadyAddObserveKeyPath) {
        [array addObject:[[KvoObserverInfo alloc] initWithObserver:observer property:property block:block]];
    }
    
    return isAllreadyAddObserveKeyPath;
}

- (Class)_generateKvoClass
{
    NSString *originClassName = NSStringFromClass(self.class);
    
    // 1.如果已近是派生类
    if ([originClassName hasPrefix:kGenerateKvoClassPrefix]) {
        return nil;
    }
    
    // 2.派生类类名
    NSString *kvoClassName = [kGenerateKvoClassPrefix stringByAppendingString:originClassName];
    
    // 3.如果有kvoClass类，直接返回
    Class kvoClass = NSClassFromString(kvoClassName);
    if (kvoClass) {
        return kvoClass;
    }
    
    // 4.生成原始类的派生类，用于kvo重写setter方法
    kvoClass = objc_allocateClassPair(self.class, kvoClassName.UTF8String, 0);
    
    // 5.注册派生类
    objc_registerClassPair(kvoClass);
    
    // 6.由于切换了对象的isa指针，会导致对象的类为派生类，这时候需要重新设置派生类的class方法
    Method clazzMethod = class_getInstanceMethod(self.class, @selector(class));
    const char *types = method_getTypeEncoding(clazzMethod);
    class_addMethod(kvoClass, @selector(class), (IMP)kvo_class, types);
    
    return kvoClass;
}

#pragma mark - Getter

- (NSMutableDictionary *)kvoPropertyAttributes
{
    NSMutableDictionary *attrs = objc_getAssociatedObject(self, &kKvoPropertyAttributesAssociateKey);
    if (!attrs) {
        attrs = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &kKvoPropertyAttributesAssociateKey, attrs, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return attrs;
}

@end
