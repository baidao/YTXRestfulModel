//
//  YTXRestfulModelDBProtocol.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/19.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    YTXRestfulModelDBErrorCodeNotFound = 0,
    YTXRestfulModelDBErrorCodeNotColumns = 1,
    YTXRestfulModelDBErrorCodeUnkonw = 9999
} YTXRestfulModelDBErrorCode;

typedef enum : NSUInteger {
    //升序
    YTXRestfulModelDBSortByDESC,
    //降序
    YTXRestfulModelDBSortByASC
} YTXRestfulModelDBSortBy;

@interface YTXRestfulModelDBSerializingModel : NSObject

/** 可以是CType @"d"这种*/
@property (nonatomic, nonnull, copy) NSString * objectClass;

/** 表名 */
@property (nonatomic, nonnull, copy) NSString *  columnName;

/** Model原始的属性名字 */
@property (nonatomic, nonnull, copy) NSString *  modelName;

@property (nonatomic, assign) BOOL isPrimaryKey;

@property (nonatomic, assign) BOOL autoincrement;

@property (nonatomic, assign) BOOL unique;

@property (nonatomic, nonnull, copy) NSString * defaultValue;

/** 外键类名 可以使用fetchForeignWithName */
@property (nonatomic, nonnull, copy) NSString * foreignClassName;

@end

@protocol YTXRestfulModelDBProtocol;

@protocol YTXRestfulModelDBSerializing <NSObject>

/** NSDictionary<ColumnName(lowerCase), NSValue(YTXRestfulModelDBSerializingStruct)> */
+ (nullable NSMutableDictionary<NSString *, YTXRestfulModelDBSerializingModel *> *) tableKeyPathsByPropertyKey;

+ (nullable NSNumber *) currentMigrationVersion;

+ (BOOL) autoAlterTable;

+ (BOOL) autoCreateTable;

+ (BOOL) isPrimaryKeyAutoincrement;

+ (void) migrationsMethodWithSync:(nonnull id<YTXRestfulModelDBProtocol>)sync;

@optional
/** 在这个方法内migrateWithVersion*/
+ (void) dbWillMigrateWithSync:(nonnull id<YTXRestfulModelDBProtocol>)sync;

+ (void) dbDidMigrateWithSync:(nonnull id<YTXRestfulModelDBProtocol>)sync;

@end


typedef void (^YTXRestfulModelMigrationBlock)(_Nonnull id, NSError * _Nullable * _Nullable);

@interface YTXRestfulModelDBMigrationEntity : NSObject

@property (nonnull, nonatomic, copy) YTXRestfulModelMigrationBlock block;
@property (nonnull, nonatomic, copy) NSNumber *version;

@end

@protocol YTXRestfulModelDBProtocol <NSObject>

@required

@property (nonatomic, assign, readonly, nonnull) Class<YTXRestfulModelDBSerializing> modelClass;

@property (nonnull, nonatomic, copy, readonly) NSString * primaryKey;

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

/** GET Foreign Models with primary key */
- (nonnull NSArray<NSDictionary *> *) fetchForeignSyncWithModelClass:(nonnull Class<YTXRestfulModelDBSerializing>)modelClass primaryKeyValue:(nonnull id) value error:(NSError * _Nullable * _Nullable) error param:(nullable NSDictionary *)param;

/** ORDER BY primaryKey ASC*/
- (nonnull NSArray<NSDictionary *> *) fetchAllSyncWithError:(NSError * _Nullable * _Nullable) error;


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

/** 大于currentMigrationVersion将会依次执行，数字越大越后执行*/
- (void) migrate:(nonnull YTXRestfulModelDBMigrationEntity *) entity;

- (BOOL) createColumnWithDB:(nonnull id)db structSync:(nonnull YTXRestfulModelDBSerializingModel *)sstruct error:(NSError * _Nullable * _Nullable)error;

@optional

- (BOOL) renameColumnWithDB:(nonnull id)db originName:(nonnull NSString *)originName newName:(nonnull NSString *)newName error:(NSError * _Nullable * _Nullable)error;

- (BOOL) dropColumnWithDB:(nonnull id)db structSync:(nonnull YTXRestfulModelDBSerializingModel *)sstruct error:(NSError * _Nullable * _Nullable)error;

- (BOOL) changeCollumnDB:(nonnull id)db oldStructSync:(nonnull YTXRestfulModelDBSerializingModel *) oldStruct toNewStruct:(nonnull YTXRestfulModelDBSerializingModel *) newStruct error:(NSError * _Nullable * _Nullable)error;

@end
