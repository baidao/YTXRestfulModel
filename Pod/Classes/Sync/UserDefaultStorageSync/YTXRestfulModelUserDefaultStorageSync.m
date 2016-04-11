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


@end
