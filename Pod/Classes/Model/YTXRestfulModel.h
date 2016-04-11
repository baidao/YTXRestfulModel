//
//  YTXModel.h
//  YTXRestfulModel
//
//  Created by cao jun on 16/01/25.
//  Copyright © 2015 Elephants Financial Service. All rights reserved.
//

#import "YTXRestfulModelProtocol.h"
#import "YTXRestfulModelStorageProtocol.h"
#import "YTXRestfulModelRemoteProtocol.h"
#import "YTXRestfulModelDBProtocol.h"
#import <Mantle/Mantle.h>
#import <Foundation/Foundation.h>

#define YTXAssertSyncExists(__SYNC__, __DESC__) \
NSAssert(__SYNC__ != nil, @"应该在pod中安装%@ 像这样：%@", __DESC__, @"pod 'YTXRestfulModel', :path => '../', :subspecs => [ 'FMDBSync', 'UserDefaultStorageSync']");\

@interface YTXRestfulModel : MTLModel <YTXRestfulModelProtocol, MTLJSONSerializing, YTXRestfulModelDBSerializing>

@property (nonnull, nonatomic, strong) id<YTXRestfulModelStorageProtocol> storageSync;
@property (nonnull, nonatomic, strong) id<YTXRestfulModelRemoteProtocol> remoteSync;
@property (nonnull, nonatomic, strong) id<YTXRestfulModelDBProtocol> dbSync;


- (nonnull instancetype) mergeWithAnother:(_Nonnull id) model;

/** 要用keyId判断 */
- (BOOL) isNew;

/** 需要告诉我主键是什么，子类也应当实现 */
+ (nonnull NSString *) primaryKey;

+ (nonnull NSString *)syncPrimaryKey;

/** 方便的直接取主键的值*/
- (nullable id) primaryValue;

/** 在拉到数据转mantle的时候用 */
- (nonnull instancetype) transformerProxyOfResponse:(nonnull id) response error:(NSError * _Nullable * _Nullable) error;

/** 在拉到数据转外部mantle对象的时候用 */
- (nonnull id) transformerProxyOfForeign:(nonnull Class)modelClass response:(nonnull id) response error:(NSError * _Nullable * _Nullable) error;

/** 将自身转化为Dictionary，然后对传入参数进行和自身属性的融合。自身的属性优先级最高，不可被传入参数修改。 */
- (nonnull NSDictionary *)mergeSelfAndParameters:(nullable NSDictionary *)param;

- (nonnull NSString *) storageKeyWithParam:(nullable NSDictionary *) param;

/** GET */
- (nullable instancetype) fetchStorageSync:(nullable NSDictionary *) param;

/** POST / PUT */
- (nonnull instancetype) saveStorageSync:(nullable NSDictionary *) param;

/** DELETE */
- (void) destroyStorageSync:(nullable NSDictionary *) param;

/** GET */
- (nullable instancetype) fetchStorageSyncWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *) param;

/** POST / PUT */
- (nonnull instancetype) saveStorageSyncWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *) param;

/** DELETE */
- (void) destroyStorageSyncWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *) param;


/** :id/comment 这种形式的时候使用GET; modelClass is MTLModel*/
- (void) fetchRemoteForeignWithName:(nonnull NSString *)name modelClass:(nonnull Class)modelClass param:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed;
/** GET */
- (void) fetchRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed;
/** POST / PUT */
- (void) saveRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed;
/** DELETE */
- (void) destroyRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed;

/** 主键是否自增，默认为YES */
+ (BOOL) isPrimaryKeyAutoincrement;

/** 若主键是NSNumber 将会默认设置为自增的 */
+ (nullable NSMutableDictionary<NSString *, YTXRestfulModelDBSerializingModel *> *) tableKeyPathsByPropertyKey;

+ (nullable NSNumber *) currentMigrationVersion;

+ (void) migrationsMethodWithSync:(nonnull id<YTXRestfulModelDBProtocol>)sync;

/** GET */
- (nonnull instancetype) fetchDBSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error;

/**
  * POST / PUT
  * 数据库不存在时创建，否则更新
  * 更新必须带主键
  */
- (nonnull instancetype) saveDBSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error;

/** DELETE */
- (BOOL) destroyDBSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error;

/** GET Foreign Models with primary key */
- (nonnull NSArray *) fetchDBForeignSyncWithModelClass:(nonnull Class<YTXRestfulModelDBSerializing>)modelClass error:(NSError * _Nullable * _Nullable) error param:(nullable NSDictionary *)param;

@end
