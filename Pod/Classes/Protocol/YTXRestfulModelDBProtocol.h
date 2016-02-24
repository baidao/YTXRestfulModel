//
//  YTXRestfulModelDBProtocol.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/19.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>
#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    YTXRestfulModelDBErrorCodeNotFound = -100
} YTXRestfulModelDBErrorCode;

typedef enum : NSUInteger {
    //升序
    YTXRestfulModelDBSortByDESC,
    //降序
    YTXRestfulModelDBSortByASC
} YTXRestfulModelDBSortBy;

struct YTXRestfulModelDBSerializingStruct {
    /** 数据类型 */
    _Nonnull Class objectClass;
    /** 表里的属性名字 如果columnName没有将会使用modelName */
    char * _Nullable  columnName;
    /** Model的属性名字 */
    char * _Nonnull  modelName;
    
    bool isPrimaryKey;
    
    bool isForeignKey;
    
    bool autoincrement;
    
    char * _Nullable defaultValue;
    
};

@protocol YTXRestfulModelDBSerializing <NSObject>

/** NSDictionary<ColumnName, NSValue(YTXRestfulModelDBSerializingStruct)> */
+ (nullable NSDictionary<NSString *, NSValue *> *) tableKeyPathsByPropertyKey;

+ (nullable NSNumber *) currentMigrationVersion;

@optional
/** 在这个方法内migrateWithVersion*/
+ (void) dbWillMigrate;

+ (void) dbDidMigrate;

@end

@protocol YTXRestfulModelDBProtocol;

typedef RACSignal * _Nonnull (^YTXRestfulModelMigrationBlock)(_Nonnull id<YTXRestfulModelDBProtocol>);

@interface YTXRestfulModelDBMigrationEntity : NSObject

@property (nonnull, nonatomic, copy) YTXRestfulModelMigrationBlock block;
@property (nonnull, nonatomic, copy) NSNumber *version;

@end

@protocol YTXRestfulModelDBProtocol <NSObject>

@required

@property (nonatomic, copy, readonly, nonnull) NSString * path;

@property (nonatomic, assign, readonly, nonnull) Class<YTXRestfulModelDBSerializing> modelClass;

@property (nonnull, nonatomic, copy, readonly) NSString * primaryKey;

+ (nonnull instancetype) syncWithModelOfClass:(nonnull Class<YTXRestfulModelDBSerializing>) modelClass primaryKey:(nonnull NSString *) key;

- (nonnull NSString *) tableName;

- (nonnull instancetype) initWithModelOfClass:(nonnull Class<YTXRestfulModelDBSerializing>) modelClass primaryKey:(nonnull NSString *) key;

- (nonnull RACSignal *) createTable;

- (nonnull RACSignal *) dropTable;


//操作将会保证在migration之后进行

/** GET Model with primary key */
- (nonnull RACSignal *) fetchOne:(nullable NSDictionary *)param;

/** POST Model with primary key */
- (nonnull RACSignal *) createOne:(nullable NSDictionary *)param;

/** PUT Model with primary key */
- (nonnull RACSignal *) updateOne:(nullable NSDictionary *)param;

/** DELETE Model with primary key */
- (nonnull RACSignal *) destroyOne:(nullable NSDictionary *)param;

/** GET Foreign Model with primary key */
//- (nonnull RACSignal *) fetchForeignModelWithPrimaryKeyValue:(nonnull id) primaryKeyValue foreignTableName:(nonnull NSString *)foreignTableName param:(nullable NSDictionary *)param;

/** DELETE All Model with primary key */
- (nonnull RACSignal *) destroyAll;

/** ORDER BY primaryKey ASC*/
- (nonnull RACSignal *) fetchAll;

- (nonnull RACSignal *) fetchAllSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) columnName, ...;

- (nonnull RACSignal *) fetchMultipleWith:(NSUInteger) start limit:(NSUInteger) limit soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) columnName, ...;

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWhereAllTheConditionsAreMet:(nonnull NSString * ) condition, ...;

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWhereAllTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count condtions:(nonnull NSString * ) condition, ...;

/**
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWhereAllTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) columnName condtions:(nonnull NSString * ) condition, ...;

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWherePartOfTheConditionsAreMet:(nonnull NSString * ) condition, ...;

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWherePartOfTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count  condtions:(nonnull NSString * ) condition, ...;

/**
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWherePartOfTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) columnName condtions:(nonnull NSString * ) condition, ...;


//Migration

/** 数字越大越后面执行*/

/** 返回当前版本*/
@property (nonatomic, strong, readonly, nonnull) NSMutableArray<YTXRestfulModelDBMigrationEntity *> * migrationBlocks;

/** 大于currentMigrationVersion将会依次执行，数字越大越后执行*/
- (void) migrate:(nonnull YTXRestfulModelDBMigrationEntity *) entity;

- (nonnull RACSignal *) createColumnWithStruct:(struct YTXRestfulModelDBSerializingStruct)sstruct;

- (nonnull RACSignal *) dropColumnWithStruct:(struct YTXRestfulModelDBSerializingStruct)sstruct;

- (nonnull RACSignal *) changeCollumnOldStruct:(struct YTXRestfulModelDBSerializingStruct) oldStruct toNewStruct:(struct YTXRestfulModelDBSerializingStruct) newStruct;

@optional

@end
