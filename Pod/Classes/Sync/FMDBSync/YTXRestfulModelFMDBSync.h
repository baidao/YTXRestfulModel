//
//  YTXRestfulModelFMDBSync.h
//  Pods
//
//  Created by CaoJun on 16/2/22.
//
//

#import "YTXRestfulModelDBProtocol.h"

#import <Foundation/Foundation.h>

@class FMDatabaseQueue;
@class FMDatabase;

@interface YTXRestfulModelFMDBSync : NSObject <YTXRestfulModelDBProtocol>

@property (nonatomic, strong, readonly, nonnull) FMDatabaseQueue * fmdbQueue;

@property (nonatomic, assign, readonly, nonnull) Class<YTXRestfulModelDBSerializing> modelClass;

@property (nonnull, nonatomic, copy, readonly) NSString * primaryKey;


#pragma mark db operation

+ (nonnull instancetype) syncWithModelOfClass:(nonnull Class<YTXRestfulModelDBSerializing>) modelClass primaryKey:(nonnull NSString *) key;

+ (nonnull NSString *) path;

- (nonnull NSString *) tableName;

- (nonnull instancetype) initWithModelOfClass:(nonnull Class<YTXRestfulModelDBSerializing>) modelClass primaryKey:(nonnull NSString *) key;
- (nonnull NSError *) createTable;

- (nonnull NSError *) dropTable;

//操作将会保证在migration之后进行

/** GET Model with primary key */
- (nullable NSDictionary *) fetchOneSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error;

/** POST / PUT Model with primary key */
- (nullable NSDictionary *) saveOneSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error;

/** DELETE Model with primary key */
- (BOOL) destroyOneSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error;

/** GET */
- (nullable NSDictionary *) fetchTopOneSyncWithError:(NSError * _Nullable * _Nullable) error;

/** GET */
- (nullable NSDictionary *) fetchLatestOneSyncWithError:(NSError * _Nullable * _Nullable) error;

/** DELETE All Model with primary key */
- (BOOL) destroyAllSyncWithError:(NSError * _Nullable * _Nullable) error;

/** ORDER BY primaryKey ASC*/
- (nonnull NSArray<NSDictionary *> *) fetchAllSyncWithError:(NSError * _Nullable * _Nullable) error;

/** GET Foreign Models with primary key */
- (nonnull NSArray<NSDictionary *> *) fetchForeignSyncWithModelClass:(nonnull Class<YTXRestfulModelDBSerializing>)modelClass primaryKeyValue:(nonnull id) value error:(NSError * _Nullable * _Nullable) error param:(nullable NSDictionary *)param;

- (nonnull NSArray<NSDictionary *> *) fetchAllSyncWithError:(NSError * _Nullable * _Nullable)error soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSArray<NSString *> * )columnNames;

- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error start:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSArray<NSString *> * )columnNames;

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMet:(nonnull NSArray<NSString *> * )conditions;

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy conditions:(nonnull NSArray<NSString *> * )conditions;

/**
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditions:(nonnull NSArray<NSString *> * )conditions;

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMet:(nonnull NSArray<NSString *> * )conditions;

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy  conditions:(nonnull NSArray<NSString *> * )conditions;

/**
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditions:(nonnull NSArray<NSString *> * )conditions;

//Migration

/** 数字越大越后面执行*/

@property (nonatomic, strong, readonly, nonnull) NSMutableArray<YTXRestfulModelDBMigrationEntity *> * migrationBlocks;

/** 大于currentMigrationVersion将会依次执行*/
- (void) migrate:(nonnull YTXRestfulModelDBMigrationEntity *) entity;

- (BOOL) createColumnWithDB:(nonnull id)db structSync:(nonnull YTXRestfulModelDBSerializingModel *)sstruct error:(NSError * _Nullable * _Nullable)error;

// Tools
+ (nonnull NSDictionary<NSString *, NSArray<NSString * > * > *) mapOfCTypeToSqliteType;
+ (nonnull NSArray *) arrayOfMappedArgsWithOriginArray:(nonnull NSArray *)originArray propertiesMap:(nonnull NSDictionary *)propertiesMap;

+ (nonnull NSString * ) sqliteStringWhere:(nonnull NSString *) key equal:(nonnull id) value;
+ (nonnull NSString * ) sqliteStringWhere:(nonnull NSString *) key greatThan:(nonnull id) value;
+ (nonnull NSString * ) sqliteStringWhere:(nonnull NSString *) key greatThanOrEqaul:(nonnull id) value;
+ (nonnull NSString * ) sqliteStringWhere:(nonnull NSString *) key lessThan:(nonnull id) value;
+ (nonnull NSString * ) sqliteStringWhere:(nonnull NSString *) key lessThanOrEqual:(nonnull id) value;
+ (nonnull NSString * ) sqliteStringWhere:(nonnull NSString *) key like:(nonnull id) value;

@end
