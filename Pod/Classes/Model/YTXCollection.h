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
@property (nonnull, nonatomic, strong) id<YTXRestfulModelRemoteProtocol> remoteSync;

+ (nonnull instancetype) shared;

- (nonnull instancetype) initWithModelClass:(nonnull Class)modelClass;

- (nonnull instancetype) initWithModelClass:(nonnull Class)modelClass userDefaultSuiteName:(nullable NSString *) suiteName;

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
- (nonnull instancetype) resetModels:(nonnull NSArray *) array;

- (nonnull instancetype) addModels:(nonnull NSArray *) array;

- (nonnull instancetype) insertFrontModels:(nonnull NSArray *) array;

@end
