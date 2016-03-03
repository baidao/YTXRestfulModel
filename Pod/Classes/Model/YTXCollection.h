//
//  YTXCollection.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import "YTXRestfulModelUserDefaultStorageSync.h"
#import "YTXRestfulModelYTXRequestRemoteSync.h"
#import "YTXRestfulModelFMDBSync.h"

#import "YTXRestfulModel.h"

#import <Foundation/Foundation.h>

@interface YTXCollection : NSObject

@property (nonnull, nonatomic, assign) Class<MTLJSONSerializing> modelClass;
@property (nonnull, nonatomic, strong, readonly) NSArray * models;

@property (nonnull, nonatomic, strong) id<YTXRestfulModelStorageProtocol> storageSync;
@property (nonnull, nonatomic, strong) id<YTXRestfulModelRemoteProtocol> remoteSync;
@property (nonnull, nonatomic, strong) id<YTXRestfulModelDBProtocol> dbSync;


- (nonnull instancetype) initWithModelClass:(nonnull Class<YTXRestfulModelProtocol, YTXRestfulModelDBSerializing, MTLJSONSerializing>)modelClass;

- (nonnull instancetype) initWithModelClass:(nonnull Class<YTXRestfulModelProtocol, YTXRestfulModelDBSerializing, MTLJSONSerializing>)modelClass userDefaultSuiteName:(nullable NSString *) suiteName;

#pragma mark storage
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

/** GET */
- (nonnull RACSignal *) fetchStorage:(nullable NSDictionary *)param;

/** POST / PUT */
- (nonnull RACSignal *) saveStorage:(nullable NSDictionary *)param;

/** DELETE */
- (nonnull RACSignal *) destroyStorage:(nullable NSDictionary *)param;

/** GET */
- (nonnull RACSignal *) fetchStorageWithKey:(nonnull NSString *)storageKey param:(nullable NSDictionary *)param;

/** POST / PUT */
- (nonnull RACSignal *) saveStorageWithKey:(nonnull NSString *)storageKey param:(nullable NSDictionary *)param;

/** DELETE */
- (nonnull RACSignal *) destroyStorageWithKey:(nonnull NSString *)storageKey param:(nullable NSDictionary *)param;

#pragma mark remote
/* RACSignal return Tuple( self, Arrary<Model> ) **/
- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param;

/* RACSignal return self **/
- (nonnull RACSignal *) fetchRemoteThenReset:(nullable NSDictionary *)param;

/* RACSignal return self **/
- (nonnull RACSignal *) fetchRemoteThenAdd:(nullable NSDictionary *)param;

#pragma mark db
- (nonnull instancetype) fetchDBSyncAllWithError:(NSError * _Nullable * _Nullable) error;

- (nonnull instancetype) fetchDBSyncAllWithError:(NSError * _Nullable * _Nullable)error soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )columnName, ...;

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error start:(NSUInteger)start count:(NSUInteger)count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )columnName, ...;

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMet:(nonnull NSString * )condition, ...;

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy conditions:(nonnull NSString * )condition, ...;

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditions:(nonnull NSString * )condition, ...;

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMet:(nonnull NSString * )condition, ...;

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy  conditions:(nonnull NSString * )condition, ...;

- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditions:(nonnull NSString * )condition, ...;

- (BOOL) destroyDBSyncAllWithError:(NSError * _Nullable * _Nullable)error;

/* RACSignal return self **/
- (nonnull RACSignal *) fetchDBAll;

- (nonnull RACSignal *) fetchDBAllSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )columnName, ...;

- (nonnull RACSignal *) fetchDBMultipleWith:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )columnName, ...;

- (nonnull RACSignal *) fetchDBMultipleWhereAllTheConditionsAreMet:(nonnull NSString * )condition, ...;

- (nonnull RACSignal *) fetchDBMultipleWhereAllTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy conditions:(nonnull NSString * )condition, ...;

- (nonnull RACSignal *) fetchDBMultipleWhereAllTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditions:(nonnull NSString * )condition, ...;

- (nonnull RACSignal *) fetchDBMultipleWherePartOfTheConditionsAreMet:(nonnull NSString * )condition, ...;

- (nonnull RACSignal *) fetchDBMultipleWherePartOfTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy conditions:(nonnull NSString * )condition, ...;

- (nonnull RACSignal *) fetchDBMultipleWherePartOfTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditions:(nonnull NSString * )condition, ...;

/* RACSignal return BOOL **/
- (nonnull RACSignal *) destroyDBAll;

- (nullable NSArray< id<MTLJSONSerializing> > *) transformerProxyOfReponse:(nullable NSArray<NSDictionary *> *) response error:(NSError * _Nullable * _Nullable) error;

/** 在拉到数据转mantle的时候用 */
- (nullable NSArray<NSDictionary *> *) transformerProxyOfModels:(nonnull NSArray< id<MTLJSONSerializing> > *) array;

/** 注入自己时使用 */
- (nonnull instancetype) removeAllModels;

- (nonnull instancetype) resetModels:(nonnull NSArray *) array;

- (nonnull instancetype) addModels:(nonnull NSArray *) array;

- (nonnull instancetype) insertFrontModels:(nonnull NSArray *) array;

- (nonnull instancetype) sortedArrayUsingComparator:(nonnull NSComparator)cmptr;

- (nullable NSArray *) arrayWithRange:(NSRange)range;

- (nullable YTXCollection *) collectionWithRange:(NSRange)range;

- (nullable YTXRestfulModel *) modelAtIndex:(NSInteger) index;

/** 主键可能是NSNumber或NSString，统一转成NSString来判断*/
- (nullable YTXRestfulModel *) modelWithPrimaryKey:(nonnull NSString *) primaryKey;

- (BOOL) addModel:(nonnull YTXRestfulModel *) model;

- (BOOL) insertFrontModel:(nonnull YTXRestfulModel *) model;

/** 插入到index之后*/
- (BOOL) insertModel:(nonnull YTXRestfulModel *) model afterIndex:(NSInteger) index;

/** 插入到index之前*/
- (BOOL) insertModel:(nonnull YTXRestfulModel *) model beforeIndex:(NSInteger) index;

- (BOOL) removeModelAtIndex:(NSInteger) index;

/** 主键可能是NSNumber或NSString，统一转成NSString来判断*/
- (BOOL) removeModelWithPrimaryKey:(nonnull NSString *) primaryKey;

- (BOOL) removeModelWithModel:(nonnull YTXRestfulModel *) model;

/** 逆序输出Collection*/
- (void) reverseModels;

@end
