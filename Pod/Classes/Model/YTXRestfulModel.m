//
//  YTXModel.m
//  YTXRestfulModel
//
//  Created by cao jun on 16/01/25.
//  Copyright © 2015 Elephants Financial Service. All rights reserved.
//

#import "YTXRestfulModel.h"

#import <Mantle/MTLEXTRuntimeExtensions.h>

#import <objc/runtime.h>

static void *YTXRestfulModelCachedPropertyKeysKey = &YTXRestfulModelCachedPropertyKeysKey;

@implementation YTXRestfulModel

- (instancetype)init
{
    if(self = [super init])
    {
        self.storageSync = [YTXRestfulModelUserDefaultStorageSync new];
        self.remoteSync = [YTXRestfulModelYTXRequestRemoteSync syncWithPrimaryKey: [[self class] syncPrimaryKey]];
        self.dbSync = [YTXRestfulModelFMDBSync syncWithModelOfClass:[self class] primaryKey: [[self class] syncPrimaryKey]];
    }
    return self;
}

#pragma mark MTL
- (NSDictionary *)dictionaryValue {
    NSDictionary *originalDictValue = [super dictionaryValue];
    NSMutableDictionary *dictValue = [originalDictValue mutableCopy];
    for (NSString *key in originalDictValue) {
        if ([self valueForKey:key] == nil) {
            [dictValue removeObjectForKey:key];
        }
    }
    //删除这个2个不必要的属性 可以用http://stackoverflow.com/questions/18961622/how-to-omit-null-values-in-json-dictionary-using-mantle这些方法，但是最合理的还是这个。
    [dictValue removeObjectForKey:@"remoteSync"];
    [dictValue removeObjectForKey:@"storageSync"];
    [dictValue removeObjectForKey:@"dbSync"];
    return [dictValue copy];
}



+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{};
}

#pragma mark EFSModelProtocol

- (instancetype) mergeWithAnother:(_Nonnull id) model
{
    if ([self class] != [model class]){
        return self;
    }
    NSSet * keys = [[self class] propertyKeys];
    
    for (NSString * key in keys) {
        id value = [model valueForKey:key];
        if (value) {
            [self setValue:value forKey:key];
        }
    }
    return self;
}

+ (nonnull NSString *)primaryKey
{
    return @"keyId";
}

- (nullable id) primaryValue
{
    return [self valueForKey:[[self class] primaryKey]];
}

+ (nonnull NSString *)syncPrimaryKey
{
    return [self JSONKeyPathsByPropertyKey][[self primaryKey]] ?: [self primaryKey];
}

/** 要用keyId判断 */
- (BOOL) isNew
{
    return [self valueForKey:[[self class] primaryKey]] == nil;
}


#pragma mark storage
- (nonnull RACSignal *) fetchStorage:(nullable NSDictionary *)param
{
    return [self fetchStorageWithKey:[self storageKey] withParam:param];
}

- (nonnull RACSignal *) saveStorage:(nullable NSDictionary *)param
{
    return [self saveStorageWithKey:[self storageKey] withParam:param];
}

/** DELETE */
- (nonnull RACSignal *) destroyStorage:(nullable NSDictionary *)param
{
    return [self destroyStorageWithKey:[self storageKey] withParam:param];
}

