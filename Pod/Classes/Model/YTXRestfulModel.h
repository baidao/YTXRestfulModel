//
//  YTXModel.h
//  YTXRestfulModel
//
//  Created by cao jun on 16/01/25.
//  Copyright © 2015 Elephants Financial Service. All rights reserved.
//

#import "YTXRestfulModelProtocol.h"
#import "YTXRestfulModelUserDefaultCacheSync.h"
#import "YTXRestfulModelYTXRequestRemoteSync.h"

#import <Mantle/Mantle.h>
#import <Foundation/Foundation.h>

@interface YTXRestfulModel : MTLModel <YTXRestfulModelProtocol, MTLJSONSerializing>

@property (nonnull, nonatomic, strong) id<YTXRestfulModelUserDefaultCacheProtocol> cacheSync;
@property (nonnull, nonatomic, strong) id<YTXRestfulModelRemoteProtocol> remoteSync;


- (nonnull instancetype) mergeWithAnother:(_Nonnull id) model;

/** 要用keyId判断 */
- (BOOL) isNew;

/** 需要告诉我主键是什么，子类也应当实现 */
- (nonnull NSString *) primaryKey;

/** 方便的直接取主键的值*/
- (nullable id) primaryValue;

- (nonnull RACSignal *) fetchCache:(nullable NSDictionary *)param;

- (nonnull RACSignal *) saveCache:(nullable NSDictionary *)param;
/** DELETE */
- (nonnull RACSignal *) destroyCache:(nullable NSDictionary *)param;

- (nonnull RACSignal *) fetchCacheWithCacheKey:(nonnull NSString *)cachekey withParam:(nullable NSDictionary *)param;

- (nonnull RACSignal *) saveCacheWithCacheKey:(nonnull NSString *)cachekey withParam:(nullable NSDictionary *)param;
/** DELETE */
- (nonnull RACSignal *) destroyCacheWithCacheKey:(nonnull NSString *)cachekey withParam:(nullable NSDictionary *)param;

/** 在拉到数据转mantle的时候用 */
- (nonnull instancetype) transformerProxyOfReponse:(nonnull id) response error:(NSError * _Nullable * _Nullable) error;

/** 在拉到数据转外部mantle对象的时候用 */
- (nonnull id) transformerProxyOfForeign:(nonnull Class)modelClass reponse:(nonnull id) response error:(NSError * _Nullable * _Nullable) error;

/** 将自身转化为Dictionary，然后对传入参数进行和自身属性的融合。自身的属性优先级最高，不可被传入参数修改。 */
- (nonnull NSDictionary *)mergeSelfAndParameters:(nullable NSDictionary *)param;

/** :id/comment 这种形式的时候使用GET; modelClass is MTLModel*/
- (nonnull RACSignal *) fetchRemoteForeignWithName:(nonnull NSString *)name modelClass:(nonnull Class)modelClass param:(nullable NSDictionary *)param;

- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param;

- (nonnull RACSignal *) saveRemote:(nullable NSDictionary *)param;
/** DELETE */
- (nonnull RACSignal *) destroyRemote:(nullable NSDictionary *)param;

@end
