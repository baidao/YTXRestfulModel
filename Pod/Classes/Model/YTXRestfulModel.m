//
//  YTXModel.m
//  YTXRestfulModel
//
//  Created by cao jun on 16/01/25.
//  Copyright © 2015 Elephants Financial Service. All rights reserved.
//

#import "YTXRestfulModel.h"

#ifdef YTX_USERDEFAULTSTORAGESYNC_EXISTS
#import "YTXRestfulModelUserDefaultStorageSync.h"
#endif

#ifdef YTX_AFNETWORKINGREMOTESYNC_EXISTS
#import "AFNetworkingRemoteSync.h"
#endif

#ifdef YTX_YTXREQUESTREMOTESYNC_EXISTS
#import "YTXRestfulModelYTXRequestRemoteSync.h"
#endif

#ifdef YTX_FMDBSYNC_EXISTS
#import "YTXRestfulModelFMDBSync.h"
#import "NSValue+YTXRestfulModelFMDBSync.h"
#endif

#import <Mantle/MTLEXTRuntimeExtensions.h>

#import <objc/runtime.h>

@implementation YTXRestfulModelDBSerializingModel

@end

@implementation YTXRestfulModelDBMigrationEntity

@end

@implementation YTXRestfulModel

- (instancetype)init
{
    if(self = [super init])
    {
#ifdef YTX_USERDEFAULTSTORAGESYNC_EXISTS
        self.storageSync = [YTXRestfulModelUserDefaultStorageSync new];
#endif

#ifdef YTX_AFNETWORKINGREMOTESYNC_EXISTS
        self.remoteSync = [AFNetworkingRemoteSync syncWithPrimaryKey: [[self class] syncPrimaryKey]];
#endif

#ifdef YTX_YTXREQUESTREMOTESYNC_EXISTS
        self.remoteSync = [YTXRestfulModelYTXRequestRemoteSync syncWithPrimaryKey: [[self class] syncPrimaryKey]];
#endif

#ifdef YTX_FMDBSYNC_EXISTS
        self.dbSync = [YTXRestfulModelFMDBSync syncWithModelOfClass:[self class] primaryKey: [[self class] syncPrimaryKey]];
#endif
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


//Mantle的model属性和目标源属性的映射表。DBSync也会使用。
+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{};
}

#pragma mark EFSModelProtocol

- (nonnull instancetype) mergeWithAnother:(_Nonnull id) model
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

//主键名。在Model上的名字
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
        [self transformerProxyOfResponse:dict error:&error];
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


- (nonnull NSString *) storageKeyWithParam:(nullable NSDictionary *) param
{
    NSDictionary * dict = [self mergeSelfAndParameters:param];
    id primaryKeyValue = dict[[[self class] syncPrimaryKey]];

    NSAssert(primaryKeyValue != nil, @"Stroage必须找到主键的值");

    return [NSString stringWithFormat:@"EFSModel+%@+%@", NSStringFromClass([self class]), [primaryKeyValue description]];
}

#pragma mark remote
/** 在拉到数据转mantle的时候用 */
- (nonnull instancetype) transformerProxyOfResponse:(nonnull id) response error:(NSError * _Nullable * _Nullable) error
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

- (nonnull NSDictionary *)mergeSelfPrimaryKeyAndParameters:(nullable NSDictionary *)param
{
    NSDictionary * mapParam = [self mapParameters:param];
    
    NSDictionary *dic = [MTLJSONAdapter JSONDictionaryFromModel:self];
    
    NSMutableDictionary *retDic = [NSMutableDictionary dictionary];
    
    if (dic[[[self class] syncPrimaryKey]] != nil) {
        retDic[[[self class] syncPrimaryKey]] = dic[[[self class] syncPrimaryKey]];
    }
    
    for (NSString *key in mapParam) {
        retDic[key] = mapParam[key];
    }
    return retDic;
}

- (nonnull id) transformerProxyOfForeign:(nonnull Class)modelClass response:(nonnull id) response error:(NSError * _Nullable * _Nullable) error;
{
    return [MTLJSONAdapter modelsOfClass:modelClass fromJSONArray:response error:error];
}

- (void) fetchRemoteForeignWithName:(nonnull NSString *)name modelClass:(nonnull Class)modelClass param:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed
{
    __weak __typeof(&*self)weakSelf = self;
    [self.remoteSync fetchRemoteForeignWithName:name param:[self mergeSelfAndParameters:param] success:^(id  _Nullable response) {
        NSError * error = nil;
        id model = [weakSelf transformerProxyOfForeign:modelClass response:response error:&error];
        if (!error) {
            success(model);
        }
        else {
            failed(error);
        }
    } failed:failed];
}

- (void) fetchRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed
{
    __weak __typeof(&*self)weakSelf = self;
    [self.remoteSync fetchRemote:[self mergeSelfPrimaryKeyAndParameters:param] success:^(id  _Nullable response) {
        NSError * error = nil;
        id model = [weakSelf transformerProxyOfResponse:response error:&error];
        if (!error) {
            success(model);
        }
        else {
            failed(error);
        }
    } failed:failed];
}

- (void) saveRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed
{
    __weak __typeof(&*self)weakSelf = self;
    if ([self isNew]) {
        [self.remoteSync createRemote:[self mergeSelfAndParameters:param] success:^(id  _Nullable response) {
            NSError * error = nil;
            id model = [weakSelf transformerProxyOfResponse:response error:&error];
            if (!error) {
                success(model);
            }
            else {
                failed(error);
            }
        } failed:failed];
    } else {
        [self.remoteSync updateRemote:[self mergeSelfAndParameters:param] success:^(id  _Nullable response) {
            NSError * error = nil;
            id model = [weakSelf transformerProxyOfResponse:response error:&error];
            if (!error) {
                success(model);
            }
            else {
                failed(error);
            }
        } failed:failed];
    }
}

- (void) destroyRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed
{
    __weak __typeof(&*self)weakSelf = self;
    [self.remoteSync destroyRemote:[self mergeSelfAndParameters:param] success:^(id  _Nullable response) {
        NSError * error = nil;
        id model = [weakSelf transformerProxyOfResponse:response error:&error];
        if (!error) {
            success(model);
        }
        else {
            failed(error);
        }
    } failed:failed];
}

+ (nonnull NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, YTXRestfulModelDBSerializingModel *> *> *) _tableKeyPathsByPropertyKeyMap
{
    static NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, YTXRestfulModelDBSerializingModel *> *> * map;

    if (map == nil) {
        map = [NSMutableDictionary dictionary];
    }

    return map;
}

+ (nonnull NSString *) _tableKeyPathsCachedKey
{
    return [NSString stringWithFormat:@"YTX.%@", NSStringFromClass([self class])];
}

#pragma mark DB
+ (BOOL) isPrimaryKeyAutoincrement
{
    return YES;
}

+ (nullable NSMutableDictionary<NSString *, YTXRestfulModelDBSerializingModel *> *) tableKeyPathsByPropertyKey
{
    NSMutableDictionary<NSString *, YTXRestfulModelDBSerializingModel *> * cachedKeys = [self _tableKeyPathsByPropertyKeyMap][[self _tableKeyPathsCachedKey]];

    if (cachedKeys != nil) {
        return cachedKeys;
    }

    __block NSMutableDictionary<NSString *, YTXRestfulModelDBSerializingModel *> * properties =  [NSMutableDictionary dictionary];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

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

        NSString * propertyClassName = [[self class] formateObjectType:propertyType];

        BOOL isPrimaryKey = [modelProperyName isEqualToString:[self primaryKey]];

        BOOL isPrimaryKeyAutoincrement = NO;
        if (isPrimaryKey) {
            isPrimaryKeyAutoincrement = [self isPrimaryKeyAutoincrement];
        }

        YTXRestfulModelDBSerializingModel * dbsm = [YTXRestfulModelDBSerializingModel new];
        dbsm.objectClass = propertyClassName;
        dbsm.columnName = columnName;
        dbsm.modelName = modelProperyName;
        dbsm.isPrimaryKey = isPrimaryKey;
        dbsm.autoincrement = isPrimaryKeyAutoincrement;
        dbsm.unique = NO;

        [properties setObject:dbsm forKey:columnName];
    }];
