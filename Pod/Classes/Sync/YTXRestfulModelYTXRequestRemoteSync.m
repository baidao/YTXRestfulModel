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

- (void)setUrl:(NSURL *)url
{
    _url = url;
}

/** GET */
- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param
{
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        [[YTXRequest requestWithNSURL:self.url AndRequestMethod:YTKRequestMethodGet] sendWithParameters:param success:^(id response) {
            [subscriber sendNext:response];
            [subscriber sendCompleted];
        } failure:^(YTXRequest *request) {
            [subscriber sendError:[self errorWithYTXRequest:request]];
        }];
        return nil;
    }];
}

/** POST */
- (nonnull RACSignal *) createRemote:(nullable NSDictionary *)param
{
    //TODO: 暂且copy如果发现并没有什么特殊性的话，应当抽成一个方法，只是改变YTKRequestMethod
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        [[YTXRequest requestWithNSURL:self.url AndRequestMethod:YTKRequestMethodPost] sendWithParameters:param success:^(id response) {
            [subscriber sendNext:response];
            [subscriber sendCompleted];
        } failure:^(YTXRequest *request) {
            [subscriber sendError:[self errorWithYTXRequest:request]];
        }];
        return nil;
    }];
}

/** put */
- (nonnull RACSignal *) updateRemote:(nullable NSDictionary *)param
{
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        [[YTXRequest requestWithNSURL:self.url AndRequestMethod:YTKRequestMethodPut] sendWithParameters:param success:^(id response) {
            [subscriber sendNext:response];
            [subscriber sendCompleted];
        } failure:^(YTXRequest *request) {
            [subscriber sendError:[self errorWithYTXRequest:request]];
        }];
        return nil;
    }];
}

/** DELETE */
- (nonnull RACSignal *) destroyRemote:(nullable NSDictionary *)param
{
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        [[YTXRequest requestWithNSURL:self.url AndRequestMethod:YTKRequestMethodDelete] sendWithParameters:param success:^(id response) {
            [subscriber sendNext:response];
            [subscriber sendCompleted];
        } failure:^(YTXRequest *request) {
            [subscriber sendError:[self errorWithYTXRequest:request]];
        }];
        return nil;
    }];
}

#pragma mark - function
- (NSError *) errorWithYTXRequest:(YTXRequest *) request;
{
    return [NSError errorWithDomain:RestFulDomain code:request.responseStatusCode userInfo:request.userInfo];
}

- (NSURL *) setupUrlWithPathNameOfYTXRequestJSON:(NSString * )pathName
{
    return [YTXRequest urlWithName:pathName];
}


@end
