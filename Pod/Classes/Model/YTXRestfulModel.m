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

- (nullable id) primaryValue
{
    return [self valueForKey:[self primaryKey]];
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
        [subject sendNext:self];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (nonnull RACSignal *) saveCache:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.cacheSync saveCache:param withMtlModel:self] subscribeNext:^(id x) {
        @strongify(self);
        [subject sendNext:self];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

/** DELETE */
- (nonnull RACSignal *) destroyCache:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.cacheSync destroyCache:param withMtlModel:self] subscribeNext:^(id x) {
        @strongify(self);
        [subject sendNext:self];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (nonnull RACSignal *)fetchCacheWithCacheKey:(NSString *)cachekey withParam:(NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.cacheSync fetchCacheWithCacheKey:cachekey withParam:param withMtlModel:self] subscribeNext:^(id x) {
        @strongify(self);
        [self mergeWithAnother:x];
        [subject sendNext:self];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (nonnull RACSignal *)saveCacheWithCacheKey:(nonnull NSString *)cachekey withParam:(nullable NSDictionary *)param
{
    return [self.cacheSync saveCacheWithCacheKey:cachekey withParam:param withMtlModel:self];
}

- (nonnull RACSignal *)destroyCacheWithCacheKey:(nonnull NSString *)cachekey withParam:(nullable NSDictionary *)param
{
    return [self.cacheSync destroyCacheWithKey:cachekey withParam:param withMtlModel:self];
}

#pragma mark remote
/** 在拉到数据转mantle的时候用 */
- (nonnull instancetype) transformerProxyOfReponse:(nonnull id) response error:(NSError * _Nullable * _Nullable) error
{
    return [self mergeWithAnother:[MTLJSONAdapter modelOfClass:[self class] fromJSONDictionary:response error:error]];
}

- (nonnull NSDictionary *)mapParameters:(nonnull NSDictionary *)param
{
    NSMutableDictionary * retDict = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *_JSONKeyPathsByPropertyKey = [[[self class] JSONKeyPathsByPropertyKey] copy];
    
    NSString * mappedPropertyKey = nil;
    
    for (NSString *key in param) {
        
        mappedPropertyKey = _JSONKeyPathsByPropertyKey[key] ? : key;
        
        retDict[mappedPropertyKey] = param[key];
    }
    
    return retDict;
}

- (nonnull NSDictionary *)mergeSelfAndParameters:(nullable NSDictionary *)param
{
    NSDictionary * mapParam = [self mapParameters:param];
    
    NSMutableDictionary *retDic = [[MTLJSONAdapter JSONDictionaryFromModel:self] mutableCopy];
    
    for (NSString *key in mapParam) {
        retDic[key] = mapParam[key];
    }
    return retDic;
}

- (nonnull id) transformerProxyOfForeign:(nonnull Class)modelClass reponse:(nonnull id) response error:(NSError * _Nullable * _Nullable) error;
{
    return [MTLJSONAdapter modelsOfClass:modelClass fromJSONArray:response error:error];
}

- (nonnull RACSignal *) fetchRemoteForeignWithName:(nonnull NSString *)name modelClass:(nonnull Class)modelClass param:(nullable NSDictionary *)param;
{
    NSAssert([modelClass isSubclassOfClass: [MTLModel class] ], @"希望传入的class是MTLModel的子类，这样才能使用mantle转换");
    @weakify(self);
    RACSubject * subject = [RACSubject subject];
    [[self.remoteSync fetchRemoteForeignWithName:name param:[self mergeSelfAndParameters:param]] subscribeNext:^(id x) {
        @strongify(self);
        NSError * error = nil;
        [self transformerProxyOfForeign: modelClass reponse:x error:&error];
        if (!error) {
            [subject sendNext:self];
            [subject sendCompleted];
        }
        else {
            [subject sendError:error];
        }
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.remoteSync fetchRemote:[self mergeSelfAndParameters:param]] subscribeNext:^(id x) {
        @strongify(self);
        NSError * error = nil;
        [self transformerProxyOfReponse:x error:&error];
        if (!error) {
            [subject sendNext:self];
            [subject sendCompleted];
        }
        else {
            [subject sendError:error];
        }
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (nonnull RACSignal *) saveRemote:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    if ([self isNew]) {
        [[self.remoteSync createRemote:[self mergeSelfAndParameters:param]] subscribeNext:^(id x) {
            @strongify(self);
            NSError * error = nil;
            [self transformerProxyOfReponse:x error:&error];
            if (!error) {
                [subject sendNext:self];
                [subject sendCompleted];
            }
            else {
                [subject sendError:error];
            }
        } error:^(NSError *error) {
            [subject sendError:error];
        }];
    }
    else {
        [[self.remoteSync updateRemote:[self mergeSelfAndParameters:param]] subscribeNext:^(id x) {
            @strongify(self);
            NSError * error = nil;
            [self transformerProxyOfReponse:x error:&error];
            if (!error) {
                [subject sendNext:self];
                [subject sendCompleted];
            }
            else {
                [subject sendError:error];
            }
        } error:^(NSError *error) {
             [subject sendError:error];
        }];
    }
    
    return subject;
}

- (nonnull RACSignal *) destroyRemote:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.remoteSync destroyRemote:[self mergeSelfAndParameters:param]] subscribeNext:^(id x) {
        @strongify(self);
        NSError * error = nil;
        [self transformerProxyOfReponse:x error:&error];
        if (!error) {
            [subject sendNext:x];
            [subject sendCompleted];
        }
        else {
            [subject sendError:error];
        }
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    
    return subject;
}

@end
