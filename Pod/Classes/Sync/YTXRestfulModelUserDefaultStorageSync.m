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

/** GET */
- (nullable id) fetchStorageSyncWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *) param
{
    return [[[NSUserDefaults alloc] initWithSuiteName:self.userDefaultSuiteName] objectForKey:storage];
}

/** POST / PUT */
- (nullable id<NSCoding>) saveStorageSyncWithKey:(nonnull NSString *)storage withObject:(nonnull id<NSCoding>)object param:(nullable NSDictionary *) param
{
    [[[NSUserDefaults alloc] initWithSuiteName:self.userDefaultSuiteName] setObject:object forKey:storage];
    return object;
}

/** DELETE */
- (void) destroyStorageSyncWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *) param
{
    [[[NSUserDefaults alloc] initWithSuiteName:self.userDefaultSuiteName] removeObjectForKey:storage];
}

/** GET */
- (nonnull RACSignal *) fetchStorageWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *) param
{
    NSDictionary * dict = [self fetchStorageSyncWithKey:storage param:param];
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (dict) {
                [subscriber sendNext:dict];
                [subscriber sendCompleted];
            }
            else {
                [subscriber sendError:[NSError errorWithDomain:NSStringFromClass([self class]) code:404 userInfo:nil]];
            }
        });

        return nil;
    }];
}

/** POST / PUT */
- (nonnull RACSignal *) saveStorageWithKey:(nonnull NSString *)storage withObject:(nonnull id<NSCoding>)object param:(nullable NSDictionary *) param
{
    [self saveStorageSyncWithKey:storage withObject:object param:param];
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [subscriber sendNext:object];
            [subscriber sendCompleted];
        });

        return nil;
    }];
}

/** DELETE */
- (nonnull RACSignal *) destroyStorageWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *) param
{
    [self destroyStorageSyncWithKey:storage param:param];
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [subscriber sendNext:nil];
            [subscriber sendCompleted];
        });

        return nil;
    }];
}


@end
