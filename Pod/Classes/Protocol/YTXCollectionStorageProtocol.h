//
//  YTXCollectionStorageProtocol.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>
#import <Foundation/Foundation.h>

@class YTXCollection;

@protocol YTXCollectionStorageProtocol <NSObject>

@property (nonnull, nonatomic, strong, readonly) Class modelClass;

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
