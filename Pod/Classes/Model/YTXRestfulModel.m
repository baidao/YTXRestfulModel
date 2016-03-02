//
//  YTXModel.m
//  YTXRestfulModel
//
//  Created by cao jun on 16/01/25.
//  Copyright © 2015 Elephants Financial Service. All rights reserved.
//

#import "YTXRestfulModel.h"

#import "NSValue+YTXRestfulModelFMDBSync.h"

#import <Mantle/MTLEXTRuntimeExtensions.h>

#import <objc/runtime.h>


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
/** GET */
- (nullable instancetype) fetchStorageSync:(nullable NSDictionary *) param
{
    return [self fetchStorageSyncWithKey:[self storageKeyWithParam:param] param:param];
}

/** POST / PUT */
- (nonnull instancetype) saveStorageSync:(nullable NSDictionary *) param
{
    return [self saveStorageSyncWithKey:[self storageKeyWithParam:param] param:param];
}

/** DELETE */
- (void) destroyStorageSync:(nullable NSDictionary *) param
{
    return [self destroyStorageSyncWithKey:[self storageKeyWithParam:param] param:param];
}

/** GET */
- (nullable instancetype) fetchStorageSyncWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *) param
{
    NSDictionary * dict = [self.storageSync fetchStorageSyncWithKey:storage param:param];
    if (dict) {
        NSError * error;
        [self transformerProxyOfReponse:dict error:&error];
        if (!error) {
            return self;
        }

    }
    return nil;
}

/** POST / PUT */
- (nonnull instancetype) saveStorageSyncWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *) param
{
    [self.storageSync saveStorageSyncWithKey:storage withObject:[self mergeSelfAndParameters:param] param:param];
    return self;
}

/** DELETE */
- (void) destroyStorageSyncWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *) param
{
    [self.storageSync destroyStorageSyncWithKey:storage param:param];
}

- (nonnull RACSignal *) fetchStorage:(nullable NSDictionary *)param
{
    return [self fetchStorageWithKey:[self storageKeyWithParam:param] param:param];
}

- (nonnull RACSignal *) saveStorage:(nullable NSDictionary *)param
{
    return [self saveStorageWithKey:[self storageKeyWithParam:param] param:param];
}

/** DELETE */
- (nonnull RACSignal *) destroyStorage:(nullable NSDictionary *)param
{
    return [self destroyStorageWithKey:[self storageKeyWithParam:param] param:param];
}

- (nonnull RACSignal *)fetchStorageWithKey:(NSString *)storage param:(NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.storageSync fetchStorageWithKey:storage param:param] subscribeNext:^(NSDictionary * x) {
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

- (nonnull RACSignal *)saveStorageWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *)param
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

- (nonnull RACSignal *)destroyStorageWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *)param
{
    return [self.storageSync destroyStorageWithKey:storage param:param];
}

