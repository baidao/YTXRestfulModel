//
//  AFNetworkingRemoteSync.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/3/4.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import "YTXRestfulModelRemoteProtocol.h"

#import <Foundation/Foundation.h>

@class AFHTTPSessionManager;

@interface AFNetworkingRemoteSync : NSObject <YTXRestfulModelRemoteProtocol>

@property (nonnull, nonatomic, strong, readonly) AFHTTPSessionManager * requestSessionManager;

/** 超时时间 默认60 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

@property (nonnull, nonatomic, strong) NSURL * url;

/** 设置网络请求的地址，通过Block形式，每次访问都会重新执行，以处理shared中URL会变的情况。同时使用URL和URLBlock会优先使用Block */
@property (nullable, nonatomic, strong) NSURL * _Nonnull (^urlHookBlock)(void);

@property (nonnull, nonatomic, copy, readonly) NSString * primaryKey;

+ (nonnull instancetype) syncWithURL:(nonnull NSURL *)URL primaryKey:(nonnull NSString *) primaryKey;

+ (nonnull instancetype) syncWithPrimaryKey:(nonnull NSString *) primaryKey;

+ (nullable YTXRestfulModelRemoteHookExtraParamBlock) hookExtraParamBlock;

+ (void) setHookExtraParamBlock:(nullable YTXRestfulModelRemoteHookExtraParamBlock) hookExtraParamBlock;

+ (nullable YTXRestfulModelRemoteHookRequestBlock) hookRequestBlock;

+ (void) setHookRequestBlock:(nullable YTXRestfulModelRemoteHookRequestBlock) hookRequestBlock;

- (nonnull instancetype) initWithURL:(nonnull NSURL *)URL primaryKey:(nonnull NSString *) primaryKey;

- (nonnull instancetype) initWithPrimaryKey:(nonnull NSString *) primaryKey;

/** GET :id/commont */
- (void) fetchRemoteForeignWithName:(nonnull NSString *)name param:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed;

/** GET */
- (void) fetchRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed;

/** POST */
- (void) createRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed;

/** put */
- (void) updateRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed;

/** DELETE */
- (void) destroyRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed;

@end
