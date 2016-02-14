//
//  YTXCollection.m
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/19.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import "YTXCollection.h"
#import "YTXRestfulModel.h"

#import <Mantle/Mantle.h>

typedef enum {
    RESET,
    ADD,
    INSERTFRONT,
} FetchRemoteHandleScheme;

@implementation YTXCollection

@synthesize url = _url;

- (instancetype)init
{
    if(self = [super init])
    {
        self.cacheSync = [[YTXCollectionUserDefaultCacheSync alloc] initWithModelClass:[YTXRestfulModel class]];
        self.remoteSync = [YTXRestfulModelYTXRequestRemoteSync new];
        self.modelClass = [YTXRestfulModel class];
        self.models = [NSMutableArray array];
    }
    return self;

}

- (instancetype)initWithModelClass:(Class)modelClass
{
    return [self initWithModelClass:modelClass userDefaultSuiteName:nil];
}

- (instancetype)initWithModelClass:(Class)modelClass userDefaultSuiteName:(NSString *) suiteName
{
    if(self = [super init])
    {
        self.cacheSync = [[YTXCollectionUserDefaultCacheSync alloc] initWithModelClass:modelClass userDefaultSuiteName:suiteName];
        self.remoteSync = [YTXRestfulModelYTXRequestRemoteSync new];
        self.modelClass = modelClass;
        self.models = [NSMutableArray array];
    }
    return self;
}

#pragma mark EFSCollectionProtocol
+ (instancetype) shared
{
    static YTXCollection * collection;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        collection =  [[[self class] alloc] init];
        NSAssert(collection.modelClass, @"如果使用Shared必须在子类实现init方法并且在内部绑定当前的Model");
    });
    return collection;
}

#pragma mark cache
- (nonnull RACSignal *) fetchCache:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.cacheSync fetchCache:param] subscribeNext:^(NSArray * x) {
        @strongify(self);
        //读cache就直接替换
        [self.models removeAllObjects];
        [self.models addObjectsFromArray:x];
        [subject sendNext:self];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (nonnull RACSignal *) saveCache:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    [[self.cacheSync saveCache:param withCollection:self.models] subscribeNext:^(id x) {
        [subject sendNext:self];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}
/** DELETE */
- (nonnull RACSignal *) destroyCache:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    [[self.cacheSync destroyCache:param] subscribeNext:^(id x) {
        [subject sendNext:self];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}


#pragma mark remote

- (void)setUrl:(NSURL *)url
{
    self.remoteSync.url = url;
}

- (NSURL *)url
{
    return self.remoteSync.url;
}

/** 在拉到数据转mantle的时候用 */
- (nonnull NSArray *) transformerProxyOfReponse:(nonnull id) response
{
    return [MTLJSONAdapter modelsOfClass:[self modelClass] fromJSONArray:response error:nil];
}

- (nonnull instancetype) resetModels:(nonnull NSArray *) array
{
    [self.models removeAllObjects];
    [self.models addObjectsFromArray:array];
    return self;
}

- (nonnull instancetype) addModels:(nonnull NSArray *) array
{
    [self.models addObjectsFromArray:array];
    return self;
}

- (nonnull instancetype) insertFrontModels:(nonnull NSArray *) array
{
    [[array mutableCopy] addObjectsFromArray: self.models];
    [self.models removeAllObjects];
    [self.models addObjectsFromArray:array];
    return self;
}

- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param withScheme:(FetchRemoteHandleScheme) scheme
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.remoteSync fetchRemote:param] subscribeNext:^(id x) {
        @strongify(self);
        NSArray * arr = [self transformerProxyOfReponse:x];
        switch (scheme) {
            case RESET:
                [self resetModels:arr];
                break;
            case ADD:
                [self addModels:arr];
                break;
            case INSERTFRONT:
                [self insertFrontModels:arr];
                break;
            default:
                break;
        }
        
        [subject sendNext:self];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

/* reset **/
- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param
{
    return [self fetchRemote:param withScheme:RESET];
}

/* add **/
- (nonnull RACSignal *) fetchRemoteThenAdd:(nullable NSDictionary *)param
{
    return [self fetchRemote:param withScheme:ADD];
}

/* insertFront **/
- (nonnull RACSignal *) fetchRemoteThenInsertFront:(nullable NSDictionary *)param
{
    return [self fetchRemote:param withScheme:INSERTFRONT];
}

@end
