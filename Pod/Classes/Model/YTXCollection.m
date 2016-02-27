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
        self.storageSync = [YTXRestfulModelUserDefaultStorageSync new];
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
        self.storageSync = [YTXRestfulModelUserDefaultStorageSync new];
        self.remoteSync = [YTXRestfulModelYTXRequestRemoteSync new];
        self.modelClass = modelClass;
        self.models = @[];
    }
    return self;
}

#pragma mark storage
/** GET */
- (nonnull instancetype) fetchStorageSync:(nullable NSDictionary *) param
{
    return [self fetchStorageSyncWithKey:[self storageKey] withParam:param];
}

/** POST / PUT */
- (nonnull instancetype) saveStorageSync:(nullable NSDictionary *) param
{
    return [self saveStorageSyncWithKey:[self storageKey] withParam:param];
}

/** DELETE */
- (void) destroyStorageSync:(nullable NSDictionary *) param
{
    return [self destroyStorageSyncWithKey:[self storageKey] withParam:param];
}

/** GET */
- (nonnull  instancetype) fetchStorageSyncWithKey:(nonnull NSString *)storage withParam:(nullable NSDictionary *) param
{
    NSArray * x = [self.storageSync fetchStorageSyncWithKey:storage param:param];
    if (x) {
        NSArray * ret = [self transformerProxyOfReponse:x error:nil];
        [self resetModels:ret];
    }
    return self;
}

/** POST / PUT */
- (nonnull instancetype) saveStorageSyncWithKey:(nonnull NSString *)storage withParam:(nullable NSDictionary *) param
{
    [self.storageSync saveStorageSyncWithKey:storage withObject:[self transformerProxyOfModels:[self.models copy]] param:param];

    return self;
}

/** DELETE */
- (void) destroyStorageSyncWithKey:(nonnull NSString *)storage withParam:(nullable NSDictionary *) param
{
    [self.storageSync destroyStorageSyncWithKey:storage param:param];
}

/** GET */
- (nonnull RACSignal *) fetchStorage:(nullable NSDictionary *)param
{
    return [self fetchStorageWithKey:[self storageKey] param:param];
}

/** POST / PUT */
- (nonnull RACSignal *) saveStorage:(nullable NSDictionary *)param
{
    return [self saveStorageWithKey:[self storageKey] param:param];
}

/** DELETE */
- (nonnull RACSignal *) destroyStorage:(nullable NSDictionary *)param
{
    return [self destroyStorageWithKey:[self storageKey] param:param];}

- (RACSignal *)fetchStorageWithKey:(NSString *)storageKey param:(NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.storageSync fetchStorageWithKey:storageKey param:param] subscribeNext:^(NSArray * x) {
        @strongify(self);
        //读storage就直接替换
        NSError * error = nil;
        NSArray * ret = [self transformerProxyOfReponse:x error:&error];
        
        if (!error) {
            [self resetModels:ret];
            [subject sendNext:self];
            [subject sendCompleted];
        }
        else {
            [subject sendError:error];
        }
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (RACSignal *)saveStorageWithKey:(NSString *)storageKey param:(NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.storageSync saveStorageWithKey:storageKey withObject:[self transformerProxyOfModels:[self.models copy]] param:param] subscribeNext:^(id x) {
        @strongify(self);
        [subject sendNext:self];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (RACSignal *)destroyStorageWithKey:(NSString *)storageKey param:(NSDictionary *)param
{
    return [self.storageSync destroyStorageWithKey:storageKey param:param];
}

- (nonnull NSString *) storageKey
{
    return [NSString stringWithFormat:@"EFSCollection+%@", NSStringFromClass(self.modelClass)];
}

#pragma mark remote

/** 在拉到数据转mantle的时候用 */
- (nullable NSArray< id<MTLJSONSerializing> > *) transformerProxyOfReponse:(nullable NSArray<NSDictionary *> *) response error:(NSError * _Nullable * _Nullable) error
{
    return [MTLJSONAdapter modelsOfClass:[self modelClass] fromJSONArray:response error:error];
}
     
    /** 在拉到数据转mantle的时候用 */
- (nullable NSArray<NSDictionary *> *) transformerProxyOfModels:(nonnull NSArray< id<MTLJSONSerializing> > *) array
{
    return [MTLJSONAdapter JSONArrayFromModels:array];
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
        NSError * error = nil;

        NSArray * arr = [self transformerProxyOfReponse:x error:&error];
        if (!error) {
            [subject sendNext: RACTuplePack(self, arr) ];
            [subject sendCompleted];
        }
        else {
            [subject sendError:error];
        }

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
        NSError * error = nil;

        NSArray * arr = [self transformerProxyOfReponse:x error:&error];
        if (!error) {
            [self resetModels:arr];
            [subject sendNext:self];
            [subject sendCompleted];
        }
        else {
            [subject sendError:error];
        }

    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (nonnull RACSignal *) fetchRemoteThenAdd:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.remoteSync fetchRemote:param] subscribeNext:^(id x) {
        @strongify(self);
        NSError * error = nil;

        NSArray * arr = [self transformerProxyOfReponse:x error:&error];
        if (!error) {
            [self addModels:arr];
            [subject sendNext:self];
            [subject sendCompleted];
        }
        else {
            [subject sendError:error];
        }
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
