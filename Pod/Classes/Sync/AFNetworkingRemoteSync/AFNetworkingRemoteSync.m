//
//  AFNetworkingRemoteSync.m
//  YTXRestfulModel
//
//  Created by CaoJun on 16/3/4.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import "AFNetworkingRemoteSync.h"

#import <AFNetworking/AFNetworking.h>

static YTXRestfulModelRemoteHookExtraParamBlock __hookExtraParamBlock;

static YTXRestfulModelRemoteHookRequestBlock __hookRequestBlock;

static NSString *const RestFulDomain = @"AFNetworkingRemoteSync"; //error domain

@interface AFNetworkingRemoteSync()

@property (nonnull, nonatomic, strong) AFHTTPSessionManager * requestSessionManager;

@end

@implementation AFNetworkingRemoteSync

- (NSURL *)url {
    if (self.urlHookBlock) {
        return self.urlHookBlock();
    }
    return _url;
}

+ (nonnull instancetype) syncWithURL:(nonnull NSURL *)URL primaryKey:(nonnull NSString *) primaryKey
{
    return [[self alloc] initWithURL:URL primaryKey:primaryKey];
}

+ (nonnull instancetype) syncWithPrimaryKey:(nonnull NSString *) primaryKey
{
    return [[self alloc] initWithPrimaryKey:primaryKey];
}

+ (nullable YTXRestfulModelRemoteHookExtraParamBlock) hookExtraParamBlock
{
    return __hookExtraParamBlock;
}

+ (void) setHookExtraParamBlock:(nullable YTXRestfulModelRemoteHookExtraParamBlock)hookExtraParamBlock
{
    __hookExtraParamBlock = hookExtraParamBlock;
}

+ (nullable YTXRestfulModelRemoteHookRequestBlock) hookRequestBlock
{
    return __hookRequestBlock;
}

+ (void) setHookRequestBlock:(nullable YTXRestfulModelRemoteHookRequestBlock) hookRequestBlock
{
    __hookRequestBlock = hookRequestBlock;
}

- (nonnull instancetype) initWithURL:(nonnull NSURL *)URL primaryKey:(nonnull NSString *) primaryKey
{
    if (self = [super init]) {
        _url = URL;
        _primaryKey = primaryKey;
        _timeoutInterval = 60;
        self.requestSessionManager.requestSerializer.timeoutInterval = _timeoutInterval;
    }
    return self;
}

- (nonnull instancetype) initWithPrimaryKey:(nonnull NSString *) primaryKey
{
    if (self = [super init]) {
        _primaryKey = primaryKey;
        _timeoutInterval = 60;
        self.requestSessionManager.requestSerializer.timeoutInterval = _timeoutInterval;
    }
    return self;
}

/** GET :id/comment */
- (void) fetchRemoteForeignWithName:(nonnull NSString *)name param:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed
{
    NSURL * url = [[self restfulURLWithParam:param] URLByAppendingPathComponent:name];
    NSMutableDictionary * newParam = [[self restfulParamWithParam:param] mutableCopy];
    
    if (AFNetworkingRemoteSync.hookRequestBlock) {
        AFNetworkingRemoteSync.hookRequestBlock(self, @"GET", &url, &newParam);
    }
    
    [self.requestSessionManager GET:[url absoluteString] parameters:newParam success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failed(error);
    }];
}

/** GET */
- (void) fetchRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed
{
    NSURL * url = [self restfulURLWithParam:param];
    NSMutableDictionary * newParam = [[self restfulParamWithParam:param] mutableCopy];
    
    if (AFNetworkingRemoteSync.hookRequestBlock) {
        AFNetworkingRemoteSync.hookRequestBlock(self, @"GET", &url, &newParam);
    }
    
    [self.requestSessionManager GET:[url absoluteString] parameters:newParam success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failed(error);
    }];
}

/** POST */
- (void) createRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed
{
    NSURL * url = [self restfulURLWithParam:param];
    NSMutableDictionary * newParam = [[self restfulParamWithParam:param] mutableCopy];
    
    if (AFNetworkingRemoteSync.hookRequestBlock) {
        AFNetworkingRemoteSync.hookRequestBlock(self, @"POST", &url, &newParam);
    }
    
    [self.requestSessionManager POST:[url absoluteString] parameters:newParam success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failed(error);
    }];
}

/** PUT */
- (void) updateRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed
{
    NSURL * url = [self restfulURLWithParam:param];
    NSMutableDictionary * newParam = [[self restfulParamWithParam:param] mutableCopy];
    
    if (AFNetworkingRemoteSync.hookRequestBlock) {
        AFNetworkingRemoteSync.hookRequestBlock(self, @"PUT", &url, &newParam);
    }
    
    [self.requestSessionManager PUT:[url absoluteString] parameters:newParam success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failed(error);
    }];
}

/** DELETE */
- (void) destroyRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed
{
    NSURL * url = [self restfulURLWithParam:param];
    NSMutableDictionary * newParam = [[self restfulParamWithParam:param] mutableCopy];
    
    if (AFNetworkingRemoteSync.hookRequestBlock) {
        AFNetworkingRemoteSync.hookRequestBlock(self, @"DELETE", &url, &newParam);
    }
    
    [self.requestSessionManager DELETE:[url absoluteString] parameters:newParam success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failed(error);
    }];
}

#pragma mark - function

- (NSURL *) restfulURLWithParam:(NSDictionary *)param
{
    NSURL *url = [self.url copy];
    id primaryKey = param[self.primaryKey];
    if (primaryKey) {
        url = [url URLByAppendingPathComponent:[primaryKey description]];
    }
    return url;
}

- (NSDictionary *) restfulParamWithParam:(NSDictionary *)param
{
    NSMutableDictionary *retParam = [NSMutableDictionary dictionaryWithDictionary:AFNetworkingRemoteSync.hookExtraParamBlock != nil ? AFNetworkingRemoteSync.hookExtraParamBlock() : @{}];
    
    for (NSString * key in param) {
        [retParam setObject:param[key] forKey:key];
    }
    
    if (self.primaryKey) {
        [retParam removeObjectForKey:self.primaryKey];
    }
    return retParam;
}

- (nonnull AFHTTPSessionManager *) requestSessionManager
{
    if (!_requestSessionManager) {
        _requestSessionManager = [AFHTTPSessionManager manager];
    }
    return _requestSessionManager;
}

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval
{
    _timeoutInterval = timeoutInterval;
    self.requestSessionManager.requestSerializer.timeoutInterval = _timeoutInterval;
}

@end
