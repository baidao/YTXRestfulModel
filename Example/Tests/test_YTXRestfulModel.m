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

describe(@"YTXRestfulModel tests", ^{
    
    context(@"initial", ^{
        
        it(@"initial model", ^{
            YTXTestModel *testModel = [[YTXTestModel alloc] init];
            [[testModel should] beNonNil];
        });
        
        it(@"initial collection", ^{
            YTXTestCollection *testCollection = [[YTXTestCollection alloc] init];
            [[testCollection should] beNonNil];
        });
        
    });
    
    
    context(@"collection", ^{
//        
//        [YTXRequestConfig sharedYTXRequestConfig].serviceKey = @"test";
//    
//        it(@"collection fetch remote", ^{
//            __block id ret;
//            [[[YTXTestCollection shared] fetchRemote:@{ @"_limit": @"10"}] subscribeNext:^(id x) {
//                ret = x;
//            } error:^(NSError *error) {
//                NSLog(@"<ERROR> %@", error);
//            }];
//            [[expectFutureValue(ret) shouldEventually] beNonNil];
//        });
//        
//        it(@"collection fetch remote then add", ^{
//            __block YTXTestCollection *ret;
//            [[[YTXTestCollection shared] fetchRemoteThenAdd:@{@"_start": @"10", @"_limit": @"10"}] subscribeNext:^(id x) {
//                ret = x;
//            } error:^(NSError *error) {
//                NSLog(@"<ERROR> %@", error);
//            }];
//            [[expectFutureValue(@(ret.models.count)) shouldEventually] equal:@(20)];
//            [[expectFutureValue(ret.models.lastObject[@"id"]) shouldEventually] equal:@(20)];
//        });
//        
    });
    
    context(@"model", ^{
        
        [YTXRequestConfig sharedYTXRequestConfig].serviceKey = @"local";
        
        __block NSNumber *keyId;
        
        it(@"model create remote POST", ^{
            YTXTestModel *testModel = [[YTXTestModel alloc] init];
            testModel.title = @"ytx test hahahaha";
            testModel.body = @"teststeststesettsetsetttsetttest";
            testModel.userId = @1;
            [[testModel saveRemote:nil] subscribeNext:^(YTXTestModel *responseModel) {
                keyId = testModel.keyId;
                NSLog(@"<SUCCESS> %@", responseModel);
            } error:^(NSError *error) {
                NSLog(@"<ERROR> %@", error);
            }];
            [[expectFutureValue(testModel.keyId) shouldEventually] beNonNil];
        });
        
        it(@"model update remote PUT", ^{
            __block YTXTestModel *testModel = [[YTXTestModel alloc] init];
            testModel.keyId = keyId;
            testModel.title = @"ytx test hahahaha";
            testModel.body = @"改过了";
            testModel.userId = @1;
            [[testModel saveRemote:nil] subscribeNext:^(YTXTestModel *responseModel) {
                testModel = responseModel;
                NSLog(@"<SUCCESS> %@", responseModel);
            } error:^(NSError *error) {
                NSLog(@"<ERROR> %@", error);
            }];
            [[expectFutureValue(testModel.body) shouldEventually] equal:@"改过了"];
        });
        
        it(@"model fetch remote GET", ^{
            __block YTXTestModel *testModel = [[YTXTestModel alloc] init];
            testModel.keyId = keyId;
            [[testModel fetchRemote:nil] subscribeNext:^(YTXTestModel *responseModel) {
                testModel = responseModel;
                NSLog(@"<SUCCESS> %@", responseModel);
            } error:^(NSError *error) {
                NSLog(@"<ERROR> %@", error);
            }];
            [[expectFutureValue(testModel.keyId) shouldEventually] equal:keyId];
        });
        
        
        it(@"model delete remote DELETE", ^{
            __block YTXTestModel *testModel = [[YTXTestModel alloc] init];
            testModel.keyId = keyId;
            [[testModel destroyRemote:nil] subscribeNext:^(YTXTestModel *responseModel) {
                testModel = responseModel;
                NSLog(@"<SUCCESS> %@", responseModel);
            } error:^(NSError *error) {
                NSLog(@"<ERROR> %@", error);
            }];
            [[expectFutureValue(testModel.keyId) shouldEventually] equal:keyId];
        });
    });
});

SPEC_END
