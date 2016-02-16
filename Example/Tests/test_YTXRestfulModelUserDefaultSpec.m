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


SPEC_BEGIN(YTXRestfulModelUserDefaultSpec)

describe(@"测试YTXRestfulModelUserDefault", ^{

    context(@"Model功能", ^{
        
        it(@"保存缓存成功，使用cacheKey", ^{
            YTXTestModel *model = [YTXTestModel new];
            __block YTXTestModel *ret = nil;
            [[model saveCacheWithCacheKey:@"key1" withParam:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {
                
            }];
            [[expectFutureValue(ret) shouldEventually] equal:model];
        });
        
        it(@"获取缓存成功，使用cacheKey", ^{
            YTXTestModel *model = [YTXTestModel new];
            __block YTXTestModel *ret = nil;
            
            [[[model saveCacheWithCacheKey:@"key2" withParam:nil] flattenMap:^RACStream *(id value) {
                return [model fetchCacheWithCacheKey:@"key2" withParam:nil];
            }] subscribeNext:^(id x) {
                ret = x;
            }];
            
            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });
        
        it(@"保存缓存成功并且可以读取到，使用cacheKey", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.keyId = @1;
            __block YTXTestModel *model2 = [YTXTestModel new];
            [[model1 saveCacheWithCacheKey:@"key3" withParam:nil] subscribeNext:^(id x) {
                [model2 fetchCacheWithCacheKey:@"key3" withParam:nil];
            }];
            
            [[expectFutureValue(model2.keyId) shouldEventually] equal:model1.keyId];
        });
        
        it(@"删除缓存成功，使用cacheKey", ^{
            YTXTestModel *model = [YTXTestModel new];
            __block YTXTestModel *ret = nil;
            [[model destroyCacheWithCacheKey:@"key4" withParam:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {
                
            }];
            [[expectFutureValue(ret) shouldEventually] equal:model];
        });
        
        it(@"删除缓存成功并且读不到，使用cacheKey", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.keyId = @1;
            __block YTXTestModel *model2 = [YTXTestModel new];
            __block YTXTestModel *model3 = [YTXTestModel new];
            
            [[[[[model1 saveCacheWithCacheKey:@"key5" withParam:nil] flattenMap:^RACStream *(id value) {
                return [model2 fetchCacheWithCacheKey:@"key5" withParam:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model1 destroyCacheWithCacheKey:@"key5" withParam:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model3 fetchCacheWithCacheKey:@"key5" withParam:nil];
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
            
            [[model1 saveCacheWithCacheKey:@"key6" withParam:nil] subscribeNext:^(id x) {
                [[model2 fetchCacheWithCacheKey:@"abc" withParam:nil] subscribeError:^(NSError *error) {
                    ret = error;
                }];
            }] ;
            
            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });
        
        it(@"使用cacheKey确实根据key存了不同份到cache中", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.keyId = @1;
            __block YTXTestModel *model2 = [YTXTestModel new];
            model2.keyId = @2;
            __block YTXTestModel *model3 = [YTXTestModel new];
            __block YTXTestModel *model4 = [YTXTestModel new];
            
            [[[[[model1 saveCacheWithCacheKey:@"key111" withParam:nil] flattenMap:^RACStream *(id value) {
                return [model2 saveCacheWithCacheKey:@"key222" withParam:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model3 fetchCacheWithCacheKey:@"key111" withParam:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model4 fetchCacheWithCacheKey:@"key222" withParam:nil];
            }] subscribeNext:^(id x) {
                
            }];
            
            [[expectFutureValue(model3.keyId) shouldEventually] equal:@1];
            [[expectFutureValue(model4.keyId) shouldEventually] equal:@2];
            [[expectFutureValue(model3.keyId) shouldNotEventually] equal:expectFutureValue(model4.keyId)];
            
        });
        
        it(@"保存缓存成功", ^{
            YTXTestModel *model = [YTXTestModel new];
            __block YTXTestModel *ret = nil;
            [[model saveCache:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {
                
            }];
            [[expectFutureValue(ret) shouldEventually] equal:model];
        });
        
        it(@"获取缓存成功", ^{
            YTXTestModel *model = [YTXTestModel new];
            __block YTXTestModel *ret = nil;
            
            [[[model saveCache:nil] flattenMap:^RACStream *(id value) {
                return [model fetchCache:nil];
            }] subscribeNext:^(id x) {
                ret = x;
            }];
            
            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });
        
        it(@"保存缓存成功并且可以读取到", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.keyId = @1;
            __block YTXTestModel *model2 = [YTXTestModel new];
            [[model1 saveCache:nil] subscribeNext:^(id x) {
                [model2 fetchCache:nil];
            }];

            [[expectFutureValue(model2.keyId) shouldEventually] equal:model1.keyId];
        });
        
        it(@"删除缓存成功", ^{
            YTXTestModel *model = [YTXTestModel new];
            __block YTXTestModel *ret = nil;
            [[model destroyCache:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {
                
            }];
            [[expectFutureValue(ret) shouldEventually] equal:model];
        });
        
        it(@"删除缓存成功并且读不到", ^{
            YTXTestModel *model1 = [YTXTestModel new];
            model1.keyId = @1;
            __block YTXTestModel *model2 = [YTXTestModel new];
            __block YTXTestModel *model3 = [YTXTestModel new];
            
            [[[[[model1 saveCache:nil] flattenMap:^RACStream *(id value) {
                return [model2 fetchCache:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model1 destroyCache:nil];
            }] flattenMap:^RACStream *(id value) {
                return [model3 fetchCache:nil];
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
            
            [[model1 destroyCache:nil] subscribeNext:^(id x) {
                [[model2 fetchCache:nil] subscribeError:^(NSError *error) {
                    ret = error;
                }];
            }] ;
            
            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });

    });
    
    context(@"Collection功能", ^{
        it(@"保存缓存成功，自定义cacheKey", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            __block YTXTestCollection *ret1 = nil;
            [[collection1 saveCacheWithCacheKey:@"cacheKey1" withParam:nil] subscribeNext:^(id x) {
                ret1 = x;
            } error:^(NSError *error) {
                
            }];
            [[expectFutureValue(ret1) shouldEventually] equal:collection1];
        });
        
        it(@"获取缓存成功，自定义cacheKey", ^{
            YTXTestCollection *collection = [YTXTestCollection new];
            YTXTestModel *model1 = [[YTXTestModel alloc] init];
            model1.keyId = @1;
            YTXTestModel *model2 = [[YTXTestModel alloc] init];
            YTXTestModel *model3 = [[YTXTestModel alloc] init];
            YTXTestModel *model4 = [[YTXTestModel alloc] init];
            [collection addModels:@[model1, model2, model3, model4]];
            __block YTXTestCollection *ret = nil;
            [[[collection saveCacheWithCacheKey:@"cacheKey1" withParam:nil] flattenMap:^RACStream *(id value) {
                return [collection fetchCacheWithCacheKey:@"cacheKey1" withParam:nil];
            }] subscribeNext:^(id x) {
                ret = x;
            }];
           
            [[expectFutureValue(@(ret.models.count)) shouldEventually] equal:@(collection.models.count)];
            [[expectFutureValue(((YTXTestModel *)ret.models.firstObject).keyId) shouldEventually] equal:@1];
        });
        
        it(@"保存缓存成功并且可以读取到，使用cacheKey", ^{
            YTXTestCollection *collection = [YTXTestCollection new];
            YTXTestModel *model = [[YTXTestModel alloc] init];
            model.keyId = @1;
            [collection addModels:@[model]];
            __block YTXTestCollection *ret = [YTXTestCollection new];
            [[collection saveCacheWithCacheKey:@"cacheKey3" withParam:nil] subscribeNext:^(id x) {
                [ret fetchCacheWithCacheKey:@"cacheKey3" withParam:nil];
            }];
            
            [[expectFutureValue(((YTXTestModel *)ret.models.firstObject).keyId) shouldEventually] equal:model.keyId];
        });
        
        it(@"删除缓存成功，使用cacheKey", ^{
            YTXTestCollection *collection = [YTXTestCollection new];
            __block YTXTestModel *ret = nil;
            [[collection destroyCacheWithCacheKey:@"cacheKey4" withParam:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {

            }];
            [[expectFutureValue(ret) shouldEventually] equal:collection];
        });
        
        it(@"删除缓存成功并且读不到，使用cacheKey", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            YTXTestModel *model = [[YTXTestModel alloc] init];
            model.keyId = @1;
            [collection1 addModels:@[model]];
            __block YTXTestCollection *collection2 = [YTXTestCollection new];
            __block YTXTestCollection *collection3 = [YTXTestCollection new];
            
            [[[[[collection1 saveCacheWithCacheKey:@"cacheKey5" withParam:nil] flattenMap:^RACStream *(id value) {
                return [collection2 fetchCacheWithCacheKey:@"cacheKey5" withParam:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection1 destroyCacheWithCacheKey:@"cacheKey5" withParam:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection3 fetchCacheWithCacheKey:@"cacheKey5" withParam:nil];
            }] subscribeNext:^(id x) {
                
            }];
            [[expectFutureValue(((YTXTestModel *)collection2.models.firstObject).keyId) shouldEventually] equal:@1];
            [[expectFutureValue(((YTXTestModel *)collection3.models.firstObject).keyId) shouldEventually] beNil];
        });

        it(@"没取到的情况会进入error", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            __block YTXTestCollection *collection2 = [YTXTestCollection new];
            
            __block NSError *ret = nil;
            
            [[collection1 saveCacheWithCacheKey:@"key6" withParam:nil] subscribeNext:^(id x) {
                [[collection2 fetchCacheWithCacheKey:@"abc" withParam:nil] subscribeError:^(NSError *error) {
                    ret = error;
                }];
            }] ;
            
            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });
        
        it(@"使用cacheKey确实根据key存了不同份到cache中", ^{
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


            [[[[[collection1 saveCacheWithCacheKey:@"key111" withParam:nil] flattenMap:^RACStream *(id value) {
                return [collection2 saveCacheWithCacheKey:@"key222" withParam:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection3 fetchCacheWithCacheKey:@"key111" withParam:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection4 fetchCacheWithCacheKey:@"key222" withParam:nil];
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
            [[collection1 saveCache:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {
                
            }];
            [[expectFutureValue(((YTXTestModel *)ret.models.firstObject).keyId) shouldEventually] equal:((YTXTestModel *)collection1.models.firstObject).keyId];
        });
        
        it(@"获取缓存成功", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            __block YTXTestCollection *ret = [YTXTestCollection new];
            
            [[[collection1 saveCache:nil] flattenMap:^RACStream *(id value) {
                return [ret fetchCache:nil];
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

            [[collection1 saveCache:nil] subscribeNext:^(id x) {
                [ret fetchCache:nil];
            }];
            
            [[expectFutureValue(((YTXTestModel *)ret.models.firstObject).keyId) shouldEventually] equal:((YTXTestModel *)collection1.models.firstObject).keyId];
        });
        
        it(@"删除缓存成功", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            __block YTXTestCollection *ret = nil;
            [[collection1 destroyCache:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {
                
            }];
            [[expectFutureValue(ret) shouldEventually] equal:collection1];
        });
        
        it(@"删除缓存成功并且读不到", ^{
            YTXTestCollection *collection1 = [YTXTestCollection new];
            YTXTestModel *model1 = [[YTXTestModel alloc] init];
            model1.keyId = @1;
            [collection1 addModels:@[model1]];
            __block YTXTestCollection *collection2 =  [YTXTestCollection new];
            __block YTXTestCollection *collection3 =  [YTXTestCollection new];
            
            [[[[[collection1 saveCache:nil] flattenMap:^RACStream *(id value) {
                return [collection2 fetchCache:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection1 destroyCache:nil];
            }] flattenMap:^RACStream *(id value) {
                return [collection3 fetchCache:nil];
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
            
            [[collection1 destroyCache:nil] subscribeNext:^(id x) {
                [[collection2 fetchCache:nil] subscribeError:^(NSError *error) {
                    ret = error;
                }];
            }] ;
            
            [[expectFutureValue(ret) shouldEventually] beNonNil];
        });
        
    });
    
});

SPEC_END
