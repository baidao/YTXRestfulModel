//
//  YTXRestfulModelUserDefaultCacheProtocol.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>
#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

@protocol YTXRestfulModelUserDefaultCacheProtocol <NSObject>

@required

/** GET */
- (nonnull RACSignal *) fetchCache:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model;

/** POST / PUT */
- (nonnull RACSignal *) saveCache:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel<MTLJSONSerializing> *) model;

/** DELETE */
- (nonnull RACSignal *) destroyCache:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model;

/** GET */
- (nonnull RACSignal *) fetchCacheWithCacheKey:(nonnull NSString *)cachekey withParam:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model;

/** POST / PUT */
- (nonnull RACSignal *) saveCacheWithCacheKey:(nonnull NSString *)cachekey withParam:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel<MTLJSONSerializing> *) model;

/** DELETE */
- (nonnull RACSignal *) destroyCacheWithKey:(nonnull NSString *)cachekey withParam:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model;

- (nonnull NSString *) cacheKeyWithMtlModel:(nonnull MTLModel *) model;

@end
