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

@interface YTXCollection()

@property (nonnull, nonatomic, strong) NSArray * models;

@end

@implementation YTXCollection

- (instancetype)init
{
    if(self = [super init])
    {
        self.cacheSync = [[YTXCollectionUserDefaultCacheSync alloc] initWithModelClass:[YTXRestfulModel class]];
        self.remoteSync = [YTXRestfulModelYTXRequestRemoteSync new];
        self.modelClass = [YTXRestfulModel class];
        self.models = @[];
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
        self.models = @[];
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
        [self resetModels:x];
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

- (RACSignal *)fetchCacheWithCacheKey:(NSString *)cacheKey withParam:(NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.cacheSync fetchCacheWithCacheKey:cacheKey withParam:param] subscribeNext:^(NSArray * x) {
        @strongify(self);
        //读cache就直接替换
        [self resetModels:x];
        [subject sendNext:self];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (RACSignal *)saveCacheWithCacheKey:(NSString *)cacheKey withParam:(NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    [[self.cacheSync saveCacheWithCacheKey:cacheKey withParam:param withCollection:self.models] subscribeNext:^(id x) {
        [subject sendNext:self];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (RACSignal *)destroyCacheWithCacheKey:(NSString *)cacheKey withParam:(NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    [[self.cacheSync destroyCacheWithCacheKey:cacheKey withParam:param] subscribeNext:^(id x) {
        [subject sendNext:self];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

#pragma mark remote

/** 在拉到数据转mantle的时候用 */
- (nonnull NSArray *) transformerProxyOfReponse:(nonnull id) response
{
    return [MTLJSONAdapter modelsOfClass:[self modelClass] fromJSONArray:response error:nil];
}

- (nonnull instancetype) removeAllModels
{
    self.models = @[];
    return self;
}

- (nonnull instancetype) resetModels:(nonnull NSArray *) array
{
# if DEBUG
    for (id item in array) {
        NSAssert([item isMemberOfClass:self.modelClass], @"加入的数组中的每一项都必须是当前的Model类型");
    }
# endif
    self.models = array;
    return self;
}

- (nonnull instancetype) addModels:(nonnull NSArray *) array
{
    NSMutableArray * temp = [NSMutableArray arrayWithArray:self.models];
    
    [temp addObjectsFromArray:array];
    
    return [self resetModels:temp];
}

- (nonnull instancetype) insertFrontModels:(nonnull NSArray *) array
{
    NSMutableArray * temp = [NSMutableArray arrayWithArray:array];
    
    [temp addObjectsFromArray:self.models];
    
    return [self resetModels:temp];
}

- (nonnull instancetype)sortedArrayUsingComparator:(NSComparator)cmptr
{
    [self resetModels:[self.models sortedArrayUsingComparator:cmptr]];
    return self;
}

- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.remoteSync fetchRemote:param] subscribeNext:^(id x) {
        @strongify(self);
        NSArray * arr = [self transformerProxyOfReponse:x];
        [subject sendNext: RACTuplePack(self, arr) ];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (nonnull RACSignal *) fetchRemoteThenReset:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.remoteSync fetchRemote:param] subscribeNext:^(id x) {
        @strongify(self);
        NSArray * arr = [self transformerProxyOfReponse:x];
        [self resetModels:arr];
        [subject sendNext: self];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (nullable NSArray *) arrayWithRange:(NSRange)range
{
    if (range.location + range.length > self.models.count) {
        return nil;
    }
    
    return [self.models subarrayWithRange:range];
}

- (nullable YTXCollection *) collectionWithRange:(NSRange)range
{
    NSArray * arr = [self arrayWithRange:range];
    
    return arr ? [[[YTXCollection alloc] initWithModelClass:self.modelClass] addModels:arr] : nil;
}

- (nullable YTXRestfulModel *) modelAtIndex:(NSInteger) index
{
    if (index < 0 || index >= self.models.count) {
        return nil;
    }
    
    return self.models[index];
}

- (nullable YTXRestfulModel *) modelWithPrimaryKey:(nonnull NSString *) primaryKey
{
    for (YTXRestfulModel *model in self.models) {
        if ( [[[model primaryValue] description] isEqualToString:primaryKey]) {
            return model;
        }
    }
    return nil;
}

- (BOOL) addModel:(nonnull YTXRestfulModel *) model
{
    NSMutableArray * temp = [NSMutableArray arrayWithArray:self.models];
    [temp addObject:model];
    [self resetModels:temp];
    return YES;
}

- (BOOL) insertFrontModel:(nonnull YTXRestfulModel *) model
{
    return [self insertModel:model beforeIndex:0];
}

/** 插入到index之后*/
- (BOOL) insertModel:(nonnull YTXRestfulModel *) model afterIndex:(NSInteger) index
{
    if (self.models.count == 0 || self.models.count == index+1) {
        return [self addModel:model];
    }
    
    if (index < 0 || index >= self.models.count) {
        return NO;
    }
    NSMutableArray * temp = [NSMutableArray arrayWithArray:self.models];
    [temp insertObject:model atIndex:index+1];
    [self resetModels:temp];
    return YES;
}

/** 插入到index之前*/
- (BOOL) insertModel:(nonnull YTXRestfulModel *) model beforeIndex:(NSInteger) index
{
    if (self.models.count == 0) {
        return [self addModel:model];
    }
    
    if (index < 0 || index >= self.models.count) {
        return NO;
    }
    NSMutableArray * temp = [NSMutableArray arrayWithArray:self.models];
    [temp insertObject:model atIndex:index];
    [self resetModels:temp];
    return YES;
}

- (BOOL) removeModelAtIndex:(NSInteger) index
{
    if (index < 0 || index >= self.models.count) {
        return NO;
    }
    NSMutableArray * temp = [NSMutableArray arrayWithArray:self.models];
    [temp removeObjectAtIndex:index];
    [self resetModels:temp];
    return YES;
}

/** 主键可能是NSNumber或NSString，统一转成NSString来判断*/
- (BOOL) removeModelWithPrimaryKey:(nonnull NSString *) primaryKey
{
    for (YTXRestfulModel *model in self.models) {
        if ( [[[model primaryValue] description] isEqualToString:primaryKey]) {
            NSMutableArray * temp = [NSMutableArray arrayWithArray:self.models];
            [temp removeObject:model];
            [self resetModels:temp];
            return YES;
        }
    }
    return NO;
}

- (BOOL) removeModelWithModel:(nonnull YTXRestfulModel *) model
{
    NSMutableArray * temp = [NSMutableArray arrayWithArray:self.models];
    
    NSInteger index = [[self models] indexOfObject:model];
    
    if (NSNotFound == index) {
        return NO;
    }
    
    [temp removeObjectAtIndex:index];
    [self resetModels:temp];
    return YES;
}

- (void)reverseModels
{
    [self resetModels:self.models.reverseObjectEnumerator.allObjects];
}

@end
