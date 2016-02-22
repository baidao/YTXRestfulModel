//
//  YTXCollectionUserDefaultStorageSync.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YTXCollectionStorageProtocol.h"

@interface YTXCollectionUserDefaultStorageSync : NSObject <YTXCollectionStorageProtocol>

@property (nullable, nonatomic, copy) NSString * userDefaultSuiteName;
@property (nonnull, nonatomic, strong, readonly) Class modelClass;


- (nonnull instancetype) initWithModelClass:(nonnull Class)modelClass;
- (nonnull instancetype) initWithModelClass:(nonnull Class)modelClass userDefaultSuiteName:(nullable NSString *) suiteName;

/** GET */
- (nonnull RACSignal *) fetchStorageWithKey:(nonnull NSString *)storageKey withParam:(nullable NSDictionary *)param;
/** POST / PUT */
- (nonnull RACSignal *) saveStorageWithKey:(nonnull NSString *)storageKey withParam:(nullable NSDictionary *)param withCollection:(nonnull NSArray *)collection;
/** DELETE */
- (nonnull RACSignal *) destroyStorageWithKey:(nonnull NSString *)storageKey withParam:(nullable NSDictionary *)param;

/** GET */
- (nonnull RACSignal *) fetchStorage:(nullable NSDictionary *)param;
/** POST / PUT */
- (nonnull RACSignal *) saveStorage:(nullable NSDictionary *)param withCollection:(nonnull NSArray *)collection;
/** DELETE */
- (nonnull RACSignal *) destroyStorage:(nullable NSDictionary *)param;

@end
