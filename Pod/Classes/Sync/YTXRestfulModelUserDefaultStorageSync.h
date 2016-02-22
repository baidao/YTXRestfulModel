//
//  YTXRestfulModelUserDefaultStorageSync.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import "YTXRestfulModelStorageProtocol.h"

#import <Foundation/Foundation.h>


@interface YTXRestfulModelUserDefaultStorageSync : NSObject<YTXRestfulModelStorageProtocol>

@property (nullable, nonatomic, copy, readonly) NSString * userDefaultSuiteName;

- (nonnull instancetype) initWithUserDefaultSuiteName:(nullable NSString *) suiteName;

- (nonnull RACSignal *) fetchStorageWithKey:(nonnull NSString *)storage withParam:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model;

/** POST / PUT */
- (nonnull RACSignal *) saveStorageWithKey:(nonnull NSString *)storage withParam:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel<MTLJSONSerializing> *) model;

/** DELETE */
- (nonnull RACSignal *) destroyStorageWithKey:(nonnull NSString *)storage withParam:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model;


/** GET */
- (nonnull RACSignal *) fetchStorage:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model;

- (nonnull RACSignal *) saveStorage:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel<MTLJSONSerializing> *) model;
/** DELETE */
- (nonnull RACSignal *) destroyStorage:(nullable NSDictionary *)param withMtlModel:(nonnull MTLModel *) model;

- (nonnull NSString *) storageKeyWithMtlModel:(nonnull MTLModel *) model;

@end