#pragma clang diagnostic pop

    [self _tableKeyPathsByPropertyKeyMap][[self _tableKeyPathsCachedKey]] = properties;

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

+ (void) migrationsMethodWithSync:(nonnull id<YTXRestfulModelDBProtocol>)sync;
{

}

+ (void)dbWillMigrateWithSync:(nonnull id<YTXRestfulModelDBProtocol>)sync
{

}

+ (void)dbDidMigrateWithSync:(nonnull id<YTXRestfulModelDBProtocol>)sync
{

}

/** GET */
- (nonnull instancetype) fetchDBSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error
{
    NSDictionary * x = [self.dbSync fetchOneSync:[self mergeSelfAndParameters:param] error:error];

    if (x && *error == nil ) {
        [self transformerProxyOfResponse:x error:error];
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
        [self transformerProxyOfResponse:x error:&error];
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
    NSDictionary * x = [self.dbSync saveOneSync:[self mergeSelfAndParameters:param] error:error];

    if (x && *error == nil ) {
        [self transformerProxyOfResponse:x error:error];
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
        [self transformerProxyOfResponse:x error:&error];
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
    return [self.dbSync destroyOneSync:[self mergeSelfAndParameters:param] error:error];
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
- (nonnull NSArray *) fetchDBForeignSyncWithModelClass:(nonnull Class<YTXRestfulModelDBSerializing>)modelClass error:(NSError * _Nullable * _Nullable) error param:(nullable NSDictionary *)param
{
    NSDictionary * dict = [self mergeSelfAndParameters:param];

    id primaryKeyValue = dict[[[self class] syncPrimaryKey]];

    NSAssert(primaryKeyValue != nil, @"主键的值不能为空");

    NSArray<NSDictionary *> * x = [self.dbSync fetchForeignSyncWithModelClass:modelClass primaryKeyValue:primaryKeyValue error:error param:dict];

    return [self transformerProxyOfForeign:modelClass response:x error:error];
}

/** GET Foreign Models with primary key */
- (nonnull RACSignal *) fetchDBForeignWithModelClass:(nonnull Class<YTXRestfulModelDBSerializing>)modelClass param:(nullable NSDictionary *)param
{
    NSDictionary * dict = [self mergeSelfAndParameters:param];

    id primaryKeyValue = dict[[[self class] syncPrimaryKey]];

    NSAssert(primaryKeyValue != nil, @"主键的值不能为空");

    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[self.dbSync fetchForeignWithModelClass:modelClass primaryKeyValue:primaryKeyValue param:dict] subscribeNext:^(id x) {
        @strongify(self);
        NSError * error = nil;
        [self transformerProxyOfResponse:x error:&error];
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

#pragma mark - tools
+ (nonnull NSString*) formateObjectType:(const char* _Nonnull )objcType
{
    if (!objcType || !strlen(objcType)) return nil;
    NSString* type = [NSString stringWithCString:objcType encoding:NSUTF8StringEncoding];

    switch (objcType[0]) {
        case '@':
            type = [type substringWithRange:NSMakeRange(2, strlen(objcType)-3)];
            break;
        case '{':
            type = [type substringWithRange:NSMakeRange(1, strchr(objcType, '=')-objcType-1)];
            break;
        default:
            break;
    }
    return type;
}


- (id<YTXRestfulModelStorageProtocol>)storageSync
{
    YTXAssertSyncExists(_storageSync, @"StorageSync");
    return _storageSync;
}

-(id<YTXRestfulModelDBProtocol>)dbSync
{
    YTXAssertSyncExists(_dbSync, @"DBSync");
    return _dbSync;
}

-(id<YTXRestfulModelRemoteProtocol>)remoteSync
{
    YTXAssertSyncExists(_remoteSync, @"RemoteSync");
    return _remoteSync;
}

@end
