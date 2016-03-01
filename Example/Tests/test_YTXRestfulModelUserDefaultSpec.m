//
//  test_YTXRestfulModelUserDefaultSpec.m
//  YTXRestfulModel
//
//  Created by zhanglu on 16/2/15.
//  Copyright 2016年 caojun. All rights reserved.
//

#import "YTXTestCollection.h"

#import <Kiwi/Kiwi.h>
#import <YTXRequest/YTXRequest.h>

#import <YTXRestfulModel/YTXRestfulModelUserDefaultStorageSync.h>

static NSString * suitName1 = @"com.baidao.test";
static NSString * suitName2 = @"com.baidao.ppp";
static NSString * suitName3 = @"com.baidao.test1";
static NSString * suitName4 = @"com.baidao.ppp2";

SPEC_BEGIN(YTXRestfulModelUserDefaultSpec)

describe(@"测试YTXRestfulModelUserDefaultStorageSync", ^{
    static NSString * storagModelKey1 = @"TestStorageModelKey1";
    static NSString * storagModelKey2 = @"TestStorageModelKey2";
    static NSString * storagModelKey3 = @"TestStorageModelKey3";
    
    context(@"Model同步功能", ^{
        beforeAll(^{
            //清空以便测试
            YTXTestModel *model1 = [YTXTestModel new];
            model1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName1];
            
            YTXTestModel *model2 = [YTXTestModel new];
            model2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName2];
            
            YTXTestModel *model3 = [YTXTestModel new];
            
            [model1 destroyStorageSyncWithKey:storagModelKey1 param:nil];
            [model2 destroyStorageSyncWithKey:storagModelKey2 param:nil];
            [model3 destroyStorageSyncWithKey:storagModelKey3 param:nil];
            
        });
        
        afterAll(^{
            //清空以便测试
            YTXTestModel *model1 = [YTXTestModel new];
            model1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName1];
            
            YTXTestModel *model2 = [YTXTestModel new];
            model2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName2];
            
            YTXTestModel *model3 = [YTXTestModel new];
            
            [model1 destroyStorageSyncWithKey:storagModelKey1 param:nil];
            [model2 destroyStorageSyncWithKey:storagModelKey2 param:nil];
            [model3 destroyStorageSyncWithKey:storagModelKey3 param:nil];
            
        });
        
        it(@"保存缓存成功，使用storageKey", ^{
            YTXTestModel *model = [YTXTestModel new];
            YTXTestModel *ret = [model saveStorageSyncWithKey:@"key1" param:nil];

            [[ret should] equal:model];
        });
        
        it(@"获取缓存成功，使用storageKey", ^{
            YTXTestModel *model = [YTXTestModel new];
            [model saveStorageSyncWithKey:@"key2" param:nil];
            YTXTestModel *ret = [model fetchStorageSyncWithKey:@"key2" param:nil];
            
            [[ret should] beNonNil];
        });

        it(@"保存缓存成功并且可以读取到，使用storageKey", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.keyId = @1;
            YTXTestModel *model2 = [YTXTestModel new];
            [model1 saveStorageSyncWithKey:@"key3" param:nil];
            [model2 fetchStorageSyncWithKey:@"key3" param:nil];
            
            [[model2.keyId should] equal:model1.keyId];
        });
        
        it(@"删除缓存成功，使用storageKey", ^{
            YTXTestModel *model = [YTXTestModel new];
            [model destroyStorageSyncWithKey:@"key4" param:nil];
        });

        it(@"删除缓存成功并且读不到，使用storageKey", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.keyId = @1;
            YTXTestModel *model2 = [YTXTestModel new];
            YTXTestModel *model3 = [YTXTestModel new];
            [model1 saveStorageSyncWithKey:@"key5" param:nil];
            [model2 fetchStorageSyncWithKey:@"key5" param:nil];
            [model1 destroyStorageSyncWithKey:@"key5" param:nil];
            [model3 fetchStorageSyncWithKey:@"key5" param:nil];

            [[model2.keyId should] beNonNil];
            [[model3.keyId should] beNil];
        });

        it(@"没取到的情况会得到nil", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.keyId = @1;
            YTXTestModel *model2 = [YTXTestModel new];
            
            [model1 saveStorageSyncWithKey:@"key6" param:nil];
            id ret = [model2 fetchStorageSyncWithKey:@"abc" param:nil];
             
            [[ret should] beNil];
        });

        it(@"使用storageKey确实根据key存了不同份到storage中", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.keyId = @1;
            YTXTestModel *model2 = [YTXTestModel new];
            model2.keyId = @2;
            YTXTestModel *model3 = [YTXTestModel new];
            YTXTestModel *model4 = [YTXTestModel new];
            
            [model1 saveStorageSyncWithKey:@"key111" param:nil];
            [model2 saveStorageSyncWithKey:@"key222" param:nil];
            [model3 fetchStorageSyncWithKey:@"key111" param:nil];
            [model4 fetchStorageSyncWithKey:@"key222" param:nil];
            
            [[model3.keyId should] equal:@1];
            [[model4.keyId should] equal:@2];
            [[model3.keyId shouldNot] equal:model4.keyId];
            
        });

        it(@"保存缓存成功", ^{
            YTXTestModel *model = [YTXTestModel new];
            model.keyId = @1;
            YTXTestModel *ret = [model saveStorageSync:nil];
            [[ret should] equal:model];
        });

        it(@"获取缓存成功", ^{
            YTXTestModel *model = [YTXTestModel new];
            model.keyId = @1001;
            [model saveStorageSync:nil];
            YTXTestModel *ret = [model fetchStorageSync:nil];
            
            [[ret should] beNonNil];
        });

        it(@"保存缓存成功并且可以读取到", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.keyId = @1002;
            model1.title = @"Test";
            YTXTestModel *model2 = [YTXTestModel new];
            [model1 saveStorageSync:nil];
            model2.keyId = @1002;
            [model2 fetchStorageSync:nil];
            
            [[model2.keyId should] equal:model1.keyId];
            [[model2.title should] equal:model1.title];
        });

        it(@"删除缓存成功", ^{
            YTXTestModel *model = [YTXTestModel new];
            model.keyId = @1002;
            [model destroyStorageSync:nil];
        });

        it(@"删除缓存成功并且读不到", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.keyId = @1003;
            model1.title = @"Test";
            YTXTestModel *model2 = [YTXTestModel new];
            model2.keyId = model1.keyId;
            YTXTestModel *model3 = [YTXTestModel new];
            model3.keyId = model1.keyId;
            
            [model1 saveStorageSync:nil];
            [model2 fetchStorageSync:nil];
            [model1 destroyStorageSync:nil];
            [model3 fetchStorageSync:nil];
            
            [[model2.title should] beNonNil];
            [[model3.title should] beNil];
        });
	
        it(@"没取到的情况会得到nil", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.keyId = @1004;
            YTXTestModel *model2 = [YTXTestModel new];
            model2.keyId = model1.keyId;
    
            [model1 destroyStorageSync:nil];
            YTXTestModel * ret = [model2 fetchStorageSync:nil];
            
            [[ret should] beNil];
        });
        
        it(@"更换UserDefalut的group", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName1];
            model1.keyId = @1005;
            model1.title = @"model1Title";
            
            YTXTestModel *model2 = [YTXTestModel new];
            model2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName2];
            model2.keyId = @1005;
            model2.title = @"model2Title";
            
            YTXTestModel *model3 = [YTXTestModel new];
            model3.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName1];
            model3.keyId = @1005;
            
            YTXTestModel *model4 = [YTXTestModel new];
            model4.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName2];
            model4.keyId = @1005;
            
            [model1 saveStorageSync:nil];
            [model2 saveStorageSync:nil];
            [model3 fetchStorageSync:nil];
            [model4 fetchStorageSync:nil];
            
            [[model3.title should] equal:@"model1Title"];
            [[model4.title should] equal:@"model2Title"];
        });
    });
    
    context(@"Collection同步功能", ^{
        beforeAll(^{
            //清空以便测试
            YTXTestCollection *collection1 = [YTXTestCollection new];
            collection1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName1];
            
            YTXTestCollection *collection2 = [YTXTestCollection new];
            collection2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName2];
            
            YTXTestCollection *collection3 = [YTXTestCollection new];
            
            [collection1 destroyStorageSync:nil];
            [collection2 destroyStorageSync:nil];
            [collection3 destroyStorageSync:nil];
        });
        
        afterAll(^{
            //清空以便测试
            YTXTestCollection *collection1 = [YTXTestCollection new];
            collection1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName1];
            
            YTXTestCollection *collection2 = [YTXTestCollection new];
            collection2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName2];
            
            YTXTestCollection *collection3 = [YTXTestCollection new];
            
            [collection1 destroyStorageSync:nil];
            [collection2 destroyStorageSync:nil];
            [collection3 destroyStorageSync:nil];
        });

        it(@"保存缓存成功，自定义storageKey", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            YTXTestCollection *ret1 = [collection1 saveStorageSyncWithKey:@"storageKey1" param:nil];

            [[expectFutureValue(ret1) shouldEventually] equal:collection1];
        });
        
        it(@"获取缓存成功，自定义storageKey", ^{
            YTXTestCollection *collection = [YTXTestCollection new];
            YTXTestModel *model1 = [[YTXTestModel alloc] init];
            model1.keyId = @1;
            YTXTestModel *model2 = [[YTXTestModel alloc] init];
            YTXTestModel *model3 = [[YTXTestModel alloc] init];
            YTXTestModel *model4 = [[YTXTestModel alloc] init];
            [collection addModels:@[model1, model2, model3, model4]];
            [collection saveStorageSyncWithKey:@"storageKey1" param:nil];
            YTXTestCollection *ret = [collection fetchStorageSyncWithKey:@"storageKey1" param:nil];
            
            [[@(ret.models.count) should] equal:@(collection.models.count)];
            [[((YTXTestModel *)ret.models.firstObject).keyId should] equal:@1];
        });
        
        it(@"保存缓存成功并且可以读取到，使用storageKey", ^{
            YTXTestCollection *collection = [YTXTestCollection new];
            YTXTestModel *model = [[YTXTestModel alloc] init];
            model.keyId = @1;
            [collection addModels:@[model]];
            YTXTestCollection *ret = [collection saveStorageSyncWithKey:@"storageKey3" param:nil];
            [ret fetchStorageSyncWithKey:@"storageKey3" param:nil];
            
            [[((YTXTestModel *)ret.models.firstObject).keyId should] equal:model.keyId];
        });
        
        it(@"删除缓存成功，使用storageKey", ^{
            YTXTestCollection *collection = [YTXTestCollection new];
            [collection destroyStorageSyncWithKey:@"storageKey4" param:nil];
        });
        
        it(@"删除缓存成功并且读不到，使用storageKey", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            YTXTestModel *model = [[YTXTestModel alloc] init];
            model.keyId = @1;
            [collection1 addModels:@[model]];
            YTXTestCollection *collection2 = [YTXTestCollection new];
            YTXTestCollection *collection3 = [YTXTestCollection new];
            [collection1 saveStorageSyncWithKey:@"storageKey5" param:nil];
            [collection2 fetchStorageSyncWithKey:@"storageKey5" param:nil];
            [collection1 destroyStorageSyncWithKey:@"storageKey5" param:nil];
            [collection3 fetchStorageSyncWithKey:@"storageKey5" param:nil];
            
            [[((YTXTestModel *)collection2.models.firstObject).keyId should] equal:@1];
            [[((YTXTestModel *)collection3.models.firstObject).keyId should] beNil];
        });

        it(@"没取到的情况会得到nil", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            YTXTestCollection *collection2 = [YTXTestCollection new];
            [collection1 saveStorageSyncWithKey:@"key6" param:nil];
            id ret = [collection2 fetchStorageSyncWithKey:@"abc" param:nil];
            
            [[ret should] beNil];
        });
        
        it(@"使用storageKey确实根据key存了不同份到storage中", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            YTXTestModel *model1 = [[YTXTestModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            YTXTestCollection *collection2 = [YTXTestCollection new];
            YTXTestModel *model2 = [[YTXTestModel alloc] init];
            model2.keyId = @2;
            [collection2 addModels:@[model2]];
            YTXTestCollection *collection3 = [YTXTestCollection new];
            
            YTXTestCollection *collection4 = [YTXTestCollection new];
            
            [collection1 saveStorageSyncWithKey:@"key111" param:nil];
            [collection2 saveStorageSyncWithKey:@"key222" param:nil];
            [collection3 fetchStorageSyncWithKey:@"key111" param:nil];
            [collection4 fetchStorageSyncWithKey:@"key222" param:nil];
            
            [[((YTXTestModel *)collection3.models.firstObject).keyId should] equal:@1];
            [[((YTXTestModel *)collection4.models.firstObject).keyId should] equal:@2];
            [[((YTXTestModel *)collection3.models.firstObject).keyId shouldNot] equal:((YTXTestModel *)collection4.models.firstObject).keyId];
            
        });

        it(@"保存缓存成功", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            YTXTestModel *model1 = [[YTXTestModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            YTXTestCollection *ret = [collection1 saveStorageSync:nil];
            [[((YTXTestModel *)ret.models.firstObject).keyId should] equal:((YTXTestModel *)collection1.models.firstObject).keyId];
        });

        it(@"获取缓存成功", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            YTXTestCollection *collection2 = [YTXTestCollection new];
            
            [collection1 saveStorageSync:nil];
            YTXTestCollection * ret = [collection2 fetchStorageSync:nil];
            
            [[ret should] beNonNil];
        });
        
        it(@"保存缓存成功并且可以读取到", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            YTXTestModel *model1 = [[YTXTestModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            YTXTestCollection *ret =  [YTXTestCollection new];
            [collection1 saveStorageSync:nil];
            [ret fetchStorageSync:nil];
            
            [[((YTXTestModel *)ret.models.firstObject).keyId should] equal:((YTXTestModel *)collection1.models.firstObject).keyId];
        });
        
        it(@"删除缓存成功", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            [collection1 destroyStorageSync:nil];
        });
        
        it(@"删除缓存成功并且读不到", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            YTXTestModel *model1 = [[YTXTestModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            YTXTestCollection *collection2 =  [YTXTestCollection new];
            YTXTestCollection *collection3 =  [YTXTestCollection new];
            [collection1 saveStorageSync:nil];
            [collection2 fetchStorageSync:nil];
            [collection1 destroyStorageSync:nil];
            [collection3 fetchStorageSync:nil];

            [[((YTXTestModel *)collection2.models.firstObject).keyId should] beNonNil];
            [[((YTXTestModel *)collection3.models.firstObject).keyId should] beNil];
        });
        
        it(@"没取到的情况会得到nil", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            YTXTestModel *model1 = [[YTXTestModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            YTXTestCollection *collection2 =  [YTXTestCollection new];
            [collection1 destroyStorageSync:nil];
            YTXTestCollection * ret = [collection2 fetchStorageSync:nil];
            
            [[ret should] beNil];
        });
        
        it(@"更换UserDefalut的group", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            collection1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName1];
            [collection1 addModels:@[[YTXTestModel new]]];
            
            YTXTestCollection *collection2 = [YTXTestCollection new];
            collection2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName2];
            
            YTXTestCollection *collection3 = [YTXTestCollection new];
            collection3.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName1];
            
            YTXTestCollection *collection4 = [YTXTestCollection new];
            collection4.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName2];
            
            [collection1 saveStorageSync:nil];
            [collection3 fetchStorageSync:nil];
            [collection2 fetchStorageSync:nil];
            [collection2 addModels:@[[YTXTestModel new], [YTXTestModel new]]];
            [collection2 saveStorageSync:nil];
            [collection4 fetchStorageSync:nil];
            [collection2 removeAllModels];
            [collection2 destroyStorageSync:nil];
            
            [[@(collection2.models.count) should] equal:@0];
            [[@(collection3.models.count) should] equal:@1];
            [[@(collection4.models.count) should] equal:@2];
        });

    });
    
    context(@"Model异步功能", ^{
        beforeAll(^{
            //清空以便测试
            YTXTestModel *model1 = [YTXTestModel new];
            model1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName3];

            YTXTestModel *model2 = [YTXTestModel new];
            model2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName4];

            YTXTestModel *model3 = [YTXTestModel new];
            
            [model1 destroyStorageSyncWithKey:storagModelKey1 param:nil];
            [model2 destroyStorageSyncWithKey:storagModelKey2 param:nil];
            [model3 destroyStorageSyncWithKey:storagModelKey3 param:nil];

        });

        it(@"保存缓存成功，使用storageKey", ^{
            YTXTestModel *model = [YTXTestModel new];
            __block YTXTestModel *ret = nil;
            [[model saveStorageWithKey:@"key1" param:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(ret) shouldEventually] equal:model];
        });

        it(@"获取缓存成功，使用storageKey", ^{
            YTXTestModel *model = [YTXTestModel new];
            __block YTXTestModel *ret = nil;

            [[[model saveStorageWithKey:@"key2" param:nil] flattenMap:^RACStream *(id value) {
                return [model fetchStorageWithKey:@"key2" param:nil];
            }] subscribeNext:^(id x) {
                ret = x;
            }];

            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });

        it(@"保存缓存成功并且可以读取到，使用storageKey", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.keyId = @1;
            __block YTXTestModel *model2 = [YTXTestModel new];
            [[model1 saveStorageWithKey:@"key3" param:nil] subscribeNext:^(id x) {
                [model2 fetchStorageWithKey:@"key3" param:nil];
            }];

            [[expectFutureValue(model2.keyId) shouldEventually] equal:model1.keyId];
        });

        it(@"删除缓存成功，使用storageKey", ^{
            YTXTestModel *model = [YTXTestModel new];
            __block NSNumber *ret = nil;
            [[model destroyStorageWithKey:@"key4" param:nil] subscribeNext:^(id x) {
                ret = @1;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(ret) shouldEventually] equal:@1];
        });

        it(@"删除缓存成功并且读不到，使用storageKey", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.keyId = @1;
            __block YTXTestModel *model2 = [YTXTestModel new];
            __block YTXTestModel *model3 = [YTXTestModel new];

            [[[[[model1 saveStorageWithKey:@"key5" param:nil] flattenMap:^RACStream *(id value) {
                return [model2 fetchStorageWithKey:@"key5" param:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model1 destroyStorageWithKey:@"key5" param:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model3 fetchStorageWithKey:@"key5" param:nil];
            }] subscribeNext:^(id x) {

            }];
            [[expectFutureValue(model2.keyId) shouldEventually] beNonNil];
            [[expectFutureValue(model3.keyId) shouldEventually] beNil];
        });

        it(@"没取到的情况会进入error", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.keyId = @1;
            __block YTXTestModel *model2 = [YTXTestModel new];

            __block NSError *ret = nil;

            [[model1 saveStorageWithKey:@"key6" param:nil] subscribeNext:^(id x) {
                [[model2 fetchStorageWithKey:@"abc" param:nil] subscribeError:^(NSError *error) {
                    ret = error;
                }];
            }] ;

            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });
