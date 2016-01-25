//
//  YTXCollectionCacheProtocol.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>
#import <Foundation/Foundation.h>

@class YTXCollection;

@protocol YTXCollectionCacheProtocol <NSObject>

@property (nonnull, nonatomic, strong, readonly) Class modelClass;

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
