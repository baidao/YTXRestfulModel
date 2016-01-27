//
//  YTXModel.m
//  YTXRestfulModel
//
//  Created by cao jun on 16/01/25.
//  Copyright © 2015 Elephants Financial Service. All rights reserved.
//

#import "YTXRestfulModel.h"

#import <objc/runtime.h>

@implementation YTXRestfulModel

- (instancetype)init
{
    if(self = [super init])
    {
        self.cacheSync = [YTXRestfulModelUserDefaultCacheSync new];
        self.remoteSync = [YTXRestfulModelYTXRequestRemoteSync syncWithPrimaryKey: [self syncPrimaryKey]];
    }
    return self;
}

#pragma mark MTL
- (NSDictionary *)dictionaryValue {
    NSDictionary *originalDictValue = [super dictionaryValue];
    NSMutableDictionary *dictValue = [originalDictValue mutableCopy];
    for (NSString *key in originalDictValue) {
        if ([self valueForKey:key] == nil) {
            [dictValue removeObjectForKey:key];
        }
    }
    //删除这个2个不必要的属性 可以用http://stackoverflow.com/questions/18961622/how-to-omit-null-values-in-json-dictionary-using-mantle这些方法，但是最合理的还是这个。
    [dictValue removeObjectForKey:@"remoteSync"];
    [dictValue removeObjectForKey:@"cacheSync"];
    return [dictValue copy];
}



+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{};
}

#pragma mark EFSModelProtocol

+ (instancetype) shared
{
    static YTXRestfulModel *model;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        model = [[[self class] alloc] init];
    });
    return model;
}
- (instancetype) mergeWithAnother:(_Nonnull id) model
{
    if ([self class] != [model class]){
        return self;
    }
    unsigned count;
    objc_property_t *modelProperties = class_copyPropertyList([model class], &count);
    
    unsigned i;
    for (i = 0; i < count; i++)
    {
        objc_property_t modelProperty = modelProperties[i];
        NSString *modelPropertyName = [NSString stringWithUTF8String:property_getName(modelProperty)];
        
        objc_property_t selfProperty = class_getProperty([self class], [modelPropertyName UTF8String]);
        NSString *selfPropertyName = [NSString stringWithUTF8String:property_getName(selfProperty)];

        id modelValue = [model valueForKey:modelPropertyName];
        
        //我有这个属性，modelValue不等于空
        if (selfPropertyName && selfPropertyName == modelPropertyName && modelValue != nil) {

            const char * modelPropertyType =property_getAttributes(modelProperty);
            const char * selfPropertyType =property_getAttributes(selfProperty);
            //类型也一样
            if (modelPropertyType == selfPropertyType) {
                [self setValue:modelValue forKey:selfPropertyName];
            }
        }
    }
    
    free(modelProperties);
    
    return self;
}

- (NSString *)primaryKey
{
    return @"keyId";
}

- (NSString *)syncPrimaryKey
{
    return [[self class] JSONKeyPathsByPropertyKey][[self primaryKey]] ?: [self primaryKey];
}

/** 要用keyId判断 */
- (BOOL) isNew
{
    return [self valueForKey:[self primaryKey]] == nil;
}


#pragma mark cache
- (nonnull RACSignal *) fetchCache:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.cacheSync fetchCache:param withMtlModel:self] subscribeNext:^(id x) {
        @strongify(self);
        [self mergeWithAnother:x];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (nonnull RACSignal *) saveCache:(nullable NSDictionary *)param
{
    return [self.cacheSync saveCache:param withMtlModel:self];
}
/** DELETE */
- (nonnull RACSignal *) destroyCache:(nullable NSDictionary *)param
{
    return [self.cacheSync destroyCache:param withMtlModel:self];
}

#pragma mark remote

- (void)setRemoteSyncUrl:(NSURL *)url
{
    self.remoteSync.url = url;
}

/** 在拉到数据转mantle的时候用 */
- (nonnull instancetype) transformerProxyOfReponse:(nonnull id) response
{
    return [self mergeWithAnother:[MTLJSONAdapter modelOfClass:[self class] fromJSONDictionary:response error:nil]];
}

- (nonnull NSDictionary *)mergeSelfAndParameters:(nullable NSDictionary *)param
{
    NSMutableDictionary *retDic = [[MTLJSONAdapter JSONDictionaryFromModel:self] mutableCopy];
    for (NSString *key in param) {
        if (retDic[key] == nil) {
            retDic[key] = param[key];
        }
    }
    return retDic;
}

- (nonnull MTLModel *) transformerProxyOfForeign:(nonnull Class)modelClass reponse:(nonnull id) response
{
    return [MTLJSONAdapter modelOfClass:modelClass fromJSONDictionary:response error:nil];
}

- (nonnull RACSignal *) fetchRemoteForeignWithName:(nonnull NSString *)name modelClass:(nonnull Class)modelClass param:(nullable NSDictionary *)param;
{
    NSAssert([modelClass isSubclassOfClass: [MTLModel class] ], @"希望传入的class是MTLModel的子类，这样才能使用mantle转换");
    
    RACSubject * subject = [RACSubject subject];
    [[self.remoteSync fetchRemoteForeignWithName:name param:[self mergeSelfAndParameters:param]] subscribeNext:^(id x) {
        [subject sendNext:[self transformerProxyOfForeign: modelClass reponse:x] ];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    [[self.remoteSync fetchRemote:[self mergeSelfAndParameters:param]] subscribeNext:^(id x) {
        [subject sendNext:[self transformerProxyOfReponse:x]];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (nonnull RACSignal *) saveRemote:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    
    if ([self isNew]) {
        [[self.remoteSync createRemote:[self mergeSelfAndParameters:param]] subscribeNext:^(id x) {
            [subject sendNext:[self transformerProxyOfReponse:x]];
            [subject sendCompleted];
        } error:^(NSError *error) {
            [subject sendError:error];
        }];
    }
    else {
        [[self.remoteSync updateRemote:[self mergeSelfAndParameters:param]] subscribeNext:^(id x) {
            [subject sendNext:[self transformerProxyOfReponse:x]];
            [subject sendCompleted];
        } error:^(NSError *error) {
             [subject sendError:error];
        }];
    }
    
    return subject;
}

- (nonnull RACSignal *) destroyRemote:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    
    [[self.remoteSync destroyRemote:[self mergeSelfAndParameters:param]] subscribeNext:^(id x) {
        [subject sendNext: x ? [self transformerProxyOfReponse:x] : nil];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    
    return subject;
}

@end
