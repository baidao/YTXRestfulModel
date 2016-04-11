//
//  YTXRestfulModelRemoteSync.m
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import "YTXRestfulModelYTXRequestRemoteSync.h"

#import <YTXRequest/YTXRequest.h>

static NSString *const RestFulDomain = @"YTXRestfulModelRemoteSync"; //error domain

@implementation YTXRestfulModelYTXRequestRemoteSync

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
    return [YTXRequestConfig sharedYTXRequestConfig].hookExtraParamBlock;
}

+ (void) setHookExtraParamBlock:(nullable YTXRestfulModelRemoteHookExtraParamBlock) hookExtraParamBlock
{
    [YTXRequestConfig sharedYTXRequestConfig].hookExtraParamBlock = hookExtraParamBlock;
}

- (nonnull instancetype) initWithURL:(nonnull NSURL *)URL primaryKey:(nonnull NSString *) primaryKey
{
    if (self = [super init]) {
        _url = URL;
        _primaryKey = primaryKey;
        _timeoutInterval = 60;
    }
    return self;
}

- (nonnull instancetype) initWithPrimaryKey:(nonnull NSString *) primaryKey
{
    if (self = [super init]) {
        _primaryKey = primaryKey;
        _timeoutInterval = 60;
    }
    return self;
}

/** GET :id/comment */
- (void) fetchRemoteForeignWithName:(nonnull NSString *)name param:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed
{
    YTXRequest * request = [YTXRequest requestWithNSURL:[[self restfulURLWithParam:param] URLByAppendingPathComponent:name] AndRequestMethod:YTXRequestMethodGet];
    [self _sendWithParametersWithRequest:request parameters:param success:success failed:failed];
}

/** GET */
- (void) fetchRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed
{
    YTXRequest * request = [YTXRequest requestWithNSURL:[self restfulURLWithParam:param] AndRequestMethod:YTXRequestMethodGet];
    [self _sendWithParametersWithRequest:request parameters:param success:success failed:failed];
}

/** POST */
- (void) createRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed
{
    YTXRequest * request = [YTXRequest requestWithNSURL:self.url AndRequestMethod:YTXRequestMethodPost];
    [self _sendWithParametersWithRequest:request parameters:param success:success failed:failed];
}

/** PUT */
- (void) updateRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed
{
    YTXRequest * request = [YTXRequest requestWithNSURL:[self restfulURLWithParam:param] AndRequestMethod:YTXRequestMethodPut];
    [self _sendWithParametersWithRequest:request parameters:param success:success failed:failed];
}

/** DELETE */
- (void) destroyRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed
{
    YTXRequest * request = [YTXRequest requestWithNSURL:[self restfulURLWithParam:param] AndRequestMethod:YTXRequestMethodDelete];
    [self _sendWithParametersWithRequest:request parameters:param success:success failed:failed];
}

#pragma mark - function
- (NSError *) errorWithYTXRequest:(YTXRequest *) request
{
    return [NSError errorWithDomain:RestFulDomain code:request.responseStatusCode userInfo:@{@"message": request.responseJSONObject[@"msg"] ?: @"请求失败"}];
}

- (NSURL *) setupUrlWithPathNameOfYTXRequestJSON:(NSString * )pathName
{
    return [YTXRequest urlWithName:pathName];
}

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
    NSMutableDictionary *retParam = [param mutableCopy];
    if (self.primaryKey) {
        [retParam removeObjectForKey:self.primaryKey];
    }
    return retParam;
}

- (void) _sendWithParametersWithRequest:(YTXRequest *)request parameters:(NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed
{
    request.timeoutInterval = _timeoutInterval;
    [request sendWithParameters:[self restfulParamWithParam:param] success:^(id response) {
        success(response);
    } failure:^(YTXRequest *request) {
        failed([self errorWithYTXRequest:request]);
    }];
}

@end