- (nonnull NSString *) storageKeyWithParam:(nullable NSDictionary *) param
{
    NSDictionary * dict = [self mergeSelfAndParameters:param];
    id primaryKeyValue = dict[[[self class] syncPrimaryKey]];
    
    NSAssert(primaryKeyValue != nil, @"Stroage必须找到主键的值");
    
    return [NSString stringWithFormat:@"EFSModel+%@+%@", NSStringFromClass([self class]), [primaryKeyValue description]];
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

+ (nonnull NSString *) _tableKeyPathsCachedKey
{
    return [NSString stringWithFormat:@"YTX.%@", NSStringFromClass([self class])];
}

#pragma mark DB
+ (nullable NSDictionary<NSString *, NSValue *> *) tableKeyPathsByPropertyKey
{
    NSDictionary<NSString *, NSValue *> * cachedKeys = objc_getAssociatedObject(self, [[self _tableKeyPathsCachedKey] UTF8String]);
    if (cachedKeys != nil) return cachedKeys;
    
    NSMutableDictionary<NSString *, NSValue *> * properties =  [NSMutableDictionary dictionary];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    
    NSDictionary<NSString *, NSArray<NSString * > * > * cTypeMap = [YTXRestfulModelFMDBSync mapOfCTypeToSqliteType];
    
    [[self class] performSelector:NSSelectorFromString(@"enumeratePropertiesUsingBlock:") withObject:^(objc_property_t property, BOOL *stop) {
        mtl_propertyAttributes *attributes = mtl_copyPropertyAttributes(property);
        char *propertyType = property_copyAttributeValue(property, "T");
        @onExit {
            free(attributes);
            free(propertyType);
        };
        
        if (attributes->readonly && attributes->ivar == NULL) return;
        
        NSString *modelProperyName = [NSString stringWithUTF8String:property_getName(property)];
        
        if ([modelProperyName isEqualToString:@"dbSync"] || [modelProperyName isEqualToString:@"remoteSync"] || [modelProperyName isEqualToString:@"storageSync"]) {
            return;
        }
        
        NSString *columnName = [self JSONKeyPathsByPropertyKey][modelProperyName] ? : modelProperyName;
        
        const char * propertyClassName = [[NSValue formateObjectType:propertyType] UTF8String];
        
        BOOL isPrimaryKey = [modelProperyName isEqualToString:[self primaryKey]];
        
        struct YTXRestfulModelDBSerializingStruct dataStruct = {
            propertyClassName,
            [columnName UTF8String],
            [modelProperyName UTF8String],
            isPrimaryKey,
            NO,
            nil,
            NO,
            nil
        };
        
        if (isPrimaryKey){
             NSArray<NSString * > *  sqliteTypeArr = cTypeMap[ [NSString stringWithUTF8String:propertyClassName] ];
            if (sqliteTypeArr != nil && ( [sqliteTypeArr[1] isEqualToString:@"INTEGER"] || [sqliteTypeArr[0] isEqualToString:@"NSNumber"] ) ){
                dataStruct.autoincrement = YES;
            }
        }
        
        
        [properties setObject:[NSValue value:&dataStruct withObjCType:@encode(struct YTXRestfulModelDBSerializingStruct)] forKey:columnName];
    }];
#pragma clang diagnostic pop
    
    
    // It doesn't really matter if we replace another thread's work, since we do
    // it atomically and the result should be the same.
    objc_setAssociatedObject(self, [[self _tableKeyPathsCachedKey] UTF8String], properties, OBJC_ASSOCIATION_COPY);
    
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
- (nonnull instancetype) fetchDBSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error
{
    NSError * currentError;
    
    NSDictionary * x = [self.dbSync fetchOneSync:[self mergeSelfAndParameters:param] error:&currentError];
    
    if (x && currentError == nil ) {
        [self transformerProxyOfReponse:x error:&currentError];
    }
    
    if (error){
        *error = currentError;
    }
    
    return self;
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
- (nonnull instancetype) saveDBSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error
{
    NSError * currentError;
    
    NSDictionary * x = [self.dbSync saveOneSync:[self mergeSelfAndParameters:param] error:&currentError];
    
    if (x && currentError == nil ) {
        [self transformerProxyOfReponse:x error:&currentError];
    }
    
    if (error){
        *error = currentError;
    }
    
    return self;
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
    [[self.dbSync saveOne:[self mergeSelfAndParameters:[self mergeSelfAndParameters:param]]] subscribeNext:^(NSDictionary * x) {
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
- (BOOL) destroyDBSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error
{
    NSError * currentError;
    
    BOOL x = [self.dbSync destroyOneSync:[self mergeSelfAndParameters:param] error:&currentError];
    
    if (error){
        *error = currentError;
    }
    
    return x;
}

/** DELETE */
- (nonnull RACSignal *) destroyDB:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    
    [[self.dbSync destroyOne:[self mergeSelfAndParameters:param]] subscribeNext:^(id x) {
        [subject sendNext:x];
        [subject sendCompleted];
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    
    return subject;
}

/** GET Foreign Models with primary key */
- (nonnull NSArray<NSDictionary *> *) fetchDBForeignSyncWithModelClass:(nonnull Class<YTXRestfulModelDBSerializing>)modelClass error:(NSError * _Nullable * _Nullable) error param:(nullable NSDictionary *)param
{
    NSDictionary * dict = [self mergeSelfAndParameters:param];
    
    id primaryKeyValue = dict[[[self class] syncPrimaryKey]];
    
    NSAssert(primaryKeyValue != nil, @"主键的值不能为空");
    
    return [self.dbSync fetchForeignSyncWithModelClass:modelClass primaryKeyValue:primaryKeyValue error:error param:dict];
}

/** GET Foreign Models with primary key */
- (nonnull RACSignal *) fetchDBForeignWithModelClass:(nonnull Class<YTXRestfulModelDBSerializing>)modelClass param:(nullable NSDictionary *)param
{
    NSDictionary * dict = [self mergeSelfAndParameters:param];
    
    id primaryKeyValue = dict[[[self class] syncPrimaryKey]];
    
    NSAssert(primaryKeyValue != nil, @"主键的值不能为空");
    
    return [self.dbSync fetchForeignWithModelClass:modelClass primaryKeyValue:primaryKeyValue param:dict];
}

@end
