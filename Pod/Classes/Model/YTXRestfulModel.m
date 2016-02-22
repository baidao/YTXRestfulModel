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
        self.storageSync = [YTXRestfulModelUserDefaultStorageSync new];
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
    [dictValue removeObjectForKey:@"storageSync"];
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
        if (selfPropertyName && [selfPropertyName isEqualToString:modelPropertyName] && modelValue != nil) {

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


#pragma mark storage
- (nonnull RACSignal *) fetchStorage:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.storageSync fetchStorage:param withMtlModel:self] subscribeNext:^(id x) {
        @strongify(self);
        [self mergeWithAnother:x];
        [subject sendNext:self];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (nonnull RACSignal *) saveStorage:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.storageSync saveStorage:param withMtlModel:self] subscribeNext:^(id x) {
        @strongify(self);
        [subject sendNext:self];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

/** DELETE */
- (nonnull RACSignal *) destroyStorage:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.storageSync destroyStorage:param withMtlModel:self] subscribeNext:^(id x) {
        @strongify(self);
        [subject sendNext:self];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (nonnull RACSignal *)fetchStorageWithKey:(NSString *)storage withParam:(NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.storageSync fetchStorageWithKey:storage withParam:param withMtlModel:self] subscribeNext:^(id x) {
        @strongify(self);
        [self mergeWithAnother:x];
        [subject sendNext:self];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (nonnull RACSignal *)saveStorageWithKey:(nonnull NSString *)storage withParam:(nullable NSDictionary *)param
{
    return [self.storageSync saveStorageWithKey:storage withParam:param withMtlModel:self];
}

- (nonnull RACSignal *)destroyStorageWithKey:(nonnull NSString *)storage withParam:(nullable NSDictionary *)param
{
    return [self.storageSync destroyStorageWithKey:storage withParam:param withMtlModel:self];
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
        id model = [self transformerProxyOfForeign: modelClass reponse:x error:&error];
        if (!error) {
            [subject sendNext:model];
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
