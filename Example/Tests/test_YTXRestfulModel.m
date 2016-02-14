//
//  test_YTXRestfulModel.m
//  YTXRestfulModel
//
//  Created by Chuan on 1/25/16.
//  Copyright © 2016 caojun. All rights reserved.
//

#import "YTXTestCollection.h"

#import <Kiwi/Kiwi.h>
#import <YTXRequest/YTXRequest.h>

SPEC_BEGIN(YTXRestfulModelSpec)

describe(@"测试YTXRestfulModel", ^{
    context(@"初始化", ^{
        
        it(@"Model不为空", ^{
            YTXTestModel *testModel = [[YTXTestModel alloc] init];
            [[testModel should] beNonNil];
        });
        
        it(@"Collection不为空", ^{
            YTXTestCollection *testCollection = [[YTXTestCollection alloc] init];
            [[testCollection should] beNonNil];
        });
        
    });
    
    
    context(@"Collection功能", ^{
        
        [YTXRequestConfig sharedYTXRequestConfig].serviceKey = @"localhost";
    
        it(@"获取", ^{
            __block id ret;
            [[[YTXTestCollection shared] fetchRemote:@{ @"_limit": @"1"}] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {
//                NSLog(@"<ERROR> %@", error);
            }];
            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });
        
        it(@"增加", ^{
            __block YTXTestCollection *ret;
            [[[YTXTestCollection shared] fetchRemoteThenAdd:@{@"_start": @"1", @"_limit": @"1"}] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {
//                NSLog(@"<ERROR> %@", error);
            }];
            [[expectFutureValue(@(ret.models.count)) shouldEventually] equal:@(2)];
            [[expectFutureValue(ret.models.lastObject[@"id"]) shouldEventually] equal:@(2)];
        });
        
    });
    
    context(@"Model功能", ^{
        
        [YTXRequestConfig sharedYTXRequestConfig].serviceKey = @"localhost";
        
        __block YTXTestModel *testModel = [[YTXTestModel alloc] init];
        
        it(@"创建-Create-POST", ^{
            testModel.title = @"ytx test hahahaha";
            testModel.body = @"teststeststesettsetsetttsetttest";
            testModel.userId = @1;
            [[testModel saveRemote:nil] subscribeNext:^(YTXTestModel *responseModel) {
//                NSLog(@"<SUCCESS> %@", responseModel);
            } error:^(NSError *error) {
//                NSLog(@"<ERROR> %@", error);
            }];
            [[expectFutureValue(testModel.keyId) shouldEventually] beNonNil];
        });
        
        it(@"更新-Save-PUT，使用parameters", ^{
            [[testModel saveRemote:@{ @"title": @"更新了" }] subscribeNext:^(YTXTestModel *responseModel) {
//                NSLog(@"<SUCCESS> %@", responseModel);
            } error:^(NSError *error) {
//                NSLog(@"<ERROR> %@", error);
            }];
            [[expectFutureValue(testModel.title) shouldEventually] equal:@"更新了"];
        });
        
        it(@"更新-Save-PUT，使用更改model更新", ^{
            testModel.title = @"又一次更新了";
            __block NSNumber * result = nil;
            [[testModel saveRemote:nil] subscribeNext:^(YTXTestModel *responseModel) {
                result = @(1);
//                NSLog(@"<SUCCESS> %@", responseModel);
            } error:^(NSError *error) {
//                NSLog(@"<ERROR> %@", error);
            }];
            [[expectFutureValue(result) shouldEventually] beNonNil];
            [[expectFutureValue(testModel.title) shouldEventually] equal:@"又一次更新了"];
        });
        
        it(@"更新-Save-PUT，混合使用parameters和更改model更新", ^{
            testModel.title = @"Hello World";
            __block NSNumber * result = nil;
            [[testModel saveRemote:@{@"body": @"I Love You"}] subscribeNext:^(YTXTestModel *responseModel) {
                result = @(1);
//                NSLog(@"<SUCCESS> %@", responseModel);
            } error:^(NSError *error) {
//                NSLog(@"<ERROR> %@", error);
            }];
            [[expectFutureValue(result) shouldEventually] beNonNil];
            [[expectFutureValue(testModel.title) shouldEventually] equal:@"Hello World"];
            [[expectFutureValue(testModel.body) shouldEventually] equal:@"I Love You"];
        });
        
        it(@"responseModel和testModel是否是同一个指针地址", ^{
            __block YTXTestModel * testResponseModel = nil;
            [[testModel saveRemote:@{ @"title": @"同一个" }] subscribeNext:^(YTXTestModel *responseModel) {
                testResponseModel =  responseModel;
//                NSLog(@"<SUCCESS> %@", responseModel);
            } error:^(NSError *error) {
//                NSLog(@"<ERROR> %@", error);
            }];
            [[expectFutureValue(testResponseModel) shouldEventually] equal:testModel];
        });
        
        it(@"拉取-Fetch-GET", ^{
            __block YTXTestModel * currentTestModel = [[YTXTestModel alloc] init];
            currentTestModel.keyId = testModel.keyId;
            [[currentTestModel fetchRemote:nil] subscribeNext:^(YTXTestModel *responseModel) {
//                NSLog(@"<SUCCESS> %@", responseModel);
            } error:^(NSError *error) {
//                NSLog(@"<ERROR> %@", error);
            }];
            [[expectFutureValue(currentTestModel.title) shouldEventually] beNonNil];
        });
        
        
        it(@"使用Model属性获取外联model", ^{
            __block YTXTestModel * currentTestModel = [[YTXTestModel alloc] init];
            __block id ret;
            currentTestModel.keyId = @1;
            [[currentTestModel fetchRemoteForeignWithName:@"comments" modelClass:[YTXTestCommentModel class] param:nil] subscribeNext:^(id x) {
                ret = x;
//                NSLog(@"<SUCCESS> %@", x);
            } error:^(NSError *error) {
//                NSLog(@"<ERROR> %@", error);
            }];
            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });
        
        it(@"使用parameters 使用mantle map后的属性名keyId获取外联model", ^{
            __block YTXTestModel * currentTestModel = [[YTXTestModel alloc] init];
            __block id ret;
            [[currentTestModel fetchRemoteForeignWithName:@"comments" modelClass:[YTXTestCommentModel class] param:@{@"keyId": @1}] subscribeNext:^(id x) {
                ret = x;
                //                NSLog(@"<SUCCESS> %@", x);
            } error:^(NSError *error) {
                //                NSLog(@"<ERROR> %@", error);
            }];
            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });
        
        it(@"使用parameters 不使用mantle map后的属性而用服务器属性名id获取外联model", ^{
            __block YTXTestModel * currentTestModel = [[YTXTestModel alloc] init];
            __block id ret;
            [[currentTestModel fetchRemoteForeignWithName:@"comments" modelClass:[YTXTestCommentModel class] param:@{@"id": @1}] subscribeNext:^(id x) {
                ret = x;
                //                NSLog(@"<SUCCESS> %@", x);
            } error:^(NSError *error) {
                //                NSLog(@"<ERROR> %@", error);
            }];
            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });
        
        it(@"删除-Destroy-Delete，回调成功", ^{
            __block NSNumber * result = nil;
            [[testModel destroyRemote:nil] subscribeNext:^(YTXTestModel *responseModel) {
                result = @(1);
//                NSLog(@"<SUCCESS> %@", responseModel);
            } error:^(NSError *error) {
//                NSLog(@"<ERROR> %@", error);
            }];
            [[expectFutureValue(result) shouldEventually] beNonNil];
        });
        
        it(@"删除-Destroy-Delete，确实删除成功", ^{
            __block YTXTestModel * currentTestModel = [[YTXTestModel alloc] init];

            [[currentTestModel fetchRemote:@{@"keyId": testModel.keyId}] subscribeNext:^(YTXTestModel *responseModel) {
                //                NSLog(@"<SUCCESS> %@", responseModel);
            } error:^(NSError *error) {
                //                NSLog(@"<ERROR> %@", error);
            }];
            [[expectFutureValue(currentTestModel.keyId) shouldEventually] beNil];
        });
    });
});

SPEC_END
