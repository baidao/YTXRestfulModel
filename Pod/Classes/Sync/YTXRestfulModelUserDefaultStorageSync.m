//
//  YTXRestfulModelUserDefaultStorageSync.m
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import "YTXRestfulModelUserDefaultStorageSync.h"

#import <Mantle/Mantle.h>

@implementation YTXRestfulModelUserDefaultStorageSync

- (nonnull instancetype) initWithUserDefaultSuiteName:(nullable NSString *) suiteName;
{
    if (self = [super init]) {
        _userDefaultSuiteName = suiteName;
    }
    return  self;
}


- (nonnull RACSignal *) fetchStorageWithKey:(nonnull NSString *)storage withParam:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSDictionary * dict = [[[NSUserDefaults alloc] initWithSuiteName:self.userDefaultSuiteName] objectForKey:storage];

            NSError * error = nil;
            id data = [MTLJSONAdapter modelOfClass:[model class] fromJSONDictionary:dict error:&error];

            if (error) {
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
- (nonnull RACSignal *) saveStorageWithKey:(nonnull NSString *)storage withParam:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel<MTLJSONSerializing> *) model
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSDictionary * json = [MTLJSONAdapter JSONDictionaryFromModel:model];

            [[[NSUserDefaults alloc] initWithSuiteName:self.userDefaultSuiteName] setObject:json forKey:storage];

            [subscriber sendNext:model];
            [subscriber sendCompleted];
        });

        return nil;
    }];
}

/** DELETE */
- (nonnull RACSignal *) destroyStorageWithKey:(nonnull NSString *)storage withParam:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[[NSUserDefaults alloc] initWithSuiteName:self.userDefaultSuiteName] removeObjectForKey:storage];

            [subscriber sendNext:model];
            [subscriber sendCompleted];
        });

        return nil;
    }];
}


/** GET */
- (nonnull RACSignal *) fetchStorage:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model
{
    return [self fetchStorageWithKey:[self storageKeyWithMtlModel:model] withParam:param withMtlModel:model];
}

- (nonnull RACSignal *) saveStorage:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel<MTLJSONSerializing> *) model
{
    return [self saveStorageWithKey:[self storageKeyWithMtlModel:model] withParam:param withMtlModel:model];
}
/** DELETE */
- (nonnull RACSignal *) destroyStorage:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model;
{
    return [self destroyStorageWithKey:[self storageKeyWithMtlModel:model] withParam:param withMtlModel:model];
}

- (nonnull NSString *) storageKeyWithMtlModel:(nonnull MTLModel *) model
{
    return [NSString stringWithFormat:@"EFSModel+%@", NSStringFromClass([model class])];
}


@end
