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
- (nonnull RACSignal *) fetchRemoteForeignWithName:(nonnull NSString *)name param:(nullable NSDictionary *)param
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self);
        YTXRequest * request = [YTXRequest requestWithNSURL:[[self restfulURLWithParam:param] URLByAppendingPathComponent:name] AndRequestMethod:YTKRequestMethodGet];
        request.timeoutInterval = _timeoutInterval;
        [self _sendWithParametersWithRequest:request parameters:param subscriber:subscriber];
        return nil;
    }];
}

/** GET */
- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self);
        YTXRequest * request = [YTXRequest requestWithNSURL:[self restfulURLWithParam:param] AndRequestMethod:YTKRequestMethodGet];
        request.timeoutInterval = _timeoutInterval;
        [self _sendWithParametersWithRequest:request parameters:param subscriber:subscriber];
        return nil;
    }];
}

/** POST */
- (nonnull RACSignal *) createRemote:(nullable NSDictionary *)param
{
    @weakify(self);
    //TODO: 暂且copy如果发现并没有什么特殊性的话，应当抽成一个方法，只是改变YTKRequestMethod
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self);
        YTXRequest * request = [YTXRequest requestWithNSURL:self.url AndRequestMethod:YTKRequestMethodPost];
        request.timeoutInterval = _timeoutInterval;
        [self _sendWithParametersWithRequest:request parameters:param subscriber:subscriber];
        return nil;
    }];
}

/** PUT */
- (nonnull RACSignal *) updateRemote:(nullable NSDictionary *)param
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self);
        YTXRequest * request = [YTXRequest requestWithNSURL:[self restfulURLWithParam:param] AndRequestMethod:YTKRequestMethodPut];
        request.timeoutInterval = _timeoutInterval;
        [self _sendWithParametersWithRequest:request parameters:param subscriber:subscriber];
        return nil;
    }];
}

/** DELETE */
- (nonnull RACSignal *) destroyRemote:(nullable NSDictionary *)param
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self);
        YTXRequest * request = [YTXRequest requestWithNSURL:[self restfulURLWithParam:param] AndRequestMethod:YTKRequestMethodDelete];
        request.timeoutInterval = _timeoutInterval;
        [self _sendWithParametersWithRequest:request parameters:param subscriber:subscriber];
        return nil;
    }];
}

#pragma mark - function
- (NSError *) errorWithYTXRequest:(YTXRequest *) request
{
    return [NSError errorWithDomain:RestFulDomain code:request.responseStatusCode userInfo:request.userInfo];
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

- (void) _sendWithParametersWithRequest:(YTXRequest *)request parameters:(NSDictionary *)param subscriber:(id<RACSubscriber>) subscriber
{
    [request sendWithParameters:[self restfulParamWithParam:param] success:^(id response) {
        [subscriber sendNext:response];
        [subscriber sendCompleted];
    } failure:^(YTXRequest *request) {
        [subscriber sendError:[self errorWithYTXRequest:request]];
    }];
}

@end
