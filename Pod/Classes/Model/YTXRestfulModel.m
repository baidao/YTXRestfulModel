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

@synthesize url = _url;

- (instancetype)init
{
    if(self = [super init])
    {
        self.cacheSync = [YTXRestfulModelUserDefaultCacheSync new];
        self.remoteSync = [YTXRestfulModelYTXRequestRemoteSync new];
        self.remoteSync.primaryKey = [self syncPrimaryKey];
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
    unsigned count;
    objc_property_t *properties = class_copyPropertyList([model class], &count);

    
    unsigned i;
    for (i = 0; i < count; i++)
    {
        objc_property_t property = properties[i];
        NSString *name = [NSString stringWithUTF8String:property_getName(property)];
        
        id selfValue = [self valueForKey:name];
        id modelValue = [model valueForKey:name];
        
        if (selfValue && [selfValue isMemberOfClass: [modelValue class] ]) {
            [self setValue:modelValue forKey:name];
        };
    }
    
    free(properties);
    
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

- (void)setUrl:(NSURL *)url
{
    self.remoteSync.url = url;
}

- (NSURL *)url
{
    return self.remoteSync.url;
}

/** 在拉到数据转mantle的时候用 */
- (nonnull instancetype) transformerProxyOfReponse:(nonnull id) response
{
    return [self mergeWithAnother:[MTLJSONAdapter modelOfClass:[self class] fromJSONDictionary:response error:nil]];
}

- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    [[self.remoteSync fetchRemote:param] subscribeNext:^(id x) {
        [subject sendNext:[self transformerProxyOfReponse:x]];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (nonnull RACSignal *) saveRemote:(nullable NSDictionary *)param
{
    
    NSMutableDictionary * dict = [[MTLJSONAdapter JSONDictionaryFromModel:self ] mutableCopy];
    RACSubject * subject = [RACSubject subject];
    
    [dict setValuesForKeysWithDictionary:param];
    
    if ([self isNew]) {
        [[self.remoteSync createRemote:dict] subscribeNext:^(id x) {
            [subject sendNext:[self transformerProxyOfReponse:x]];
            [subject sendCompleted];
        } error:^(NSError *error) {
            [subject sendError:error];
        }];
    }
    else {
        [[self.remoteSync updateRemote:dict] subscribeNext:^(id x) {
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
    NSMutableDictionary * dict = [[MTLJSONAdapter JSONDictionaryFromModel:self ] mutableCopy];
    
    [[self.remoteSync destroyRemote:dict] subscribeNext:^(id x) {
        [subject sendNext: x ? [self transformerProxyOfReponse:x] : nil];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    
    return subject;
}



@end
