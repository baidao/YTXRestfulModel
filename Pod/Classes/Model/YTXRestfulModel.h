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
@property (nonnull, nonatomic, strong) id<YTXRestfulModelYTXRequestRemoteProtocol> remoteSync;


+ (nonnull instancetype) shared;
- (nonnull instancetype) mergeWithAnother:(_Nonnull id) model;

/** 要用keyId判断 */
- (BOOL) isNew;

/** 需要告诉我主键是什么，子类也应当实现 */
- (nonnull NSString *) primaryKey;

- (nonnull RACSignal *) fetchCache:(nullable NSDictionary *)param;

- (nonnull RACSignal *) saveCache:(nullable NSDictionary *)param;
/** DELETE */
- (nonnull RACSignal *) destroyCache:(nullable NSDictionary *)param;


@property (nullable, nonatomic, strong) NSURL * url;

/** 在拉到数据转mantle的时候用 */
- (nonnull instancetype) transformerProxyOfReponse:(nonnull id) response;

- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param;

- (nonnull RACSignal *) saveRemote:(nullable NSDictionary *)param;
/** DELETE */
- (nonnull RACSignal *) destroyRemote:(nullable NSDictionary *)param;

@end