- (nonnull RACSignal *)fetchStorageWithKey:(NSString *)storage withParam:(NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.storageSync fetchStorageWithKey:storage param: param] subscribeNext:^(NSDictionary * x) {
        @strongify(self);
        NSError * error = nil;
        [self transformerProxyOfReponse:x error:&error];
        if (!error) {
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

- (nonnull RACSignal *)saveStorageWithKey:(nonnull NSString *)storage withParam:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.storageSync saveStorageWithKey:storage withObject:[self mergeSelfAndParameters:param] param: param] subscribeNext:^(NSDictionary * x) {
        @strongify(self);
        [subject sendNext:self];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (nonnull RACSignal *)destroyStorageWithKey:(nonnull NSString *)storage withParam:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    [[self.storageSync destroyStorageWithKey:storage param: param] subscribeNext:^(NSDictionary * x) {
        [subject sendNext:nil];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

- (nonnull NSString *) storageKey
{
    return [NSString stringWithFormat:@"EFSModel+%@", NSStringFromClass([self class])];
}

#pragma mark remote
/** 在拉到数据转mantle的时候用 */
- (nonnull instancetype) transformerProxyOfReponse:(nonnull id) response error:(NSError * _Nullable * _Nullable) error
{
    return [self mergeWithAnother:[MTLJSONAdapter modelOfClass:[self class] fromJSONDictionary:response error:error]];
}

- (nonnull NSDictionary *)mapParameters:(nonnull NSDictionary *)param
{
    NSMutableDictionary * retDict = [NSMutableDictionary dictionary];

    NSMutableDictionary *_JSONKeyPathsByPropertyKey = [[[self class] JSONKeyPathsByPropertyKey] copy];

    NSString * mappedPropertyKey = nil;

    for (NSString *key in param) {

        mappedPropertyKey = _JSONKeyPathsByPropertyKey[key] ? : key;

        retDict[mappedPropertyKey] = param[key];
    }

    return retDict;
}

- (nonnull NSDictionary *)mergeSelfAndParameters:(nullable NSDictionary *)param
{
    NSDictionary * mapParam = [self mapParameters:param];

    NSMutableDictionary *retDic = [[MTLJSONAdapter JSONDictionaryFromModel:self] mutableCopy];

    for (NSString *key in mapParam) {
        retDic[key] = mapParam[key];
    }
    return retDic;
}

- (nonnull id) transformerProxyOfForeign:(nonnull Class)modelClass reponse:(nonnull id) response error:(NSError * _Nullable * _Nullable) error;
{
    return [MTLJSONAdapter modelsOfClass:modelClass fromJSONArray:response error:error];
}

- (nonnull RACSignal *) fetchRemoteForeignWithName:(nonnull NSString *)name modelClass:(nonnull Class)modelClass param:(nullable NSDictionary *)param;
{
    NSAssert([modelClass isSubclassOfClass: [MTLModel class] ], @"希望传入的class是MTLModel的子类，这样才能使用mantle转换");
    @weakify(self);
    RACSubject * subject = [RACSubject subject];
    [[self.remoteSync fetchRemoteForeignWithName:name param:[self mergeSelfAndParameters:param]] subscribeNext:^(id x) {
        @strongify(self);
        NSError * error = nil;
        id model = [self transformerProxyOfForeign: modelClass reponse:x error:&error];
        if (!error) {
            [subject sendNext:model];
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

- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.remoteSync fetchRemote:[self mergeSelfAndParameters:param]] subscribeNext:^(id x) {
        @strongify(self);
        NSError * error = nil;
        [self transformerProxyOfReponse:x error:&error];
        if (!error) {
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

- (nonnull RACSignal *) saveRemote:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    if ([self isNew]) {
        [[self.remoteSync createRemote:[self mergeSelfAndParameters:param]] subscribeNext:^(id x) {
            @strongify(self);
            NSError * error = nil;
            [self transformerProxyOfReponse:x error:&error];
            if (!error) {
                [subject sendNext:self];
                [subject sendCompleted];
            }
            else {
                [subject sendError:error];
            }
        } error:^(NSError *error) {
            [subject sendError:error];
        }];
    }
    else {
        [[self.remoteSync updateRemote:[self mergeSelfAndParameters:param]] subscribeNext:^(id x) {
            @strongify(self);
            NSError * error = nil;
            [self transformerProxyOfReponse:x error:&error];
            if (!error) {
                [subject sendNext:self];
                [subject sendCompleted];
            }
            else {
                [subject sendError:error];
            }
        } error:^(NSError *error) {
             [subject sendError:error];
        }];
    }

    return subject;
}

- (nonnull RACSignal *) destroyRemote:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    [[self.remoteSync destroyRemote:[self mergeSelfAndParameters:param]] subscribeNext:^(id x) {
        [subject sendNext:nil];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];

    return subject;
}

#pragma mark DB
+ (nullable NSDictionary<NSString *, NSValue *> *) tableKeyPathsByPropertyKey
{
    NSDictionary<NSString *, NSValue *> * cachedKeys = objc_getAssociatedObject(self, YTXRestfulModelCachedPropertyKeysKey);
    if (cachedKeys != nil) return cachedKeys;
    
    NSMutableDictionary<NSString *, NSValue *> * properties =  [NSMutableDictionary dictionary];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    
    [[self class] performSelector:NSSelectorFromString(@"enumeratePropertiesUsingBlock:") withObject:^(objc_property_t property, BOOL *stop) {
        mtl_propertyAttributes *attributes = mtl_copyPropertyAttributes(property);
        char *propertyType = property_copyAttributeValue(property, "T");
        @onExit {
            free(attributes);
        };
        
        if (attributes->readonly && attributes->ivar == NULL) return;
        
        NSString *modelProperyName = @(property_getName(property));
        NSString *columnName = [self JSONKeyPathsByPropertyKey][modelProperyName] ? : modelProperyName;
        
        const char * propertyClassName = [[YTXRestfulModelFMDBSync formateObjectType:propertyType] UTF8String];
        
        BOOL isPrimaryKey = [modelProperyName isEqualToString:[self primaryKey]];
        
        struct YTXRestfulModelDBSerializingStruct dataStruct = {
            propertyClassName,
            [columnName UTF8String],
            [modelProperyName UTF8String],
            isPrimaryKey,
            NO,
            nil,
            NO
        };
        
        
        [properties setObject:[NSValue value:&dataStruct withObjCType:@encode(struct YTXRestfulModelDBSerializingStruct)] forKey:columnName];
    }];
#pragma clang diagnostic pop
    
    
    // It doesn't really matter if we replace another thread's work, since we do
    // it atomically and the result should be the same.
    objc_setAssociatedObject(self, YTXRestfulModelCachedPropertyKeysKey, properties, OBJC_ASSOCIATION_COPY);
    
    return properties;
}

+ (nullable NSNumber *) currentMigrationVersion
{
    return @0;
}

+ (BOOL) autoCreateTable
{
    return NO;
}

/** GET */
- (nonnull RACSignal *) fetchDB:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    
    @weakify(self);
    [[self.dbSync fetchOne:[self mergeSelfAndParameters:param]] subscribeNext:^(NSDictionary * x) {
        @strongify(self);
        NSError * error = nil;
        [self transformerProxyOfReponse:x error:&error];
        if (!error) {
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

/**
 * POST / PUT
 * 数据库不存在时创建，否则更新
 * 更新必须带主键
 */
- (nonnull RACSignal *) saveDB:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.dbSync saveOne:[self mergeSelfAndParameters:param]] subscribeNext:^(NSDictionary * x) {
        @strongify(self);
        NSError * error = nil;
        [self transformerProxyOfReponse:x error:&error];
        if (!error) {
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

/** DELETE */
- (nonnull RACSignal *) destroyDB:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    
    return subject;
}

@end
