//
//  YTXCollectionUserDefaultCacheSync.m
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/19.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import "YTXCollectionUserDefaultCacheSync.h"

#import <Mantle/Mantle.h>

@implementation YTXCollectionUserDefaultCacheSync

- (nonnull instancetype) initWithModelClass:(nonnull Class)modelClass
{
    return [self initWithModelClass:modelClass userDefaultSuiteName:nil];
}

- (nonnull instancetype) initWithModelClass:(nonnull Class)modelClass userDefaultSuiteName:(nullable NSString *) suiteName;
{
    if (self = [super init]) {
        _modelClass = modelClass;
        _userDefaultSuiteName = suiteName;
    }
    return  self;
}

/** GET */
- (nonnull RACSignal *) fetchCacheWithCacheKey:(nonnull NSString *)cacheKey withParam:(nullable NSDictionary *)param
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSArray * jsonArray = [[[NSUserDefaults alloc] initWithSuiteName:self.userDefaultSuiteName] objectForKey:cacheKey];
            
            NSError * error = nil;
            NSArray * array = [MTLJSONAdapter modelsOfClass:self.modelClass fromJSONArray:jsonArray error:&error];
            
            if (error) {
                [subscriber sendError:error];
            }
            else {
                [subscriber sendNext:array];
                [subscriber sendCompleted];
            }
            
        });
        return nil;
    }];
}
/** POST / PUT */
- (nonnull RACSignal *) saveCacheWithCacheKey:(nonnull NSString *)cacheKey withParam:(nullable NSDictionary *)param withCollection:(nonnull NSArray *)collection
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[[NSUserDefaults alloc] initWithSuiteName:self.userDefaultSuiteName] setObject:[MTLJSONAdapter JSONArrayFromModels:collection] forKey:cacheKey];
            
            [subscriber sendNext:collection];
            [subscriber sendCompleted];
        });
        
        return nil;
    }];
}
/** DELETE */
- (nonnull RACSignal *) destroyCacheWithCacheKey:(nonnull NSString *)cacheKey withParam:(nullable NSDictionary *)param
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[[NSUserDefaults alloc] initWithSuiteName:self.userDefaultSuiteName] removeObjectForKey:cacheKey];
            [subscriber sendNext:nil];
            [subscriber sendCompleted];
        });
        return nil;
    }];
}

- (nonnull RACSignal *) fetchCache:(nullable NSDictionary *)param
{
    return [self fetchCacheWithCacheKey:[self cacheKeyWithModelClass:self.modelClass] withParam:param];
}
/** POST / PUT */
- (nonnull RACSignal *) saveCache:(nullable NSDictionary *)param withCollection:(nonnull NSArray *)collection
{
    return [self saveCacheWithCacheKey:[self cacheKeyWithModelClass:self.modelClass] withParam:param withCollection:collection];
    
}
/** DELETE */
- (nonnull RACSignal *) destroyCache:(nullable NSDictionary *)param
{
    return [self destroyCacheWithCacheKey:[self cacheKeyWithModelClass:self.modelClass] withParam:param];
}

- (nonnull NSString *) cacheKeyWithModelClass:(Class)modelClass
{
    return [NSString stringWithFormat:@"EFSCollection+%@", NSStringFromClass(modelClass)];
}

@end
