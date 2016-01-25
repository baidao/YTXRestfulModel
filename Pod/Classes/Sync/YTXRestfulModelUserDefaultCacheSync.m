//
//  YTXRestfulModelUserDefaultCacheSync.m
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import "YTXRestfulModelUserDefaultCacheSync.h"

#import <Mantle/Mantle.h>

@implementation YTXRestfulModelUserDefaultCacheSync

- (nonnull instancetype) initWithUserDefaultSuiteName:(nullable NSString *) suiteName;
{
    if (self = [super init]) {
        _userDefaultSuiteName = suiteName;
    }
    return  self;
}


- (nonnull RACSignal *) fetchCacheWithCacheKey:(nonnull NSString *)cachekey wtihParam:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSDictionary * dict = [[[NSUserDefaults alloc] initWithSuiteName:self.userDefaultSuiteName] objectForKey:cachekey];
            
            NSError * error = nil;
            id data = [MTLJSONAdapter modelOfClass:[model class] fromJSONDictionary:dict error:&error];
            
            if (!error) {
                [subscriber sendError:error];
                
            } else {
                [subscriber sendNext:data];
                [subscriber sendCompleted];
            }
            
        });
        
        return nil;
    }];
}

/** POST / PUT */
- (nonnull RACSignal *) saveCacheWithCacheKey:(nonnull NSString *)cachekey wtihParam:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel<MTLJSONSerializing> *) model
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSDictionary * json = [MTLJSONAdapter JSONDictionaryFromModel:model];
            
            [[[NSUserDefaults alloc] initWithSuiteName:self.userDefaultSuiteName] setObject:json forKey:cachekey];
            
            [subscriber sendNext:model];
            [subscriber sendCompleted];
        });
        
        return nil;
    }];
}

/** DELETE */
- (nonnull RACSignal *) destroyCacheWithKey:(nonnull NSString *)cachekey wtihParam:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[[NSUserDefaults alloc] initWithSuiteName:self.userDefaultSuiteName] removeObjectForKey:cachekey];
            
            [subscriber sendNext:model];
            [subscriber sendCompleted];
        });
        
        return nil;
    }];
}


/** GET */
- (nonnull RACSignal *) fetchCache:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model
{
    return [self fetchCacheWithCacheKey:[self cacheKeyWithMtlModel:model] wtihParam:param withMtlModel:model];
}

- (nonnull RACSignal *) saveCache:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel<MTLJSONSerializing> *) model
{
    return [self saveCacheWithCacheKey:[self cacheKeyWithMtlModel:model] wtihParam:param withMtlModel:model];
}
/** DELETE */
- (nonnull RACSignal *) destroyCache:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model;
{
    return [self destroyCacheWithKey:[self cacheKeyWithMtlModel:model] wtihParam:param withMtlModel:model];
}

- (nonnull NSString *) cacheKeyWithMtlModel:(nonnull MTLModel *) model
{
    return [NSString stringWithFormat:@"EFSModel+%@", NSStringFromClass([model class])];
}


@end
