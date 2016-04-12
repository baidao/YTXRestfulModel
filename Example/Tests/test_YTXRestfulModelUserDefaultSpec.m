//
//  test_YTXRestfulModelUserDefaultSpec.m
//  YTXRestfulModel
//
//  Created by zhanglu on 16/2/15.
//  Copyright 2016年 caojun. All rights reserved.
//

#import "YTXTestAFNetworkingRemoteCollection.h"

#import <Kiwi/Kiwi.h>

#import <YTXRestfulModel/YTXRestfulModelUserDefaultStorageSync.h>
#import <YTXRestfulModel/YTXRestfulModelRACSupport.h>

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
            YTXTestAFNetworkingRemoteModel *model1 = [YTXTestAFNetworkingRemoteModel new];
            model1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName1];
            
            YTXTestAFNetworkingRemoteModel *model2 = [YTXTestAFNetworkingRemoteModel new];
            model2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName2];
            
            YTXTestAFNetworkingRemoteModel *model3 = [YTXTestAFNetworkingRemoteModel new];
            
            [model1 destroyStorageSyncWithKey:storagModelKey1 param:nil];
            [model2 destroyStorageSyncWithKey:storagModelKey2 param:nil];
            [model3 destroyStorageSyncWithKey:storagModelKey3 param:nil];
            
        });
        
        afterAll(^{
            //清空以便测试
            YTXTestAFNetworkingRemoteModel *model1 = [YTXTestAFNetworkingRemoteModel new];
            model1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName1];
            
            YTXTestAFNetworkingRemoteModel *model2 = [YTXTestAFNetworkingRemoteModel new];
            model2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName2];
            
            YTXTestAFNetworkingRemoteModel *model3 = [YTXTestAFNetworkingRemoteModel new];
            
            [model1 destroyStorageSyncWithKey:storagModelKey1 param:nil];
            [model2 destroyStorageSyncWithKey:storagModelKey2 param:nil];
            [model3 destroyStorageSyncWithKey:storagModelKey3 param:nil];
            
        });
        
        it(@"保存缓存成功，使用storageKey", ^{
            YTXTestAFNetworkingRemoteModel *model = [YTXTestAFNetworkingRemoteModel new];
            YTXTestAFNetworkingRemoteModel *ret = [model saveStorageSyncWithKey:@"key1" param:nil];

            [[ret should] equal:model];
        });
        
        it(@"获取缓存成功，使用storageKey", ^{
            YTXTestAFNetworkingRemoteModel *model = [YTXTestAFNetworkingRemoteModel new];
            [model saveStorageSyncWithKey:@"key2" param:nil];
            YTXTestAFNetworkingRemoteModel *ret = [model fetchStorageSyncWithKey:@"key2" param:nil];
            
            [[ret should] beNonNil];
        });

        it(@"保存缓存成功并且可以读取到，使用storageKey", ^{
            YTXTestAFNetworkingRemoteModel *model1 = [YTXTestAFNetworkingRemoteModel new];
            model1.keyId = @1;
            YTXTestAFNetworkingRemoteModel *model2 = [YTXTestAFNetworkingRemoteModel new];
            [model1 saveStorageSyncWithKey:@"key3" param:nil];
            [model2 fetchStorageSyncWithKey:@"key3" param:nil];
            
            [[model2.keyId should] equal:model1.keyId];
        });
        
        it(@"删除缓存成功，使用storageKey", ^{
            YTXTestAFNetworkingRemoteModel *model = [YTXTestAFNetworkingRemoteModel new];
            [model destroyStorageSyncWithKey:@"key4" param:nil];
        });

        it(@"删除缓存成功并且读不到，使用storageKey", ^{
            YTXTestAFNetworkingRemoteModel *model1 = [YTXTestAFNetworkingRemoteModel new];
            model1.keyId = @1;
            YTXTestAFNetworkingRemoteModel *model2 = [YTXTestAFNetworkingRemoteModel new];
            YTXTestAFNetworkingRemoteModel *model3 = [YTXTestAFNetworkingRemoteModel new];
            [model1 saveStorageSyncWithKey:@"key5" param:nil];
            [model2 fetchStorageSyncWithKey:@"key5" param:nil];
            [model1 destroyStorageSyncWithKey:@"key5" param:nil];
            [model3 fetchStorageSyncWithKey:@"key5" param:nil];

            [[model2.keyId should] beNonNil];
            [[model3.keyId should] beNil];
        });

        it(@"没取到的情况会得到nil", ^{
            YTXTestAFNetworkingRemoteModel *model1 = [YTXTestAFNetworkingRemoteModel new];
            model1.keyId = @1;
            YTXTestAFNetworkingRemoteModel *model2 = [YTXTestAFNetworkingRemoteModel new];
            
            [model1 saveStorageSyncWithKey:@"key6" param:nil];
            id ret = [model2 fetchStorageSyncWithKey:@"abc" param:nil];
             
            [[ret should] beNil];
        });

        it(@"使用storageKey确实根据key存了不同份到storage中", ^{
            YTXTestAFNetworkingRemoteModel *model1 = [YTXTestAFNetworkingRemoteModel new];
            model1.keyId = @1;
            YTXTestAFNetworkingRemoteModel *model2 = [YTXTestAFNetworkingRemoteModel new];
            model2.keyId = @2;
            YTXTestAFNetworkingRemoteModel *model3 = [YTXTestAFNetworkingRemoteModel new];
            YTXTestAFNetworkingRemoteModel *model4 = [YTXTestAFNetworkingRemoteModel new];
            
            [model1 saveStorageSyncWithKey:@"key111" param:nil];
            [model2 saveStorageSyncWithKey:@"key222" param:nil];
            [model3 fetchStorageSyncWithKey:@"key111" param:nil];
            [model4 fetchStorageSyncWithKey:@"key222" param:nil];
            
            [[model3.keyId should] equal:@1];
            [[model4.keyId should] equal:@2];
            [[model3.keyId shouldNot] equal:model4.keyId];
            
        });

        it(@"保存缓存成功", ^{
            YTXTestAFNetworkingRemoteModel *model = [YTXTestAFNetworkingRemoteModel new];
            model.keyId = @1;
            YTXTestAFNetworkingRemoteModel *ret = [model saveStorageSync:nil];
            [[ret should] equal:model];
        });

        it(@"获取缓存成功", ^{
            YTXTestAFNetworkingRemoteModel *model = [YTXTestAFNetworkingRemoteModel new];
            model.keyId = @1001;
            [model saveStorageSync:nil];
            YTXTestAFNetworkingRemoteModel *ret = [model fetchStorageSync:nil];
            
            [[ret should] beNonNil];
        });

        it(@"保存缓存成功并且可以读取到", ^{
            YTXTestAFNetworkingRemoteModel *model1 = [YTXTestAFNetworkingRemoteModel new];
            model1.keyId = @1002;
            model1.title = @"Test";
            YTXTestAFNetworkingRemoteModel *model2 = [YTXTestAFNetworkingRemoteModel new];
            [model1 saveStorageSync:nil];
            model2.keyId = @1002;
            [model2 fetchStorageSync:nil];
            
            [[model2.keyId should] equal:model1.keyId];
            [[model2.title should] equal:model1.title];
        });

        it(@"删除缓存成功", ^{
            YTXTestAFNetworkingRemoteModel *model = [YTXTestAFNetworkingRemoteModel new];
            model.keyId = @1002;
            [model destroyStorageSync:nil];
        });

        it(@"删除缓存成功并且读不到", ^{
            YTXTestAFNetworkingRemoteModel *model1 = [YTXTestAFNetworkingRemoteModel new];
            model1.keyId = @1003;
            model1.title = @"Test";
            YTXTestAFNetworkingRemoteModel *model2 = [YTXTestAFNetworkingRemoteModel new];
            model2.keyId = model1.keyId;
            YTXTestAFNetworkingRemoteModel *model3 = [YTXTestAFNetworkingRemoteModel new];
            model3.keyId = model1.keyId;
            
            [model1 saveStorageSync:nil];
            [model2 fetchStorageSync:nil];
            [model1 destroyStorageSync:nil];
            [model3 fetchStorageSync:nil];
            
            [[model2.title should] beNonNil];
            [[model3.title should] beNil];
        });
	
        it(@"没取到的情况会得到nil", ^{
            YTXTestAFNetworkingRemoteModel *model1 = [YTXTestAFNetworkingRemoteModel new];
            model1.keyId = @1004;
            YTXTestAFNetworkingRemoteModel *model2 = [YTXTestAFNetworkingRemoteModel new];
            model2.keyId = model1.keyId;
    
            [model1 destroyStorageSync:nil];
            YTXTestAFNetworkingRemoteModel * ret = [model2 fetchStorageSync:nil];
            
            [[ret should] beNil];
        });
        
        it(@"更换UserDefalut的group", ^{
            YTXTestAFNetworkingRemoteModel *model1 = [YTXTestAFNetworkingRemoteModel new];
            model1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName1];
            model1.keyId = @1005;
            model1.title = @"model1Title";
            
            YTXTestAFNetworkingRemoteModel *model2 = [YTXTestAFNetworkingRemoteModel new];
            model2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName2];
            model2.keyId = @1005;
            model2.title = @"model2Title";
            
            YTXTestAFNetworkingRemoteModel *model3 = [YTXTestAFNetworkingRemoteModel new];
            model3.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName1];
            model3.keyId = @1005;
            
            YTXTestAFNetworkingRemoteModel *model4 = [YTXTestAFNetworkingRemoteModel new];
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
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            collection1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName1];
            
            YTXTestAFNetworkingRemoteCollection *collection2 = [YTXTestAFNetworkingRemoteCollection new];
            collection2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName2];
            
            YTXTestAFNetworkingRemoteCollection *collection3 = [YTXTestAFNetworkingRemoteCollection new];
            
            [collection1 destroyStorageSync:nil];
            [collection2 destroyStorageSync:nil];
            [collection3 destroyStorageSync:nil];
        });
        
        afterAll(^{
            //清空以便测试
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            collection1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName1];
            
            YTXTestAFNetworkingRemoteCollection *collection2 = [YTXTestAFNetworkingRemoteCollection new];
            collection2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName2];
            
            YTXTestAFNetworkingRemoteCollection *collection3 = [YTXTestAFNetworkingRemoteCollection new];
            
            [collection1 destroyStorageSync:nil];
            [collection2 destroyStorageSync:nil];
            [collection3 destroyStorageSync:nil];
        });

        it(@"保存缓存成功，自定义storageKey", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteCollection *ret1 = [collection1 saveStorageSyncWithKey:@"storageKey1" param:nil];

            [[expectFutureValue(ret1) shouldEventually] equal:collection1];
        });
        
        it(@"获取缓存成功，自定义storageKey", ^{
            YTXTestAFNetworkingRemoteCollection *collection = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model1.keyId = @1;
            YTXTestAFNetworkingRemoteModel *model2 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model3 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model4 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            [collection addModels:@[model1, model2, model3, model4]];
            [collection saveStorageSyncWithKey:@"storageKey1" param:nil];
            YTXTestAFNetworkingRemoteCollection *ret = [collection fetchStorageSyncWithKey:@"storageKey1" param:nil];
            
            [[@(ret.models.count) should] equal:@(collection.models.count)];
            [[((YTXTestAFNetworkingRemoteModel *)ret.models.firstObject).keyId should] equal:@1];
        });
        
        it(@"保存缓存成功并且可以读取到，使用storageKey", ^{
            YTXTestAFNetworkingRemoteCollection *collection = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model.keyId = @1;
            [collection addModels:@[model]];
            YTXTestAFNetworkingRemoteCollection *ret = [collection saveStorageSyncWithKey:@"storageKey3" param:nil];
            [ret fetchStorageSyncWithKey:@"storageKey3" param:nil];
            
            [[((YTXTestAFNetworkingRemoteModel *)ret.models.firstObject).keyId should] equal:model.keyId];
        });
        
        it(@"删除缓存成功，使用storageKey", ^{
            YTXTestAFNetworkingRemoteCollection *collection = [YTXTestAFNetworkingRemoteCollection new];
            [collection destroyStorageSyncWithKey:@"storageKey4" param:nil];
        });
        
        it(@"删除缓存成功并且读不到，使用storageKey", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model.keyId = @1;
            [collection1 addModels:@[model]];
            YTXTestAFNetworkingRemoteCollection *collection2 = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteCollection *collection3 = [YTXTestAFNetworkingRemoteCollection new];
            [collection1 saveStorageSyncWithKey:@"storageKey5" param:nil];
            [collection2 fetchStorageSyncWithKey:@"storageKey5" param:nil];
            [collection1 destroyStorageSyncWithKey:@"storageKey5" param:nil];
            [collection3 fetchStorageSyncWithKey:@"storageKey5" param:nil];
            
            [[((YTXTestAFNetworkingRemoteModel *)collection2.models.firstObject).keyId should] equal:@1];
            [[((YTXTestAFNetworkingRemoteModel *)collection3.models.firstObject).keyId should] beNil];
        });

        it(@"没取到的情况会得到nil", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteCollection *collection2 = [YTXTestAFNetworkingRemoteCollection new];
            [collection1 saveStorageSyncWithKey:@"key6" param:nil];
            id ret = [collection2 fetchStorageSyncWithKey:@"abc" param:nil];
            
            [[ret should] beNil];
        });
        
        it(@"使用storageKey确实根据key存了不同份到storage中", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            YTXTestAFNetworkingRemoteCollection *collection2 = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model2 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model2.keyId = @2;
            [collection2 addModels:@[model2]];
            YTXTestAFNetworkingRemoteCollection *collection3 = [YTXTestAFNetworkingRemoteCollection new];
            
            YTXTestAFNetworkingRemoteCollection *collection4 = [YTXTestAFNetworkingRemoteCollection new];
            
            [collection1 saveStorageSyncWithKey:@"key111" param:nil];
            [collection2 saveStorageSyncWithKey:@"key222" param:nil];
            [collection3 fetchStorageSyncWithKey:@"key111" param:nil];
            [collection4 fetchStorageSyncWithKey:@"key222" param:nil];
            
            [[((YTXTestAFNetworkingRemoteModel *)collection3.models.firstObject).keyId should] equal:@1];
            [[((YTXTestAFNetworkingRemoteModel *)collection4.models.firstObject).keyId should] equal:@2];
            [[((YTXTestAFNetworkingRemoteModel *)collection3.models.firstObject).keyId shouldNot] equal:((YTXTestAFNetworkingRemoteModel *)collection4.models.firstObject).keyId];
            
        });

        it(@"保存缓存成功", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            YTXTestAFNetworkingRemoteCollection *ret = [collection1 saveStorageSync:nil];
            [[((YTXTestAFNetworkingRemoteModel *)ret.models.firstObject).keyId should] equal:((YTXTestAFNetworkingRemoteModel *)collection1.models.firstObject).keyId];
        });

        it(@"获取缓存成功", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteCollection *collection2 = [YTXTestAFNetworkingRemoteCollection new];
            
            [collection1 saveStorageSync:nil];
            YTXTestAFNetworkingRemoteCollection * ret = [collection2 fetchStorageSync:nil];
            
            [[ret should] beNonNil];
        });
        
        it(@"保存缓存成功并且可以读取到", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            YTXTestAFNetworkingRemoteCollection *ret =  [YTXTestAFNetworkingRemoteCollection new];
            [collection1 saveStorageSync:nil];
            [ret fetchStorageSync:nil];
            
            [[((YTXTestAFNetworkingRemoteModel *)ret.models.firstObject).keyId should] equal:((YTXTestAFNetworkingRemoteModel *)collection1.models.firstObject).keyId];
        });
        
        it(@"删除缓存成功", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            [collection1 destroyStorageSync:nil];
        });
        
        it(@"删除缓存成功并且读不到", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            YTXTestAFNetworkingRemoteCollection *collection2 =  [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteCollection *collection3 =  [YTXTestAFNetworkingRemoteCollection new];
            [collection1 saveStorageSync:nil];
            [collection2 fetchStorageSync:nil];
            [collection1 destroyStorageSync:nil];
            [collection3 fetchStorageSync:nil];

            [[((YTXTestAFNetworkingRemoteModel *)collection2.models.firstObject).keyId should] beNonNil];
            [[((YTXTestAFNetworkingRemoteModel *)collection3.models.firstObject).keyId should] beNil];
        });
        
        it(@"没取到的情况会得到nil", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            YTXTestAFNetworkingRemoteCollection *collection2 =  [YTXTestAFNetworkingRemoteCollection new];
            [collection1 destroyStorageSync:nil];
            YTXTestAFNetworkingRemoteCollection * ret = [collection2 fetchStorageSync:nil];
            
            [[ret should] beNil];
        });
        
        it(@"更换UserDefalut的group", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            collection1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName1];
            [collection1 addModels:@[[YTXTestAFNetworkingRemoteModel new]]];
            
            YTXTestAFNetworkingRemoteCollection *collection2 = [YTXTestAFNetworkingRemoteCollection new];
            collection2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName2];
            
            YTXTestAFNetworkingRemoteCollection *collection3 = [YTXTestAFNetworkingRemoteCollection new];
            collection3.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName1];
            
            YTXTestAFNetworkingRemoteCollection *collection4 = [YTXTestAFNetworkingRemoteCollection new];
            collection4.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName2];
            
            [collection1 saveStorageSync:nil];
            [collection3 fetchStorageSync:nil];
            [collection2 fetchStorageSync:nil];
            [collection2 addModels:@[[YTXTestAFNetworkingRemoteModel new], [YTXTestAFNetworkingRemoteModel new]]];
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
            YTXTestAFNetworkingRemoteModel *model1 = [YTXTestAFNetworkingRemoteModel new];
            model1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName3];

            YTXTestAFNetworkingRemoteModel *model2 = [YTXTestAFNetworkingRemoteModel new];
            model2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName4];

            YTXTestAFNetworkingRemoteModel *model3 = [YTXTestAFNetworkingRemoteModel new];
            
            [model1 destroyStorageSyncWithKey:storagModelKey1 param:nil];
            [model2 destroyStorageSyncWithKey:storagModelKey2 param:nil];
            [model3 destroyStorageSyncWithKey:storagModelKey3 param:nil];

        });

        it(@"保存缓存成功，使用storageKey", ^{
            YTXTestAFNetworkingRemoteModel *model = [YTXTestAFNetworkingRemoteModel new];
            __block YTXTestAFNetworkingRemoteModel *ret = nil;
            [[model rac_saveStorageWithKey:@"key1" param:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(ret) shouldEventually] equal:model];
        });

        it(@"获取缓存成功，使用storageKey", ^{
            YTXTestAFNetworkingRemoteModel *model = [YTXTestAFNetworkingRemoteModel new];
            __block YTXTestAFNetworkingRemoteModel *ret = nil;

            [[[model rac_saveStorageWithKey:@"key2" param:nil] flattenMap:^RACStream *(id value) {
                return [model rac_fetchStorageWithKey:@"key2" param:nil];
            }] subscribeNext:^(id x) {
                ret = x;
            }];

            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });

        it(@"保存缓存成功并且可以读取到，使用storageKey", ^{
            YTXTestAFNetworkingRemoteModel *model1 = [YTXTestAFNetworkingRemoteModel new];
            model1.keyId = @1;
            __block YTXTestAFNetworkingRemoteModel *model2 = [YTXTestAFNetworkingRemoteModel new];
            [[model1 rac_saveStorageWithKey:@"key3" param:nil] subscribeNext:^(id x) {
                [model2 rac_fetchStorageWithKey:@"key3" param:nil];
            }];

            [[expectFutureValue(model2.keyId) shouldEventually] equal:model1.keyId];
        });

        it(@"删除缓存成功，使用storageKey", ^{
            YTXTestAFNetworkingRemoteModel *model = [YTXTestAFNetworkingRemoteModel new];
            __block NSNumber *ret = nil;
            [[model rac_destroyStorageWithKey:@"key4" param:nil] subscribeNext:^(id x) {
                ret = @1;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(ret) shouldEventually] equal:@1];
        });

        it(@"删除缓存成功并且读不到，使用storageKey", ^{
            YTXTestAFNetworkingRemoteModel *model1 = [YTXTestAFNetworkingRemoteModel new];
            model1.keyId = @1;
            __block YTXTestAFNetworkingRemoteModel *model2 = [YTXTestAFNetworkingRemoteModel new];
            __block YTXTestAFNetworkingRemoteModel *model3 = [YTXTestAFNetworkingRemoteModel new];

            [[[[[model1 rac_saveStorageWithKey:@"key5" param:nil] flattenMap:^RACStream *(id value) {
                return [model2 rac_fetchStorageWithKey:@"key5" param:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model1 rac_destroyStorageWithKey:@"key5" param:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model3 rac_fetchStorageWithKey:@"key5" param:nil];
            }] subscribeNext:^(id x) {

            }];
            [[expectFutureValue(model2.keyId) shouldEventually] beNonNil];
            [[expectFutureValue(model3.keyId) shouldEventually] beNil];
        });

        it(@"没取到的情况会进入error", ^{
            YTXTestAFNetworkingRemoteModel *model1 = [YTXTestAFNetworkingRemoteModel new];
            model1.keyId = @1;
            __block YTXTestAFNetworkingRemoteModel *model2 = [YTXTestAFNetworkingRemoteModel new];

            __block NSError *ret = nil;

            [[model1 rac_saveStorageWithKey:@"key6" param:nil] subscribeNext:^(id x) {
                [[model2 rac_fetchStorageWithKey:@"abc" param:nil] subscribeError:^(NSError *error) {
                    ret = error;
                }];
            }] ;

            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });
//
        it(@"使用storageKey确实根据key存了不同份到storage中", ^{
            YTXTestAFNetworkingRemoteModel *model1 = [YTXTestAFNetworkingRemoteModel new];
            model1.keyId = @1;
            __block YTXTestAFNetworkingRemoteModel *model2 = [YTXTestAFNetworkingRemoteModel new];
            model2.keyId = @2;
            __block YTXTestAFNetworkingRemoteModel *model3 = [YTXTestAFNetworkingRemoteModel new];
            __block YTXTestAFNetworkingRemoteModel *model4 = [YTXTestAFNetworkingRemoteModel new];

            [[[[[model1 rac_saveStorageWithKey:@"key111" param:nil] flattenMap:^RACStream *(id value) {
                return [model2 rac_saveStorageWithKey:@"key222" param:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model3 rac_fetchStorageWithKey:@"key111" param:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model4 rac_fetchStorageWithKey:@"key222" param:nil];
            }] subscribeNext:^(id x) {

            }];

            [[expectFutureValue(model3.keyId) shouldEventually] equal:@1];
            [[expectFutureValue(model4.keyId) shouldEventually] equal:@2];
            [[expectFutureValue(model3.keyId) shouldNotEventually] equal:expectFutureValue(model4.keyId)];

        });

        it(@"保存缓存成功", ^{
            YTXTestAFNetworkingRemoteModel *model = [YTXTestAFNetworkingRemoteModel new];
            model.keyId = @2001;
            __block YTXTestAFNetworkingRemoteModel *ret = nil;
            [[model rac_saveStorage:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(ret) shouldEventually] equal:model];
        });

        it(@"获取缓存成功", ^{
            YTXTestAFNetworkingRemoteModel *model = [YTXTestAFNetworkingRemoteModel new];
            model.keyId = @2002;
            __block YTXTestAFNetworkingRemoteModel *ret = nil;

            [[[model rac_saveStorage:nil] flattenMap:^RACStream *(id value) {
                return [model rac_fetchStorage:nil];
            }] subscribeNext:^(id x) {
                ret = x;
            }];

            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });

        it(@"保存缓存成功并且可以读取到", ^{
            YTXTestAFNetworkingRemoteModel *model1 = [YTXTestAFNetworkingRemoteModel new];
            model1.keyId = @2003;
            model1.title = @"testModel1";
            __block YTXTestAFNetworkingRemoteModel *model2 = [YTXTestAFNetworkingRemoteModel new];
            model2.keyId = model1.keyId;
            [[model1 rac_saveStorage:nil] subscribeNext:^(id x) {
                [model2 rac_fetchStorage:nil];
            }];

            [[expectFutureValue(model2.title) shouldEventually] equal:model1.title];
        });

        it(@"删除缓存成功", ^{
            YTXTestAFNetworkingRemoteModel *model = [YTXTestAFNetworkingRemoteModel new];
            model.keyId = @2004;
            __block NSNumber *ret = nil;
            [[model rac_destroyStorage:nil] subscribeNext:^(id x) {
                ret = @1;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(ret) shouldEventually] equal:@1];
        });

        it(@"删除缓存成功并且读不到", ^{
            YTXTestAFNetworkingRemoteModel *model1 = [YTXTestAFNetworkingRemoteModel new];
            model1.keyId = @2005;
            model1.title = @"testModel1";
            __block YTXTestAFNetworkingRemoteModel *model2 = [YTXTestAFNetworkingRemoteModel new];
            model2.keyId = model1.keyId;
            __block YTXTestAFNetworkingRemoteModel *model3 = [YTXTestAFNetworkingRemoteModel new];
            model3.keyId = model1.keyId;
            
            [[[[[model1 rac_saveStorage:nil] flattenMap:^RACStream *(id value) {
                return [model2 rac_fetchStorage:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model1 rac_destroyStorage:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model3 rac_fetchStorage:nil];
            }] subscribeNext:^(id x) {

            }];
            [[expectFutureValue(model2.title) shouldEventually] beNonNil];
            [[expectFutureValue(model3.title) shouldEventually] beNil];
        });

        it(@"没取到的情况会进入error", ^{
            YTXTestAFNetworkingRemoteModel *model1 = [YTXTestAFNetworkingRemoteModel new];
            model1.keyId = @2006;
            __block YTXTestAFNetworkingRemoteModel *model2 = [YTXTestAFNetworkingRemoteModel new];
            model2.keyId = model1.keyId;
            __block NSError *ret = nil;

            [[model1 rac_destroyStorage:nil] subscribeNext:^(id x) {
                [[model2 rac_fetchStorage:nil] subscribeError:^(NSError *error) {
                    ret = error;
                }];
            }] ;

            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });

        it(@"更换UserDefalut的group", ^{
            YTXTestAFNetworkingRemoteModel *model1 = [YTXTestAFNetworkingRemoteModel new];
            model1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName3];
            model1.keyId = @2007;
            model1.title = @"testModel1";

            __block YTXTestAFNetworkingRemoteModel *model2 = [YTXTestAFNetworkingRemoteModel new];
            model2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName4];
            model2.keyId = @2007;
            model2.title = @"testModel2";

            __block YTXTestAFNetworkingRemoteModel *model3 = [YTXTestAFNetworkingRemoteModel new];
            model3.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName3];
            model3.keyId = @2007;

            __block YTXTestAFNetworkingRemoteModel *model4 = [YTXTestAFNetworkingRemoteModel new];
            model4.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName4];
            model4.keyId = @2007;
            
            [[[[[model1 rac_saveStorage:nil] flattenMap:^RACStream *(id value) {
                return [model3 rac_fetchStorage:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model2 rac_saveStorage:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model4 rac_fetchStorage:nil];
            }] subscribeNext:^(id x) {
                
            }];

            [[expectFutureValue(model3.title) shouldEventually] equal:@"testModel1"];
            [[expectFutureValue(model4.title) shouldEventually] equal:@"testModel2"];

        });
    });

    context(@"Collection异步功能", ^{
        beforeAll(^{
            //清空以便测试
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];

            collection1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName3];

            YTXTestAFNetworkingRemoteCollection *collection2 = [YTXTestAFNetworkingRemoteCollection new];
            collection2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName4];

            YTXTestAFNetworkingRemoteCollection *collection3 = [YTXTestAFNetworkingRemoteCollection new];

            [collection1 destroyStorageSync:nil];
            [collection2 destroyStorageSync:nil];
            [collection3 destroyStorageSync:nil];
        });

        it(@"保存缓存成功，自定义storageKey", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            __block YTXTestAFNetworkingRemoteCollection *ret1 = nil;
            [[collection1 rac_saveStorageWithKey:@"storageKey1" param:nil] subscribeNext:^(id x) {
                ret1 = x;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(ret1) shouldEventually] equal:collection1];
        });

        it(@"获取缓存成功，自定义storageKey", ^{
            YTXTestAFNetworkingRemoteCollection *collection = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model1.keyId = @1;
            YTXTestAFNetworkingRemoteModel *model2 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model3 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            YTXTestAFNetworkingRemoteModel *model4 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            [collection addModels:@[model1, model2, model3, model4]];
            __block YTXTestAFNetworkingRemoteCollection *ret = nil;
            [[[collection rac_saveStorageWithKey:@"storageKey1" param:nil] flattenMap:^RACStream *(id value) {
                return [collection rac_fetchStorageWithKey:@"storageKey1" param:nil];
            }] subscribeNext:^(id x) {
                ret = x;
            }];

            [[expectFutureValue(@(ret.models.count)) shouldEventually] equal:@(collection.models.count)];
            [[expectFutureValue(((YTXTestAFNetworkingRemoteModel *)ret.models.firstObject).keyId) shouldEventually] equal:@1];
        });

        it(@"保存缓存成功并且可以读取到，使用storageKey", ^{
            YTXTestAFNetworkingRemoteCollection *collection = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model.keyId = @1;
            [collection addModels:@[model]];
            __block YTXTestAFNetworkingRemoteCollection *ret = [YTXTestAFNetworkingRemoteCollection new];
            [[collection rac_saveStorageWithKey:@"storageKey3" param:nil] subscribeNext:^(id x) {
                [ret rac_fetchStorageWithKey:@"storageKey3" param:nil];
            }];

            [[expectFutureValue(((YTXTestAFNetworkingRemoteModel *)ret.models.firstObject).keyId) shouldEventually] equal:model.keyId];
        });

        it(@"删除缓存成功，使用storageKey", ^{
            YTXTestAFNetworkingRemoteCollection *collection = [YTXTestAFNetworkingRemoteCollection new];
            __block NSNumber *ret = @1;
            [[collection rac_destroyStorageWithKey:@"storageKey4" param:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(ret) shouldEventually] beNil];
        });

        it(@"删除缓存成功并且读不到，使用storageKey", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model.keyId = @1;
            [collection1 addModels:@[model]];
            __block YTXTestAFNetworkingRemoteCollection *collection2 = [YTXTestAFNetworkingRemoteCollection new];
            __block YTXTestAFNetworkingRemoteCollection *collection3 = [YTXTestAFNetworkingRemoteCollection new];

            [[[[[collection1 rac_saveStorageWithKey:@"storageKey5" param:nil] flattenMap:^RACStream *(id value) {
                return [collection2 rac_fetchStorageWithKey:@"storageKey5" param:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection1 rac_destroyStorageWithKey:@"storageKey5" param:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection3 rac_fetchStorageWithKey:@"storageKey5" param:nil];
            }] subscribeNext:^(id x) {

            }];
            [[expectFutureValue(((YTXTestAFNetworkingRemoteModel *)collection2.models.firstObject).keyId) shouldEventually] equal:@1];
            [[expectFutureValue(((YTXTestAFNetworkingRemoteModel *)collection3.models.firstObject).keyId) shouldEventually] beNil];
        });

        it(@"没取到的情况会进入error", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            __block YTXTestAFNetworkingRemoteCollection *collection2 = [YTXTestAFNetworkingRemoteCollection new];

            __block NSError *ret = nil;

            [[collection1 rac_saveStorageWithKey:@"key6" param:nil] subscribeNext:^(id x) {
                [[collection2 rac_fetchStorageWithKey:@"abc" param:nil] subscribeError:^(NSError *error) {
                    ret = error;
                }];
            }] ;

            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });

        it(@"使用storageKey确实根据key存了不同份到storage中", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            __block YTXTestAFNetworkingRemoteCollection *collection2 = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model2 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model2.keyId = @2;
            [collection2 addModels:@[model2]];
            __block YTXTestAFNetworkingRemoteCollection *collection3 = [YTXTestAFNetworkingRemoteCollection new];

            __block YTXTestAFNetworkingRemoteCollection *collection4 = [YTXTestAFNetworkingRemoteCollection new];


            [[[[[collection1 rac_saveStorageWithKey:@"key111" param:nil] flattenMap:^RACStream *(id value) {
                return [collection2 rac_saveStorageWithKey:@"key222" param:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection3 rac_fetchStorageWithKey:@"key111" param:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection4 rac_fetchStorageWithKey:@"key222" param:nil];
            }] subscribeNext:^(id x) {

            }];

            [[expectFutureValue(((YTXTestAFNetworkingRemoteModel *)collection3.models.firstObject).keyId) shouldEventually] equal:@1];
            [[expectFutureValue(((YTXTestAFNetworkingRemoteModel *)collection4.models.firstObject).keyId) shouldEventually] equal:@2];
            [[expectFutureValue(((YTXTestAFNetworkingRemoteModel *)collection3.models.firstObject).keyId) shouldNotEventually] equal:expectFutureValue(((YTXTestAFNetworkingRemoteModel *)collection4.models.firstObject).keyId)];

        });

        it(@"保存缓存成功", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            __block YTXTestAFNetworkingRemoteCollection *ret = nil;
            [[collection1 rac_saveStorage:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(((YTXTestAFNetworkingRemoteModel *)ret.models.firstObject).keyId) shouldEventually] equal:((YTXTestAFNetworkingRemoteModel *)collection1.models.firstObject).keyId];
        });

        it(@"获取缓存成功", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            __block YTXTestAFNetworkingRemoteCollection *ret = [YTXTestAFNetworkingRemoteCollection new];

            [[[collection1 rac_saveStorage:nil] flattenMap:^RACStream *(id value) {
                return [ret rac_fetchStorage:nil];
            }] subscribeNext:^(id x) {
                ret = x;
            }];

            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });

        it(@"保存缓存成功并且可以读取到", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            __block YTXTestAFNetworkingRemoteCollection *ret =  [YTXTestAFNetworkingRemoteCollection new];

            [[collection1 rac_saveStorage:nil] subscribeNext:^(id x) {
                [ret rac_fetchStorage:nil];
            }];

            [[expectFutureValue(((YTXTestAFNetworkingRemoteModel *)ret.models.firstObject).keyId) shouldEventually] equal:((YTXTestAFNetworkingRemoteModel *)collection1.models.firstObject).keyId];
        });

        it(@"删除缓存成功", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            __block NSNumber *ret = @1;
            [[collection1 rac_destroyStorage:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(ret) shouldEventually] beNil];
        });

        it(@"删除缓存成功并且读不到", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            __block YTXTestAFNetworkingRemoteCollection *collection2 =  [YTXTestAFNetworkingRemoteCollection new];
            __block YTXTestAFNetworkingRemoteCollection *collection3 =  [YTXTestAFNetworkingRemoteCollection new];

            [[[[[collection1 rac_saveStorage:nil] flattenMap:^RACStream *(id value) {
                return [collection2 rac_fetchStorage:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection1 rac_destroyStorage:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection3 rac_fetchStorage:nil];
            }] subscribeNext:^(id x) {

            }];
            [[expectFutureValue(((YTXTestAFNetworkingRemoteModel *)collection2.models.firstObject).keyId) shouldEventually] beNonNil];
            [[expectFutureValue(((YTXTestAFNetworkingRemoteModel *)collection3.models.firstObject).keyId) shouldEventually] beNil];
        });

        it(@"没取到的情况会进入error", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            YTXTestAFNetworkingRemoteModel *model1 = [[YTXTestAFNetworkingRemoteModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            __block YTXTestAFNetworkingRemoteCollection *collection2 =  [YTXTestAFNetworkingRemoteCollection new];
            __block NSError *ret = nil;

            [[collection1 rac_destroyStorage:nil] subscribeNext:^(id x) {
                [[collection2 rac_fetchStorage:nil] subscribeError:^(NSError *error) {
                    ret = error;
                }];
            }] ;

            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });

        it(@"更换UserDefalut的group", ^{
            YTXTestAFNetworkingRemoteCollection *collection1 = [YTXTestAFNetworkingRemoteCollection new];
            collection1.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName3];
            [collection1 addModels:@[[YTXTestAFNetworkingRemoteModel new]]];

            YTXTestAFNetworkingRemoteCollection *collection2 = [YTXTestAFNetworkingRemoteCollection new];
            collection2.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName4];

            YTXTestAFNetworkingRemoteCollection *collection3 = [YTXTestAFNetworkingRemoteCollection new];
            collection3.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName3];

            YTXTestAFNetworkingRemoteCollection *collection4 = [YTXTestAFNetworkingRemoteCollection new];
            collection4.storageSync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName4];

            [[[[collection1 rac_saveStorage:nil] flattenMap:^RACStream *(id value) {
                return [collection3 rac_fetchStorage:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection2 rac_fetchStorage:nil];
            }] subscribeError:^(NSError * x) {
                [collection2 addModels:@[[YTXTestAFNetworkingRemoteModel new], [YTXTestAFNetworkingRemoteModel new]]];
                [[[collection2 rac_saveStorage:nil] flattenMap:^RACStream *(id value) {
                    return [collection4 rac_fetchStorage:nil];
                }] subscribeNext:^(id x) {
                    [collection2 removeAllModels];
                    [collection2 rac_destroyStorage:nil];
                }];
            }];

            [[expectFutureValue(@(collection2.models.count)) shouldEventually] equal:@0];
            [[expectFutureValue(@(collection3.models.count)) shouldEventually] equal:@1];
            [[expectFutureValue(@(collection4.models.count)) shouldEventually] equal:@2];
        });

    });

});

SPEC_END
