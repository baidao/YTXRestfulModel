//
//  YTXCollection.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import "YTXCollectionUserDefaultCacheSync.h"
#import "YTXRestfulModelYTXRequestRemoteSync.h"

#import <Foundation/Foundation.h>

@interface YTXCollection : NSObject

@property (nonnull, nonatomic, assign) Class modelClass;
@property (nonnull, nonatomic, strong) NSMutableArray * models;

@property (nonnull, nonatomic, strong) id<YTXCollectionCacheProtocol> cacheSync;
@property (nonnull, nonatomic, strong) id<YTXRestfulModelYTXRequestRemoteProtocol> remoteSync;

+ (nonnull instancetype) shared;

- (nonnull instancetype) initWithModelClass:(nonnull Class)modelClass;

- (nonnull RACSignal *) fetchCache:(nullable NSDictionary *)param;

- (nonnull RACSignal *) saveCache:(nullable NSDictionary *)param;

- (nonnull RACSignal *) destroyCache:(nullable NSDictionary *)param;


@property (nullable, nonatomic, strong) NSURL * url;

/* reset **/
- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param;

/* add **/
- (nonnull RACSignal *) fetchRemoteThenAdd:(nullable NSDictionary *)param;

/* insertFront **/
- (nonnull RACSignal *) fetchRemoteThenInsertFront:(nullable NSDictionary *)param;

- (nonnull NSArray *) transformerProxyOfReponse:(nonnull id) response;

/** 注入自己时使用 */
- (nonnull instancetype) resetSelf:(nonnull NSArray *) array;

- (nonnull instancetype) addSelf:(nonnull NSArray *) array;

- (nonnull instancetype) insertFrontSelf:(nonnull NSArray *) array;

@end
