//
//  YTXRestfulModelFMDBSync.h
//  Pods
//
//  Created by CaoJun on 16/2/22.
//
//

#import "YTXRestfulModelDBProtocol.h"

#import <Foundation/Foundation.h>

#define TYPEMAP(__rawType, __objcType, __sqliteType) \
__rawType:@[__objcType, __sqliteType]

//see Objective-C Runtime Programming Guide > Type Encodings.

#define kObjectCTypeToSqliteTypeMap \
@{\
TYPEMAP(@"c",                   @"NSNumber",        @"INTEGER"),\
TYPEMAP(@"i",                   @"NSNumber",        @"INTEGER"),\
TYPEMAP(@"s",                   @"NSNumber",        @"INTEGER"),\
TYPEMAP(@"l",                   @"NSNumber",        @"INTEGER"),\
TYPEMAP(@"q",                   @"NSNumber",        @"INTEGER"),\
TYPEMAP(@"C",                   @"NSNumber",        @"INTEGER"),\
TYPEMAP(@"I",                   @"NSNumber",        @"INTEGER"),\
TYPEMAP(@"S",                   @"NSNumber",        @"INTEGER"),\
TYPEMAP(@"L",                   @"NSNumber",        @"INTEGER"),\
TYPEMAP(@"Q",                   @"NSNumber",        @"INTEGER"),\
TYPEMAP(@"f",                   @"NSNumber",        @"REAL"),\
TYPEMAP(@"d",                   @"NSNumber",        @"REAL"),\
TYPEMAP(@"B",                   @"NSNumber",        @"INTEGER"),\
TYPEMAP(@"NSString",            @"NSString",        @"TEXT"),\
TYPEMAP(@"NSMutableString",     @"NSMutableString", @"TEXT"),\
TYPEMAP(@"NSDate",              @"NSDate",          @"REAL"),\
TYPEMAP(@"NSNumber",            @"NSNumber",        @"REAL"),\
TYPEMAP(@"NSDictionary",        @"NSDictionary",    @"TEXT"),\
TYPEMAP(@"CGPoint",             @"NSValue",         @"TEXT"),\
TYPEMAP(@"CGSize",              @"NSValue",         @"TEXT"),\
TYPEMAP(@"CGRect",              @"NSValue",         @"TEXT"),\
TYPEMAP(@"CGVector",            @"NSValue",         @"TEXT"),\
TYPEMAP(@"CGAffineTransform",   @"NSValue",         @"TEXT"),\
TYPEMAP(@"UIEdgeInsets",        @"NSValue",         @"TEXT"),\
TYPEMAP(@"UIOffset",            @"NSValue",         @"TEXT"),\
TYPEMAP(@"NSRange",             @"NSValue",         @"TEXT"),\
TYPEMAP(@"NSString",            @"NSString",        @"TEXT"),\
TYPEMAP(@"NSMutableString",     @"NSMutableString", @"TEXT"),\
TYPEMAP(@"NSDate",              @"NSDate",          @"REAL"),\
TYPEMAP(@"NSNumber",            @"NSNumber",        @"REAL"),\
TYPEMAP(@"NSDictionary",        @"NSDictionary",    @"TEXT"),\
TYPEMAP(@"NSArray",             @"NSArray",         @"TEXT"),\
}

@class FMDatabase;
@class FMDatabaseQueue;


@interface YTXRestfulModelFMDBSync : NSObject <YTXRestfulModelDBProtocol>

@property (nonatomic, strong, readonly, nonnull) FMDatabase * fmdb;

@property (nonatomic, strong, readonly, nonnull) FMDatabaseQueue * fmdbQueue;

@property (nonatomic, copy, readonly, nonnull) NSString * path;

@property (nonatomic, assign, readonly, nonnull) Class<YTXRestfulModelDBSerializing> modelClass;

@property (nonnull, nonatomic, copy, readonly) NSString * primaryKey;


+ (nonnull instancetype) syncWithModelOfClass:(nonnull Class<YTXRestfulModelDBSerializing>) modelClass primaryKey:(nonnull NSString *) key;

- (nonnull instancetype) initWithModelOfClass:(nonnull Class<YTXRestfulModelDBSerializing>) modelClass primaryKey:(nonnull NSString *) key;

- (nonnull RACSignal *) createTable;

- (nonnull RACSignal *) dropTable;

- (nonnull NSString *) tableName;

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

/** ORDER BY primaryKey ASC*/
- (nonnull RACSignal *) fetchAll;

- (nonnull RACSignal *) fetchAllSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) columnName, ...;

- (nonnull RACSignal *) fetchMultipleWith:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) columnName, ...;

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWhereAllTheConditionsAreMet:(nonnull NSString * ) condition, ...;

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWhereAllTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy condtions:(nonnull NSString * ) condition, ...;

/**
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWhereAllTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy condtions:(nonnull NSString * ) condition, ...;

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWherePartOfTheConditionsAreMet:(nonnull NSString * ) condition, ...;

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWherePartOfTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy condtions:(nonnull NSString * ) condition, ...;

/**
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWherePartOfTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy condtions:(nonnull NSString * ) condition, ...;


//Migration

/** 数字越大越后面执行*/

@property (nonatomic, strong, readonly, nonnull) NSMutableArray<YTXRestfulModelDBMigrationEntity *> * migrationBlocks;

/** 大于currentMigrationVersion将会依次执行*/
- (void) migrate:(nonnull YTXRestfulModelDBMigrationEntity *) entity;

- (nonnull RACSignal *) createColumnWithStruct:(struct YTXRestfulModelDBSerializingStruct)sstruct;

- (nonnull RACSignal *) dropColumnWithStruct:(struct YTXRestfulModelDBSerializingStruct)sstruct;

- (nonnull RACSignal *) changeCollumnOldStruct:(struct YTXRestfulModelDBSerializingStruct) oldStruct toNewStruct:(struct YTXRestfulModelDBSerializingStruct) newStruct;

// Tools

+ (nonnull NSValue *) valueWithStruct:(struct YTXRestfulModelDBSerializingStruct) sstruct;
+ (struct YTXRestfulModelDBSerializingStruct) structWithValue:(nonnull NSValue *) value;

+ (nonnull NSString * ) sqliteStringWhere:(nonnull NSString *) key equal:(nonnull id) value;
+ (nonnull NSString * ) sqliteStringWhere:(nonnull NSString *) key greatThan:(nonnull id) value;
+ (nonnull NSString * ) sqliteStringWhere:(nonnull NSString *) key greatThanOrEqaul:(nonnull id) value;
+ (nonnull NSString * ) sqliteStringWhere:(nonnull NSString *) key lessThan:(nonnull id) value;
+ (nonnull NSString * ) sqliteStringWhere:(nonnull NSString *) key lessThanOrEqual:(nonnull id) value;
+ (nonnull NSString * ) sqliteStringWhere:(nonnull NSString *) key match:(nonnull id) value;

@end