//
        it(@"使用storageKey确实根据key存了不同份到storage中", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.keyId = @1;
            __block YTXTestModel *model2 = [YTXTestModel new];
            model2.keyId = @2;
            __block YTXTestModel *model3 = [YTXTestModel new];
            __block YTXTestModel *model4 = [YTXTestModel new];

            [[[[[model1 saveStorageWithKey:@"key111" param:nil] flattenMap:^RACStream *(id value) {
                return [model2 saveStorageWithKey:@"key222" param:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model3 fetchStorageWithKey:@"key111" param:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model4 fetchStorageWithKey:@"key222" param:nil];
            }] subscribeNext:^(id x) {

            }];

            [[expectFutureValue(model3.keyId) shouldEventually] equal:@1];
            [[expectFutureValue(model4.keyId) shouldEventually] equal:@2];
            [[expectFutureValue(model3.keyId) shouldNotEventually] equal:expectFutureValue(model4.keyId)];

        });

        it(@"保存缓存成功", ^{
            YTXTestModel *model = [YTXTestModel new];
            model.keyId = @2001;
            __block YTXTestModel *ret = nil;
            [[model saveStorage:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(ret) shouldEventually] equal:model];
        });

        it(@"获取缓存成功", ^{
            YTXTestModel *model = [YTXTestModel new];
            model.keyId = @2002;
            __block YTXTestModel *ret = nil;

            [[[model saveStorage:nil] flattenMap:^RACStream *(id value) {
                return [model fetchStorage:nil];
            }] subscribeNext:^(id x) {
                ret = x;
            }];

            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });

        it(@"保存缓存成功并且可以读取到", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.keyId = @2003;
            model1.title = @"testModel1";
            __block YTXTestModel *model2 = [YTXTestModel new];
            model2.keyId = model1.keyId;
            [[model1 saveStorage:nil] subscribeNext:^(id x) {
                [model2 fetchStorage:nil];
            }];

            [[expectFutureValue(model2.title) shouldEventually] equal:model1.title];
        });

        it(@"删除缓存成功", ^{
            YTXTestModel *model = [YTXTestModel new];
            model.keyId = @2004;
            __block NSNumber *ret = nil;
            [[model destroyStorage:nil] subscribeNext:^(id x) {
                ret = @1;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(ret) shouldEventually] equal:@1];
        });

        it(@"删除缓存成功并且读不到", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.keyId = @2005;
            model1.title = @"testModel1";
            __block YTXTestModel *model2 = [YTXTestModel new];
            model2.keyId = model1.keyId;
            __block YTXTestModel *model3 = [YTXTestModel new];
            model3.keyId = model1.keyId;
            
            [[[[[model1 saveStorage:nil] flattenMap:^RACStream *(id value) {
                return [model2 fetchStorage:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model1 destroyStorage:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model3 fetchStorage:nil];
            }] subscribeNext:^(id x) {

            }];
            [[expectFutureValue(model2.title) shouldEventually] beNonNil];
            [[expectFutureValue(model3.title) shouldEventually] beNil];
        });

        it(@"没取到的情况会进入error", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.keyId = @2006;
            __block YTXTestModel *model2 = [YTXTestModel new];
            model2.keyId = model1.keyId;
            __block NSError *ret = nil;

            [[model1 destroyStorage:nil] subscribeNext:^(id x) {
                [[model2 fetchStorage:nil] subscribeError:^(NSError *error) {
                    ret = error;
                }];
            }] ;

            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });

        it(@"更换UserDefalut的group", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName3];
            model1.keyId = @2007;
            model1.title = @"testModel1";

            __block YTXTestModel *model2 = [YTXTestModel new];
            model2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName4];
            model2.keyId = @2007;
            model2.title = @"testModel2";

            __block YTXTestModel *model3 = [YTXTestModel new];
            model3.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName3];
            model3.keyId = @2007;

            __block YTXTestModel *model4 = [YTXTestModel new];
            model4.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName4];
            model4.keyId = @2007;
            
            [[[[[model1 saveStorage:nil] flattenMap:^RACStream *(id value) {
                return [model3 fetchStorage:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model2 saveStorage:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model4 fetchStorage:nil];
            }] subscribeNext:^(id x) {
                
            }];

            [[expectFutureValue(model3.title) shouldEventually] equal:@"testModel1"];
            [[expectFutureValue(model4.title) shouldEventually] equal:@"testModel2"];

        });
    });

    context(@"Collection异步功能", ^{
        beforeAll(^{
            //清空以便测试
            YTXTestCollection *collection1 = [YTXTestCollection new];
            collection1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName3];

            YTXTestCollection *collection2 = [YTXTestCollection new];
            collection2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName4];

            YTXTestCollection *collection3 = [YTXTestCollection new];

            [collection1 destroyStorageSync:nil];
            [collection2 destroyStorageSync:nil];
            [collection3 destroyStorageSync:nil];
        });

        it(@"保存缓存成功，自定义storageKey", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            __block YTXTestCollection *ret1 = nil;
            [[collection1 saveStorageWithKey:@"storageKey1" param:nil] subscribeNext:^(id x) {
                ret1 = x;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(ret1) shouldEventually] equal:collection1];
        });

        it(@"获取缓存成功，自定义storageKey", ^{
            YTXTestCollection *collection = [YTXTestCollection new];
            YTXTestModel *model1 = [[YTXTestModel alloc] init];
            model1.keyId = @1;
            YTXTestModel *model2 = [[YTXTestModel alloc] init];
            YTXTestModel *model3 = [[YTXTestModel alloc] init];
            YTXTestModel *model4 = [[YTXTestModel alloc] init];
            [collection addModels:@[model1, model2, model3, model4]];
            __block YTXTestCollection *ret = nil;
            [[[collection saveStorageWithKey:@"storageKey1" param:nil] flattenMap:^RACStream *(id value) {
                return [collection fetchStorageWithKey:@"storageKey1" param:nil];
            }] subscribeNext:^(id x) {
                ret = x;
            }];

            [[expectFutureValue(@(ret.models.count)) shouldEventually] equal:@(collection.models.count)];
            [[expectFutureValue(((YTXTestModel *)ret.models.firstObject).keyId) shouldEventually] equal:@1];
        });

        it(@"保存缓存成功并且可以读取到，使用storageKey", ^{
            YTXTestCollection *collection = [YTXTestCollection new];
            YTXTestModel *model = [[YTXTestModel alloc] init];
            model.keyId = @1;
            [collection addModels:@[model]];
            __block YTXTestCollection *ret = [YTXTestCollection new];
            [[collection saveStorageWithKey:@"storageKey3" param:nil] subscribeNext:^(id x) {
                [ret fetchStorageWithKey:@"storageKey3" param:nil];
            }];

            [[expectFutureValue(((YTXTestModel *)ret.models.firstObject).keyId) shouldEventually] equal:model.keyId];
        });

        it(@"删除缓存成功，使用storageKey", ^{
            YTXTestCollection *collection = [YTXTestCollection new];
            __block NSNumber *ret = @1;
            [[collection destroyStorageWithKey:@"storageKey4" param:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(ret) shouldEventually] beNil];
        });

        it(@"删除缓存成功并且读不到，使用storageKey", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            YTXTestModel *model = [[YTXTestModel alloc] init];
            model.keyId = @1;
            [collection1 addModels:@[model]];
            __block YTXTestCollection *collection2 = [YTXTestCollection new];
            __block YTXTestCollection *collection3 = [YTXTestCollection new];

            [[[[[collection1 saveStorageWithKey:@"storageKey5" param:nil] flattenMap:^RACStream *(id value) {
                return [collection2 fetchStorageWithKey:@"storageKey5" param:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection1 destroyStorageWithKey:@"storageKey5" param:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection3 fetchStorageWithKey:@"storageKey5" param:nil];
            }] subscribeNext:^(id x) {

            }];
            [[expectFutureValue(((YTXTestModel *)collection2.models.firstObject).keyId) shouldEventually] equal:@1];
            [[expectFutureValue(((YTXTestModel *)collection3.models.firstObject).keyId) shouldEventually] beNil];
        });

        it(@"没取到的情况会进入error", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            __block YTXTestCollection *collection2 = [YTXTestCollection new];

            __block NSError *ret = nil;

            [[collection1 saveStorageWithKey:@"key6" param:nil] subscribeNext:^(id x) {
                [[collection2 fetchStorageWithKey:@"abc" param:nil] subscribeError:^(NSError *error) {
                    ret = error;
                }];
            }] ;

            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });

        it(@"使用storageKey确实根据key存了不同份到storage中", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            YTXTestModel *model1 = [[YTXTestModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            __block YTXTestCollection *collection2 = [YTXTestCollection new];
            YTXTestModel *model2 = [[YTXTestModel alloc] init];
            model2.keyId = @2;
            [collection2 addModels:@[model2]];
            __block YTXTestCollection *collection3 = [YTXTestCollection new];

            __block YTXTestCollection *collection4 = [YTXTestCollection new];


            [[[[[collection1 saveStorageWithKey:@"key111" param:nil] flattenMap:^RACStream *(id value) {
                return [collection2 saveStorageWithKey:@"key222" param:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection3 fetchStorageWithKey:@"key111" param:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection4 fetchStorageWithKey:@"key222" param:nil];
            }] subscribeNext:^(id x) {

            }];

            [[expectFutureValue(((YTXTestModel *)collection3.models.firstObject).keyId) shouldEventually] equal:@1];
            [[expectFutureValue(((YTXTestModel *)collection4.models.firstObject).keyId) shouldEventually] equal:@2];
            [[expectFutureValue(((YTXTestModel *)collection3.models.firstObject).keyId) shouldNotEventually] equal:expectFutureValue(((YTXTestModel *)collection4.models.firstObject).keyId)];

        });

        it(@"保存缓存成功", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            YTXTestModel *model1 = [[YTXTestModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            __block YTXTestCollection *ret = nil;
            [[collection1 saveStorage:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(((YTXTestModel *)ret.models.firstObject).keyId) shouldEventually] equal:((YTXTestModel *)collection1.models.firstObject).keyId];
        });

        it(@"获取缓存成功", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            __block YTXTestCollection *ret = [YTXTestCollection new];

            [[[collection1 saveStorage:nil] flattenMap:^RACStream *(id value) {
                return [ret fetchStorage:nil];
            }] subscribeNext:^(id x) {
                ret = x;
            }];

            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });

        it(@"保存缓存成功并且可以读取到", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            YTXTestModel *model1 = [[YTXTestModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            __block YTXTestCollection *ret =  [YTXTestCollection new];

            [[collection1 saveStorage:nil] subscribeNext:^(id x) {
                [ret fetchStorage:nil];
            }];

            [[expectFutureValue(((YTXTestModel *)ret.models.firstObject).keyId) shouldEventually] equal:((YTXTestModel *)collection1.models.firstObject).keyId];
        });

        it(@"删除缓存成功", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            __block NSNumber *ret = @1;
            [[collection1 destroyStorage:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(ret) shouldEventually] beNil];
        });

        it(@"删除缓存成功并且读不到", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            YTXTestModel *model1 = [[YTXTestModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            __block YTXTestCollection *collection2 =  [YTXTestCollection new];
            __block YTXTestCollection *collection3 =  [YTXTestCollection new];

            [[[[[collection1 saveStorage:nil] flattenMap:^RACStream *(id value) {
                return [collection2 fetchStorage:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection1 destroyStorage:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection3 fetchStorage:nil];
            }] subscribeNext:^(id x) {

            }];
            [[expectFutureValue(((YTXTestModel *)collection2.models.firstObject).keyId) shouldEventually] beNonNil];
            [[expectFutureValue(((YTXTestModel *)collection3.models.firstObject).keyId) shouldEventually] beNil];
        });

        it(@"没取到的情况会进入error", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            YTXTestModel *model1 = [[YTXTestModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            __block YTXTestCollection *collection2 =  [YTXTestCollection new];
            __block NSError *ret = nil;

            [[collection1 destroyStorage:nil] subscribeNext:^(id x) {
                [[collection2 fetchStorage:nil] subscribeError:^(NSError *error) {
                    ret = error;
                }];
            }] ;

            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });

        it(@"更换UserDefalut的group", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            collection1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName3];
            [collection1 addModels:@[[YTXTestModel new]]];

            YTXTestCollection *collection2 = [YTXTestCollection new];
            collection2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName4];

            YTXTestCollection *collection3 = [YTXTestCollection new];
            collection3.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName3];

            YTXTestCollection *collection4 = [YTXTestCollection new];
            collection4.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName4];

            [[[[collection1 saveStorage:nil] flattenMap:^RACStream *(id value) {
                return [collection3 fetchStorage:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection2 fetchStorage:nil];
            }] subscribeError:^(NSError * x) {
                [collection2 addModels:@[[YTXTestModel new], [YTXTestModel new]]];
                [[[collection2 saveStorage:nil] flattenMap:^RACStream *(id value) {
                    return [collection4 fetchStorage:nil];
                }] subscribeNext:^(id x) {
                    [collection2 removeAllModels];
                    [collection2 destroyStorage:nil];
                }];
            }];

            [[expectFutureValue(@(collection2.models.count)) shouldEventually] equal:@0];
            [[expectFutureValue(@(collection3.models.count)) shouldEventually] equal:@1];
            [[expectFutureValue(@(collection4.models.count)) shouldEventually] equal:@2];
        });

    });

});

SPEC_END
