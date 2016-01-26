//
//  YTXRestfulModelUserDefaultCacheSync.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import "YTXRestfulModelUserDefaultCacheProtocol.h"

#import <Foundation/Foundation.h>


@interface YTXRestfulModelUserDefaultCacheSync : NSObject<YTXRestfulModelUserDefaultCacheProtocol>

@property (nullable, nonatomic, copy, readonly) NSString * userDefaultSuiteName;

- (nonnull instancetype) initWithUserDefaultSuiteName:(nullable NSString *) suiteName;

- (nonnull RACSignal *) fetchCacheWithCacheKey:(nonnull NSString *)cachekey wtihParam:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model;

/** POST / PUT */
- (nonnull RACSignal *) saveCacheWithCacheKey:(nonnull NSString *)cachekey wtihParam:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel<MTLJSONSerializing> *) model;

/** DELETE */
- (nonnull RACSignal *) destroyCacheWithKey:(nonnull NSString *)cachekey wtihParam:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model;


/** GET */
- (nonnull RACSignal *) fetchCache:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model;

- (nonnull RACSignal *) saveCache:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel<MTLJSONSerializing> *) model;
/** DELETE */
- (nonnull RACSignal *) destroyCache:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model;

- (nonnull NSString *) cacheKeyWithMtlModel:(nonnull MTLModel *) model;

@end
