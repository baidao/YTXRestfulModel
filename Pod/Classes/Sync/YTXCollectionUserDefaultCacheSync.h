//
//  YTXCollectionUserDefaultCacheSync.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YTXCollectionCacheProtocol.h"

@interface YTXCollectionUserDefaultCacheSync : NSObject <YTXCollectionCacheProtocol>

@property (nullable, nonatomic, copy) NSString * userDefaultSuiteName;
@property (nonnull, nonatomic, strong, readonly) Class modelClass;


- (nonnull instancetype) initWithModelClass:(nonnull Class)modelClass;
- (nonnull instancetype) initWithModelClass:(nonnull Class)modelClass userDefaultSuiteName:(nullable NSString *) suiteName;

/** GET */
- (nonnull RACSignal *) fetchCacheWithCacheKey:(nonnull NSString *)cacheKey withParam:(nullable NSDictionary *)param;
/** POST / PUT */
- (nonnull RACSignal *) saveCacheWithCacheKey:(nonnull NSString *)cacheKey withParam:(nullable NSDictionary *)param withCollection:(nonnull NSArray *)collection;
/** DELETE */
- (nonnull RACSignal *) destroyCacheWithCacheKey:(nonnull NSString *)cacheKey withParam:(nullable NSDictionary *)param;

/** GET */
- (nonnull RACSignal *) fetchCache:(nullable NSDictionary *)param;
/** POST / PUT */
- (nonnull RACSignal *) saveCache:(nullable NSDictionary *)param withCollection:(nonnull NSArray *)collection;
/** DELETE */
- (nonnull RACSignal *) destroyCache:(nullable NSDictionary *)param;

@end
