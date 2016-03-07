//
//  test_YTXRestfulModelRemote.m
//  YTXRestfulModelRemote
//
//  Created by Chuan on 1/25/16.
//  Copyright © 2016 caojun. All rights reserved.
//

#import "YTXTestAFNetworkingRemoteCollection.h"

#import <Kiwi/Kiwi.h>

#import <YTXRestfulModel/AFNetworkingRemoteSync.h>

SPEC_BEGIN(YTXRestfulModelAFNetworkingRemoteSpec)

// npm install -g json-server
// json-server db.json

describe(@"测试YTXRestfulModelRemote", ^{
    context(@"初始化", ^{

        it(@"Model不为空", ^{
            YTXTestAFNetworkingRemoteModel *testModel = [[YTXTestAFNetworkingRemoteModel alloc] init];
            [[testModel should] beNonNil];
        });

        it(@"修改Model的URL，在没有HookBlock时才能修改，HookBlock的优先级更高", ^{
            YTXTestAFNetworkingRemoteModel *testModel = [[YTXTestAFNetworkingRemoteModel alloc] init];

            testModel.remoteSync.urlHookBlock = nil;

            testModel.remoteSync.url = [NSURL URLWithString:@"http://www.baidu.com/"];

            [[testModel.remoteSync.url should] equal:[NSURL URLWithString:@"http://www.baidu.com/"]];

            testModel.remoteSync.urlHookBlock = ^NSURL * _Nonnull{
                return [NSURL URLWithString:@"http://www.google.com/"];
            };

            [[testModel.remoteSync.url should] equal:[NSURL URLWithString:@"http://www.google.com/"]];

            testModel.remoteSync.url = [NSURL URLWithString:@"http://www.bing.com/"];

            [[testModel.remoteSync.url should] equal:[NSURL URLWithString:@"http://www.google.com/"]];

            [[testModel.remoteSync.url shouldNot] equal:[NSURL URLWithString:@"http://www.bing.com/"]];
        });

        it(@"使用URLHookBlock方式注入Model的remoteSync.url", ^{
            YTXTestAFNetworkingRemoteModel *testModel = [[YTXTestAFNetworkingRemoteModel alloc] init];
            [[NSUserDefaults standardUserDefaults] setObject:@"http://www.baidu.com/" forKey:@"URLHookBlock"];

            testModel.remoteSync.urlHookBlock = ^NSURL * _Nonnull{
                return [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] valueForKey:@"URLHookBlock"]];
            };

            [[testModel.remoteSync.url should] equal:[NSURL URLWithString:@"http://www.baidu.com/"]];

            [[NSUserDefaults standardUserDefaults] setObject:@"http://www.google.com/" forKey:@"URLHookBlock"];

            [[testModel.remoteSync.url should] equal:[NSURL URLWithString:@"http://www.google.com/"]];
        });

        it(@"Collection不为空", ^{
            YTXTestAFNetworkingRemoteCollection *testCollection = [[YTXTestAFNetworkingRemoteCollection alloc] init];
            [[testCollection should] beNonNil];
        });

        it(@"修改Collection的URL，Collection初始化时没有使用HookBlock形式，可以直接修改，但是有HookBlock时会优先使用HookBlock", ^{
            YTXTestAFNetworkingRemoteCollection *testCollection = [[YTXTestAFNetworkingRemoteCollection alloc] init];
            testCollection.remoteSync.url = [NSURL URLWithString:@"http://www.baidu.com/"];

            [[testCollection.remoteSync.url should] equal:[NSURL URLWithString:@"http://www.baidu.com/"]];

            testCollection.remoteSync.urlHookBlock = ^NSURL * _Nonnull{
                return [NSURL URLWithString:@"http://www.google.com/"];
            };

            [[testCollection.remoteSync.url should] equal:[NSURL URLWithString:@"http://www.google.com/"]];

            testCollection.remoteSync.url = [NSURL URLWithString:@"http://www.bing.com/"];

            [[testCollection.remoteSync.url should] equal:[NSURL URLWithString:@"http://www.google.com/"]];

            [[testCollection.remoteSync.url shouldNot] equal:[NSURL URLWithString:@"http://www.bing.com/"]];
        });

        it(@"使用URLHookBlock方式注入Collection的remoteSync.url", ^{
            YTXTestAFNetworkingRemoteCollection *testCollection = [[YTXTestAFNetworkingRemoteCollection alloc] init];

            testCollection.remoteSync.urlHookBlock = ^NSURL * _Nonnull{
                return [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] valueForKey:@"URLHookBlock"]];
            };

            [[NSUserDefaults standardUserDefaults] setObject:@"http://www.baidu.com/" forKey:@"URLHookBlock"];

            [[testCollection.remoteSync.url should] equal:[NSURL URLWithString:@"http://www.baidu.com/"]];

            [[NSUserDefaults standardUserDefaults] setObject:@"http://www.google.com/" forKey:@"URLHookBlock"];

            [[testCollection.remoteSync.url should] equal:[NSURL URLWithString:@"http://www.google.com/"]];
        });
    });

    context(@"Collection功能，基本功能测试", ^{

        it(@"Models初始化长度为0", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            [[@( collection.models.count ) should] equal:@(0)];
        });

        it(@"重置Models", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            [collection resetModels:@[[YTXTestAFNetworkingRemoteModel new]]];
            [[@( collection.models.count ) should] equal:@(1)];
            [collection resetModels:@[[YTXTestAFNetworkingRemoteModel new], [YTXTestAFNetworkingRemoteModel new]]];
            [[@( collection.models.count ) should] equal:@(2)];
        });

        it(@"添加Models", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            [collection addModels:@[[YTXTestAFNetworkingRemoteModel new], [YTXTestAFNetworkingRemoteModel new]]];
            [[@( collection.models.count ) should] equal:@(2)];
        });

        it(@"通过index查Model", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel * front = [YTXTestAFNetworkingRemoteModel new];
            YTXTestAFNetworkingRemoteModel * back = [YTXTestAFNetworkingRemoteModel new];
            YTXTestAFNetworkingRemoteModel * middle = [YTXTestAFNetworkingRemoteModel new];
            [collection resetModels:@[front, [YTXTestAFNetworkingRemoteModel new], middle, back ]];
            [[[collection modelAtIndex:0] should] equal:front];
            [[[collection modelAtIndex:collection.models.count-1] should] equal:back];
            [[[collection modelAtIndex:2] should] equal:middle];
            [[[collection modelAtIndex:collection.models.count] should] beNil];
            [[[collection modelAtIndex:-1] should] beNil];
        });
        
        it(@"输入错误的response会返回error", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            NSError * error = nil;
            [collection transformerProxyOfReponse:@{@"abc": @123} error:&error];
            [[error should] beNonNil];
        });
        
        it(@"在index之前插入Model", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model2 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model3 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            [collection insertModel:model1 beforeIndex:0];
            [[[collection modelAtIndex:0] should] equal:model1];

            [[@([collection insertModel:model2 beforeIndex:1]) should] equal:@(NO)];
            [[@( collection.models.count ) should] equal:@(1)];
            [[@([collection insertModel:model2 beforeIndex:-1]) should] equal:@(NO)];
            [[@( collection.models.count ) should] equal:@(1)];
            [[@([collection insertModel:model2 beforeIndex:0]) should] equal:@(YES)];
            [[@( collection.models.count ) should] equal:@(2)];
            [[[collection modelAtIndex:0] should] equal:model2];
            [[@([collection insertModel:model3 beforeIndex:1]) should] equal:@(YES)];
            [[@( collection.models.count ) should] equal:@(3)];
            [[[collection modelAtIndex:1] should] equal:model3];
        });

        it(@"向后插入Model", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model2 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model3 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            [collection insertModel:model1 afterIndex:0];
            [[[collection modelAtIndex:0] should] equal:model1];

            [[@([collection insertModel:model2 afterIndex:1]) should] equal:@(NO)];
            [[@( collection.models.count ) should] equal:@(1)];
            [[@([collection insertModel:model2 afterIndex:-1]) should] equal:@(NO)];
            [[@( collection.models.count ) should] equal:@(1)];
            [[@([collection insertModel:model2 afterIndex:0]) should] equal:@(YES)];
            [[@( collection.models.count ) should] equal:@(2)];
            [[[collection modelAtIndex:1] should] equal:model2];
            [[@([collection insertModel:model3 afterIndex:1]) should] equal:@(YES)];
            [[@( collection.models.count ) should] equal:@(3)];
            [[[collection modelAtIndex:2] should] equal:model3];
        });


        it(@"在最前面插入Model", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model2 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            [collection insertFrontModel:model1];
            [[[collection modelAtIndex:0] should] equal:model1];
            [collection insertFrontModel:model2];
            [[[collection modelAtIndex:0] should] equal:model2];
            [[@( collection.models.count ) should] equal:@(2)];
        });

        it(@"在最前面插入Models", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model2 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            [collection insertFrontModels:@[model1]];
            [[[collection modelAtIndex:0] should] equal:model1];
            [collection insertFrontModels:@[model2]];
            [[[collection modelAtIndex:0] should] equal:model2];
            [[@( collection.models.count ) should] equal:@(2)];
        });

        it(@"根据NSRange查找返回NSArray", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model2 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model3 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model4 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            [collection addModels:@[model1, model2, model3, model4]];
            // 其余超出范围的Range测试采用系统方法，所以只测一下三种情况
            [[@([collection arrayWithRange:NSMakeRange(1, 2)].count ) should] equal:@2];
            [[[[collection arrayWithRange:NSMakeRange(1, 2)] firstObject] should] equal:model2];
            [[[collection arrayWithRange:NSMakeRange(4, 2)] should] beNil];
        });

        it(@"根据NSRange查找返回YTXTestCollection", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model2 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model3 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model4 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            [collection addModels:@[model1, model2, model3, model4]];
            [[@([collection collectionWithRange:NSMakeRange(1, 2)].models.count ) should] equal:@2];
            [[[[collection collectionWithRange:NSMakeRange(1, 2)].models firstObject] should] equal:model2];
            [[[collection collectionWithRange:NSMakeRange(4, 2)] should] beNil];
        });

        it(@"根据PrimaryKey查找Model", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model1.keyId = @1;
            YTXTestAFNetworkingRemoteModel *model2 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model3 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model3.keyId = @3;
            YTXTestAFNetworkingRemoteModel *model4 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            [collection addModels:@[model1, model2, model3, model4]];
            [[[collection modelWithPrimaryKey:@"1"] should] equal:model1];
            [[[collection modelWithPrimaryKey:@"3"] should] equal:model3];
            [[[collection modelWithPrimaryKey:@"2"] should] beNil];
        });

        it(@"根据索引删除Model", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model1.keyId = @1;
            YTXTestAFNetworkingRemoteModel *model2 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model3 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model3.keyId = @3;
            YTXTestAFNetworkingRemoteModel *model4 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            [collection addModels:@[model1, model2, model3, model4]];
            [[@( [collection removeModelAtIndex:0] ) should] equal:@YES];
            [[[collection modelAtIndex:0] should] equal:model2];
            [[@( [collection removeModelAtIndex:4] ) should] equal:@NO];
            [[@( [collection removeModelAtIndex:2] ) should] equal:@YES];
            [[[collection modelAtIndex:1] should] equal:model3];
        });

        it(@"根据PrimaryKey删除Model", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model1.keyId = @1;
            YTXTestAFNetworkingRemoteModel *model2 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model3 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model3.keyId = @3;
            [collection addModels:@[model1, model2, model3]];
            [[@( [collection removeModelWithPrimaryKey:@"1"] ) should] equal:@YES];
            [[[collection modelWithPrimaryKey:@"1"] should] beNil];
            [[@( [collection removeModelWithPrimaryKey:@"12"]) should] equal:@NO];
        });

        it(@"根据Model删除Model", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model1.keyId = @1;
            YTXTestAFNetworkingRemoteModel *model2 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model3 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            [collection addModels:@[model1, model2, model3]];
            [[@( [collection removeModelWithModel:model1] ) should] equal:@YES];
            [[@( [collection removeModelWithModel:model1] ) should] equal:@NO];
            [[[collection modelWithPrimaryKey:@"1"] should] beNil];
        });

        it(@"删除所有Models", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            [collection removeAllModels];
            [[@( collection.models.count ) should] equal:@(0)];
        });

        it(@"获取逆序的Models", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model2 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model3 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            [collection addModels:@[model1, model2, model3]];
            [collection reverseModels];
            [[collection.models.firstObject should] equal:model3];
            [[collection.models.lastObject should] equal:model1];
            [[collection.models[1] should] equal:model2];
        });

        it(@"对Collection排序", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model1.keyId = @1;
            YTXTestAFNetworkingRemoteModel *model2 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model2.keyId = @2;
            YTXTestAFNetworkingRemoteModel *model3 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model3.keyId = @3;
            [collection addModels:@[model1, model2, model3]];
            [collection sortedArrayUsingComparator:^NSComparisonResult(YTXTestAFNetworkingRemoteModel * _Nonnull obj1, YTXTestAFNetworkingRemoteModel * _Nonnull obj2) {
                return obj1.keyId.integerValue < obj2.keyId.integerValue;
            }];
            [[collection.models.firstObject should] equal:model3];
            [[collection.models.lastObject should] equal:model1];
            [[collection.models[1] should] equal:model2];
        });

    });

    context(@"Collection功能，RemoteSync测试", ^{

        it(@"拉取数据", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            __block YTXTestAFNetworkingRemoteCollection *ret;
            __block NSArray *array;
            [[collection fetchRemote:@{@"_start": @"1", @"_limit": @"2"}] subscribeNext:^(RACTuple *x) {
                ret = x.first;
                array = x.second;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(@([array count])) shouldEventually] equal:@(2)];
            [[expectFutureValue(ret) shouldEventually] equal:collection];
        });

        it(@"拉取数据并重置自己的models", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
             __block YTXTestAFNetworkingRemoteCollection *ret;
            [collection addModel:[YTXTestAFNetworkingRemoteModel new]];

            [[@(collection.models.count) should] equal:@(1)];

            [[collection fetchRemoteThenReset:@{@"_start": @"1", @"_limit": @"2"}] subscribeNext:^(YTXTestAFNetworkingRemoteCollection * x) {
                 ret = x;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(@(collection.models.count)) shouldEventually] equal:@(2)];
            [[expectFutureValue(ret) shouldEventually] equal:collection];
        });

        it(@"拉取数据并增加自己的models", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            __block YTXTestAFNetworkingRemoteCollection *ret;
            [collection addModel:[YTXTestAFNetworkingRemoteModel new]];

            [[@(collection.models.count) should] equal:@(1)];

            [[collection fetchRemoteThenAdd:@{@"_start": @"1", @"_limit": @"2"}] subscribeNext:^(YTXTestAFNetworkingRemoteCollection * x) {
                ret = x;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(@(collection.models.count)) shouldEventually] equal:@(3)];
            [[expectFutureValue(ret) shouldEventually] equal:collection];
        });

        it(@"拉取数据失败进入error block，因为替换了错误URL", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            collection.remoteSync.url = [NSURL URLWithString:@"http://localhost:3000/wrongtest"];
            __block NSError *err = nil;
            __block NSArray *array = nil;
            [[collection fetchRemote:@{@"_start": @"1", @"_limit": @"2"}] subscribeNext:^(RACTuple *x) {
                array = x.second;
            } error:^(NSError *error) {
                err = error;
            }];
            [[expectFutureValue(array) shouldEventually] beNil];
            [[expectFutureValue(err) shouldEventually] beNonNil];
        });
        
        xit(@"拉取数据失败进入error block，因为把超时时间定为了0", ^{
            YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
            collection.remoteSync.timeoutInterval = 0;
            __block NSError *err = nil;
            __block NSArray *array = nil;
            [[collection fetchRemote:@{@"_start": @"1", @"_limit": @"2"}] subscribeNext:^(RACTuple *x) {
                array = x.second;
            } error:^(NSError *error) {
                err = error;
            }];
            [[expectFutureValue(array) shouldEventually] beNil];
            [[expectFutureValue(err) shouldEventually] beNonNil];
        });

    });

    context(@"Model功能", ^{
        __block YTXTestAFNetworkingRemoteModel *testModel = [[YTXTestAFNetworkingRemoteModel alloc] init];
        
        it(@"输入错误的response会返回error", ^{
            YTXTestAFNetworkingRemoteModel * currentTestModel = [[YTXTestAFNetworkingRemoteModel alloc] init];
            NSError * error = nil;
            [currentTestModel transformerProxyOfReponse:@1 error:&error];
            [[error should] beNonNil];
        });
        
        it(@"输入错误的Foreign会返回error", ^{
            YTXTestAFNetworkingRemoteModel * currentTestModel = [[YTXTestAFNetworkingRemoteModel alloc] init];
            NSError * error = nil;
            [currentTestModel transformerProxyOfForeign:[self class] reponse:@1 error:&error];
            [[error should] beNonNil];
        });
        
        it(@"创建-Create-POST", ^{
            testModel.title = @"ytx test hahahaha";
            testModel.body = @"teststeststesettsetsetttsetttest";
            testModel.userId = @1;
            [[testModel saveRemote:nil] subscribeNext:^(YTXTestAFNetworkingRemoteModel *responseModel) {

            } error:^(NSError *error) {

            }];
            [[expectFutureValue(testModel.keyId) shouldEventually] beNonNil];
        });

        it(@"更新-Save-PUT，使用parameters", ^{
            [[testModel saveRemote:@{ @"title": @"更新了" }] subscribeNext:^(YTXTestAFNetworkingRemoteModel *responseModel) {

            } error:^(NSError *error) {

            }];
            [[expectFutureValue(testModel.title) shouldEventually] equal:@"更新了"];
        });

        it(@"更新-Save-PUT，使用更改model更新", ^{
            testModel.title = @"又一次更新了";
            __block NSNumber * result = nil;
            [[testModel saveRemote:nil] subscribeNext:^(YTXTestAFNetworkingRemoteModel *responseModel) {
                result = @(1);

            } error:^(NSError *error) {

            }];
            [[expectFutureValue(result) shouldEventually] beNonNil];
            [[expectFutureValue(testModel.title) shouldEventually] equal:@"又一次更新了"];
        });

        it(@"更新-Save-PUT，混合使用parameters和更改model更新", ^{
            testModel.title = @"Hello World";
            __block NSNumber * result = nil;
            [[testModel saveRemote:@{@"body": @"I Love You"}] subscribeNext:^(YTXTestAFNetworkingRemoteModel *responseModel) {
                result = @(1);

            } error:^(NSError *error) {

            }];
            [[expectFutureValue(result) shouldEventually] beNonNil];
            [[expectFutureValue(testModel.title) shouldEventually] equal:@"Hello World"];
            [[expectFutureValue(testModel.body) shouldEventually] equal:@"I Love You"];
        });

        it(@"responseModel和testModel是否是同一个指针地址", ^{
            __block YTXTestAFNetworkingRemoteModel * testResponseModel = nil;
            [[testModel saveRemote:@{ @"title": @"同一个" }] subscribeNext:^(YTXTestAFNetworkingRemoteModel *responseModel) {
                testResponseModel =  responseModel;

            } error:^(NSError *error) {

            }];
            [[expectFutureValue(testResponseModel) shouldEventually] equal:testModel];
        });

        it(@"拉取-Fetch-GET", ^{
            __block YTXTestAFNetworkingRemoteModel * currentTestModel = [[YTXTestAFNetworkingRemoteModel alloc] init];
            currentTestModel.keyId = testModel.keyId;
            [[currentTestModel fetchRemote:nil] subscribeNext:^(YTXTestAFNetworkingRemoteModel *responseModel) {

            } error:^(NSError *error) {

            }];
            [[expectFutureValue(currentTestModel.title) shouldEventually] beNonNil];
        });


        it(@"使用Model属性获取外联model", ^{
            __block YTXTestAFNetworkingRemoteModel * currentTestModel = [[YTXTestAFNetworkingRemoteModel alloc] init];
            __block id ret;
            currentTestModel.keyId = @1;
            [[currentTestModel fetchRemoteForeignWithName:@"todos" modelClass:[YTXTestAFNetworkingRemoteToDoModel class] param:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });

        it(@"使用parameters 使用mantle map后的属性名keyId获取外联model", ^{
            __block YTXTestAFNetworkingRemoteModel * currentTestModel = [[YTXTestAFNetworkingRemoteModel alloc] init];
            __block id ret;
            [[currentTestModel fetchRemoteForeignWithName:@"todos" modelClass:[YTXTestAFNetworkingRemoteToDoModel class] param:@{@"keyId": @1}] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });

        it(@"使用parameters 不使用mantle map后的属性而用服务器属性名id获取外联model", ^{
            __block YTXTestAFNetworkingRemoteModel * currentTestModel = [[YTXTestAFNetworkingRemoteModel alloc] init];
            __block id ret;
            [[currentTestModel fetchRemoteForeignWithName:@"todos" modelClass:[YTXTestAFNetworkingRemoteToDoModel class] param:@{@"id": @1}] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });

        it(@"删除-Destroy-Delete，回调成功", ^{
            __block NSNumber * result = nil;
            [[testModel destroyRemote:nil] subscribeNext:^(YTXTestAFNetworkingRemoteModel *responseModel) {
                result = @(1);

            } error:^(NSError *error) {

            }];
            [[expectFutureValue(result) shouldEventually] beNonNil];
        });

        it(@"删除-Destroy-Delete，确实删除成功", ^{
            __block YTXTestAFNetworkingRemoteModel * currentTestModel = [[YTXTestAFNetworkingRemoteModel alloc] init];

            [[currentTestModel fetchRemote:@{@"keyId": testModel.keyId}] subscribeNext:^(YTXTestAFNetworkingRemoteModel *responseModel) {

            } error:^(NSError *error) {

            }];
            [[expectFutureValue(currentTestModel.keyId) shouldEventually] beNil];
        });

        it(@"拉取-Fetch-GET失败进入error block，因为替换了错误URL", ^{
            __block YTXTestAFNetworkingRemoteModel * currentTestModel = [[YTXTestAFNetworkingRemoteModel alloc] init];
            currentTestModel.keyId = testModel.keyId;
            currentTestModel.remoteSync.urlHookBlock = nil;
            currentTestModel.remoteSync.url = [NSURL URLWithString:@"http://localhost:3000/wrongtest"];

            __block NSNumber * result = nil;
            __block NSError * err = nil;

            [[currentTestModel fetchRemote:nil] subscribeNext:^(YTXTestAFNetworkingRemoteModel *responseModel) {
                result = @1;
            } error:^(NSError *error) {
                err = error;
            }];
            [[expectFutureValue(currentTestModel.title) shouldEventually] beNil];
            [[expectFutureValue(err) shouldEventually] beNonNil];
            [[expectFutureValue(result) shouldEventually] beNil];

        });
        
        xit(@"拉取-Fetch-GET失败进入error block，因为把超时时间定为了0", ^{
            __block YTXTestAFNetworkingRemoteModel * currentTestModel = [[YTXTestAFNetworkingRemoteModel alloc] init];
            currentTestModel.keyId = testModel.keyId;
            currentTestModel.remoteSync.timeoutInterval = 0;
            
            __block NSNumber * result = nil;
            __block NSError * err = nil;
            
            [[currentTestModel fetchRemote:nil] subscribeNext:^(YTXTestAFNetworkingRemoteModel *responseModel) {
                result = @1;
            } error:^(NSError *error) {
                err = error;
            }];
            [[expectFutureValue(currentTestModel.title) shouldEventually] beNil];
            [[expectFutureValue(err) shouldEventually] beNonNil];
            [[expectFutureValue(result) shouldEventually] beNil];
            
        });
    });
});

SPEC_END
