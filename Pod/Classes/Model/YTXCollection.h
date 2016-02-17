//
//  YTXCollection.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import "YTXCollectionUserDefaultCacheSync.h"
#import "YTXRestfulModelYTXRequestRemoteSync.h"

#import "YTXRestfulModel.h"

#import <Foundation/Foundation.h>

@interface YTXCollection : NSObject

@property (nonnull, nonatomic, assign) Class modelClass;
@property (nonnull, nonatomic, strong, readonly) NSArray * models;

@property (nonnull, nonatomic, strong) id<YTXCollectionCacheProtocol> cacheSync;
@property (nonnull, nonatomic, strong) id<YTXRestfulModelRemoteProtocol> remoteSync;


- (nonnull instancetype) initWithModelClass:(nonnull Class)modelClass;

- (nonnull instancetype) initWithModelClass:(nonnull Class)modelClass userDefaultSuiteName:(nullable NSString *) suiteName;

- (nonnull RACSignal *) fetchCache:(nullable NSDictionary *)param;

- (nonnull RACSignal *) saveCache:(nullable NSDictionary *)param;

- (nonnull RACSignal *) destroyCache:(nullable NSDictionary *)param;
/** GET */
- (nonnull RACSignal *) fetchCacheWithCacheKey:(nonnull NSString *)cacheKey withParam:(nullable NSDictionary *)param;
/** POST / PUT */
- (nonnull RACSignal *) saveCacheWithCacheKey:(nonnull NSString *)cacheKey withParam:(nullable NSDictionary *)param;
/** DELETE */
- (nonnull RACSignal *) destroyCacheWithCacheKey:(nonnull NSString *)cacheKey withParam:(nullable NSDictionary *)param;


/* RACSignal return Tuple( self, Arrary<Model> ) **/
- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param;

/* RACSignal return self **/
- (nonnull RACSignal *) fetchRemoteThenReset:(nullable NSDictionary *)param;

/* RACSignal return self **/
- (nonnull RACSignal *) fetchRemoteThenAdd:(nullable NSDictionary *)param;

- (nonnull NSArray *) transformerProxyOfReponse:(nonnull id) response;

/** 注入自己时使用 */
- (nonnull instancetype) removeAllModels;

- (nonnull instancetype) resetModels:(nonnull NSArray *) array;

- (nonnull instancetype) addModels:(nonnull NSArray *) array;

- (nonnull instancetype) insertFrontModels:(nonnull NSArray *) array;

- (nonnull instancetype) sortedArrayUsingComparator:(nonnull NSComparator)cmptr;

- (nullable NSArray *) arrayWithRange:(NSRange)range;

- (nullable YTXCollection *) collectionWithRange:(NSRange)range;

- (nullable YTXRestfulModel *) modelAtIndex:(NSInteger) index;

/** 主键可能是NSNumber或NSString，统一转成NSString来判断*/
- (nullable YTXRestfulModel *) modelWithPrimaryKey:(nonnull NSString *) primaryKey;

- (BOOL) addModel:(nonnull YTXRestfulModel *) model;

- (BOOL) insertFrontModel:(nonnull YTXRestfulModel *) model;

/** 插入到index之后*/
- (BOOL) insertModel:(nonnull YTXRestfulModel *) model afterIndex:(NSInteger) index;

/** 插入到index之前*/
- (BOOL) insertModel:(nonnull YTXRestfulModel *) model beforeIndex:(NSInteger) index;

- (BOOL) removeModelAtIndex:(NSInteger) index;

/** 主键可能是NSNumber或NSString，统一转成NSString来判断*/
- (BOOL) removeModelWithPrimaryKey:(nonnull NSString *) primaryKey;

- (BOOL) removeModelWithModel:(nonnull YTXRestfulModel *) model;

/** 逆序输出Collection*/
- (void) reverseModels;

@end
