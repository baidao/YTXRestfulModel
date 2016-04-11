//
//  YTXRestfulCollection.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//


#import "YTXRestfulModelStorageProtocol.h"
#import "YTXRestfulModelRemoteProtocol.h"
#import "YTXRestfulModelDBProtocol.h"
#import "YTXRestfulModel.h"

#import <Foundation/Foundation.h>

@interface YTXRestfulCollection : NSObject

@property (nonnull, nonatomic, assign) Class<YTXRestfulModelProtocol, MTLJSONSerializing, YTXRestfulModelDBSerializing> modelClass;
@property (nonnull, nonatomic, strong, readonly) NSArray * models;

@property (nonnull, nonatomic, strong) id<YTXRestfulModelStorageProtocol> storageSync;
@property (nonnull, nonatomic, strong) id<YTXRestfulModelRemoteProtocol> remoteSync;
@property (nonnull, nonatomic, strong) id<YTXRestfulModelDBProtocol> dbSync;


- (nonnull instancetype) initWithModelClass:(nonnull Class<YTXRestfulModelProtocol, MTLJSONSerializing, YTXRestfulModelDBSerializing>)modelClass;

- (nonnull instancetype) initWithModelClass:(nonnull Class<YTXRestfulModelProtocol, MTLJSONSerializing, YTXRestfulModelDBSerializing>)modelClass userDefaultSuiteName:(nullable NSString *) suiteName;

#pragma mark storage
- (nonnull NSString *) storageKey;

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

#pragma mark remote
/* RACSignal return self **/
- (void) fetchRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed;

/* RACSignal return self **/
- (void) fetchRemoteThenAdd:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed;

#pragma mark db
- (nonnull instancetype) fetchDBSyncAllWithError:(NSError * _Nullable * _Nullable) error;
//
- (nonnull instancetype) fetchDBSyncAllWithError:(NSError * _Nullable * _Nullable)error soryBy:(YTXRestfulModelDBSortBy)sortBy orderByColumnNames:(nonnull NSArray<NSString *> * )columnNames;
- (nonnull instancetype) fetchDBSyncAllWithError:(NSError * _Nullable * _Nullable)error soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )columnName, ...;
//
- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error start:(NSUInteger)start count:(NSUInteger)count soryBy:(YTXRestfulModelDBSortBy)sortBy orderByColumnNames:(nonnull NSArray<NSString *> * )columnNames;
- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error start:(NSUInteger)start count:(NSUInteger)count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )columnName, ...;
//
- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMetConditions:(nonnull NSArray<NSString *> * )conditions;
- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMet:(nonnull NSString * )condition, ...;
//
- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy conditionsArray:(nonnull NSArray<NSString *> * )conditions;
- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy conditions:(nonnull NSString * )condition, ...;
//
- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditionsArray:(nonnull NSArray<NSString *> * )conditions;
- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditions:(nonnull NSString * )condition, ...;
//
- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMetConditionsArray:(nonnull NSArray<NSString *> * )conditions;
- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMet:(nonnull NSString * )condition, ...;
//
- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy  conditionsArray:(nonnull NSArray<NSString *> * )conditions;
- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy  conditions:(nonnull NSString * )condition, ...;
//
- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditionsArray:(nonnull NSArray<NSString *> * )conditions;
- (nonnull instancetype) fetchDBSyncMultipleWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditions:(nonnull NSString * )condition, ...;
//
- (BOOL) destroyDBSyncAllWithError:(NSError * _Nullable * _Nullable)error;

- (nonnull NSArray *) arrayWithArgs:(va_list) args firstArgument:(nullable id)firstArgument;

- (nonnull NSArray *) arrayOfMappedArgsWithOriginArray:(nonnull NSArray *)originArray;

#pragma mark - function

- (nullable NSArray< id<MTLJSONSerializing> > *) transformerProxyOfResponse:(nullable id) response error:(NSError * _Nullable * _Nullable) error;

/** 在拉到数据转mantle的时候用 */
- (nullable NSArray<NSDictionary *> *) transformerProxyOfModels:(nonnull NSArray< id<MTLJSONSerializing> > *) array;

/** 注入自己时使用 */
- (nonnull instancetype) removeAllModels;

- (nonnull instancetype) resetModels:(nonnull NSArray *) array;

- (nonnull instancetype) addModels:(nonnull NSArray *) array;

- (nonnull instancetype) insertFrontModels:(nonnull NSArray *) array;

- (nonnull instancetype) sortedArrayUsingComparator:(nonnull NSComparator)cmptr;

- (nullable NSArray *) arrayWithRange:(NSRange)range;

- (nullable YTXRestfulCollection *) collectionWithRange:(NSRange)range;

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
