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
        
        [YTXRequestConfig sharedYTXRequestConfig].serviceKey = @"test";
    
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
        
    });
    
    context(@"model", ^{
        
        [YTXRequestConfig sharedYTXRequestConfig].serviceKey = @"test";
        
        it(@"model create remote POST", ^{
            YTXTestModel *testModel = [[YTXTestModel alloc] init];
            testModel.title = @"ytx test hahahaha";
            testModel.body = @"teststeststesettsetsetttsetttest";
            testModel.userId = @1;
            [[testModel saveRemote:nil] subscribeNext:^(id x) {
                NSLog(@"<SUCCESS> %@", x);
            } error:^(NSError *error) {
                NSLog(@"<ERROR> %@", error);
            }];
            [[expectFutureValue(testModel.keyId) shouldEventually] equal:@101];
        });
        
        it(@"model fetch remote", ^{
            __block YTXTestModel *ret = [[YTXTestModel alloc] init];
            ret.keyId = @2;
            [[ret fetchRemote:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {
                NSLog(@"<ERROR> %@", error);
            }];
            [[expectFutureValue(ret.keyId) shouldEventually] equal:@(2)];
        });
        
    });
});

SPEC_END
