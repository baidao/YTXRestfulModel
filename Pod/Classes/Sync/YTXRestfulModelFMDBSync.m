//
//  YTXRestfulModelFMDBSync.m
//  Pods
//
//  Created by CaoJun on 16/2/22.
//
//

#import "YTXRestfulModelFMDBSync.h"

#import "NSObject+YTXRestfulModelFMDBSync.h"
#import "NSArray+YTXRestfulModelFMDBSync.h"
#import "NSDictionary+RACSequenceAdditions.h"
#import "NSNumber+YTXRestfulModelFMDBSync.h"
#import "NSDate+YTXRestfulModelFMDBSync.h"
#import "NSString+YTXRestfulModelFMDBSync.h"
#import "NSValue+YTXRestfulModelFMDBSync.h"

#import <FMDB/FMDatabaseAdditions.h>
#import <FMDB/FMDatabaseQueue.h>
#import <objc/runtime.h>

static NSString * ErrorDomain = @"YTXRestfulModelFMDBSync";

@interface YTXRestfulModelFMDBSync()

@property (nonatomic, strong, nonnull) FMDatabaseQueue * fmdbQueue;

@property (nonatomic, strong, nonnull) NSMutableArray<YTXRestfulModelDBMigrationEntity *> * migrationBlocks;

@end

@implementation YTXRestfulModelFMDBSync

#pragma mark init

+ (nonnull instancetype) syncWithModelOfClass:(nonnull Class<YTXRestfulModelDBSerializing>) modelClass primaryKey:(nonnull NSString *) key
{
    return [[YTXRestfulModelFMDBSync alloc] initWithModelOfClass:modelClass primaryKey:key];
}

- (nonnull instancetype) initWithModelOfClass:(nonnull Class<YTXRestfulModelDBSerializing>) modelClass primaryKey:(nonnull NSString *) key
{
    if (self = [super init]) {
        _fmdbQueue = [[self class] sharedDBQueue];
        _modelClass = modelClass;
        _primaryKey = key;
        if ( [modelClass autoCreateTable] && [self createTable] == nil ) {
            [self migrationTable];
        }
    }
    return self;
}


#pragma mark db operation

+ (nonnull FMDatabaseQueue *) sharedDBQueue
{
    static FMDatabaseQueue * dbQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dbQueue = [FMDatabaseQueue databaseQueueWithPath:[self path]];
    });
    return dbQueue;
}

- (nonnull NSError *) createTable
{
    __block NSError * error;
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        NSNumber * currentVersion = [self.modelClass currentMigrationVersion];

        BOOL success = NO;

        if (![db tableExists:[self tableName]]) {

            NSString *sql = [self sqlForCreatingTable];
            success = [db executeUpdate:sql withErrorAndBindings:&error];
            if (success) {
                [YTXRestfulModelFMDBSync saveMigrationVersionToUserDefault:currentVersion classOfModel:self.modelClass];
            }
        }
    }];
    return error;
}

- (nonnull NSError *) migrationTable
{
    __block NSError * error;
    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        if ([db tableExists:[self tableName]]) {
            NSNumber * currentVersion = [self.modelClass currentMigrationVersion];
            NSNumber * migrationVersion = [YTXRestfulModelFMDBSync migrationVersionWithclassOfModelFromUserDefault:self.modelClass];
            //migration doing
            if (migrationVersion && [migrationVersion integerValue] < [currentVersion integerValue]) {
                [self.modelClass dbWillMigrate];

                [self.migrationBlocks sortUsingComparator:^NSComparisonResult(YTXRestfulModelDBMigrationEntity * obj1, YTXRestfulModelDBMigrationEntity * obj2) {
                    return obj1.version > obj2.version;
                }];

                @weakify(self);
                [[[self.migrationBlocks.rac_sequence.signal  filter:^BOOL(YTXRestfulModelDBMigrationEntity *entity) {
                    return entity.version > currentVersion;
                }] flattenMap:^RACStream *(YTXRestfulModelDBMigrationEntity *entity) {
                    @strongify(self);
                    return entity.block(self);
                }] subscribeError:^(NSError *err) {
                    *rollback = YES;
                    error = err;
                } completed:^{
                    @strongify(self);
                    [YTXRestfulModelFMDBSync saveMigrationVersionToUserDefault:currentVersion classOfModel:self.modelClass];
                    [[self modelClass] dbDidMigrate];
                }];
            }
        }
    }];

    return error;
}

- (nonnull NSError *) dropTable
{
    __block NSError *error = nil;

    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:[self sqlForDropTable] withErrorAndBindings:&error];
    }];

    return error;
}

- (nullable NSDictionary *) dictionaryWithFMResultSet:(FMResultSet *) rs error:(NSError * _Nullable * _Nullable) error
{
    NSArray* columns = [[rs columnNameToIndexMap] allKeys];
    NSDictionary<NSString *, NSValue *> * map =  [self.modelClass tableKeyPathsByPropertyKey];
    NSDictionary* typeMap = [YTXRestfulModelFMDBSync mapOfCTypeToSqliteType];
    NSMutableDictionary * ret = nil;

    BOOL success = [rs next];

    if (success) {
        ret = [NSMutableDictionary dictionary];

        for (NSString * key in map) {
            NSUInteger index = [columns indexOfObject: [key lowercaseString] ];

            if (index == NSNotFound) {
                continue;
            }

            NSString * columnName = [columns objectAtIndex:index];

            struct YTXRestfulModelDBSerializingStruct sstruct = [YTXRestfulModelFMDBSync structWithValue:map[key]];

            NSString * objectTypeString = typeMap[[NSString stringWithUTF8String:sstruct.objectClass]][0];

            NSString * modelPropertyName = [NSString stringWithUTF8String:sstruct.columnName];

            Class cls = NSClassFromString(objectTypeString);

            NSString * stringValue = [rs stringForColumn:columnName];

            if (stringValue == nil) {
                continue;
            }

            id value = [cls objectForSqliteString:stringValue objectType: [NSString stringWithUTF8String:sstruct.objectClass]];

            if (value != nil) {
                [ret setObject:value forKey:modelPropertyName];
            }

        }
    }
    else if (error) {
        *error = [NSError errorWithDomain:ErrorDomain code:NSCoderValueNotFoundError userInfo:@{ @"description": @"FMResultSet No Data" }];
    }
    [rs close];
    return ret;
}

- (nullable NSArray<NSDictionary *> *) arrayWithFMResultSet:(FMResultSet *) rs error:(NSError * _Nullable * _Nullable) error
{
    NSArray* columns = [[rs columnNameToIndexMap] allKeys];
    NSDictionary<NSString *, NSValue *> * map =  [self.modelClass tableKeyPathsByPropertyKey];
    NSDictionary* typeMap = [YTXRestfulModelFMDBSync mapOfCTypeToSqliteType];
    NSMutableArray<NSMutableDictionary *> * ret = [NSMutableArray array];

    while ([rs next]) {
            NSMutableDictionary * dict = [NSMutableDictionary dictionary];

        for (NSString * key in map) {
                NSUInteger index = [columns indexOfObject: [key lowercaseString] ];

                if (index == NSNotFound) {
                    continue;
                }

                NSString * columnName = [columns objectAtIndex:index];

                struct YTXRestfulModelDBSerializingStruct sstruct = [YTXRestfulModelFMDBSync structWithValue:map[key]];

                NSString * objectTypeString = typeMap[[NSString stringWithUTF8String:sstruct.objectClass]][0];

                NSString * modelPropertyName = [NSString stringWithUTF8String:sstruct.columnName];

                Class cls = NSClassFromString(objectTypeString);

                NSString * stringValue = [rs stringForColumn:columnName];

                if (stringValue == nil) {
                    continue;
                }

                id value = [cls objectForSqliteString:stringValue objectType:[NSString stringWithUTF8String:sstruct.objectClass]];

                if (value != nil) {
                    [dict setObject:value forKey:modelPropertyName];
                }

            }
    }

    [rs close];

    if ([ret count] == 0 && error) {
        *error = [NSError errorWithDomain:ErrorDomain code:NSCoderValueNotFoundError userInfo:@{ @"description": @"FMResultSet No Data" }];
    }

    return ret;
}

- (BOOL) _isExitWithDB:(nonnull FMDatabase *) db primaryKeyValue:(nonnull id) value
{
    BOOL exist = NO;
    FMResultSet* rs = [db executeQuery:[self sqlForSelectOneWithPrimaryKeyValue:value]];

    if ([rs next]) {
        exist = YES;
    }

    [rs close];

    return exist;
}

/** GET Model with primary key */
- (nullable NSDictionary *) fetchOneSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error;
{
    id value = param[self.primaryKey];
    NSAssert(value != nil,@"必须在param找到主键的value");

    NSError * currentError;

    NSDictionary * ret = [self _fetchOneWithSqliteStringSync:[self sqlForSelectOneWithPrimaryKeyValue:param[self.primaryKey]] error:&currentError];

    if (error) {
        *error = currentError;
    }

    return ret;
}

/** GET Model with primary key */
- (nonnull RACSignal *) fetchOne:(nullable NSDictionary *)param
{
    id value = param[self.primaryKey];
    NSAssert(value != nil,@"必须在param找到主键的value");
    return [self _fetchOneWithSqliteString:[self sqlForSelectOneWithPrimaryKeyValue:param[self.primaryKey]]];
}

/** POST / PUT Model with primary key */
- (nullable NSDictionary *) saveOneSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error
{
    __block NSDictionary * ret = nil;
    __block NSError * currentError;
    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        id value = param[self.primaryKey];
        if (value == nil || ![self _isExitWithDB:db primaryKeyValue:value]) {
            //不存在 需要创建
            [db executeUpdate:[self sqlForCreateOneWithParam:param] withErrorAndBindings:&currentError];
        }
        else {
            //存在 更新
            [db executeUpdate:[self sqlForUpdateOneWithParam:param] withErrorAndBindings:&currentError];
        }
        if (!currentError) {
            NSString * sqliteString = nil;
            if (value != nil){
                // 有主键，再把结果查出来
                sqliteString = [self sqlForSelectOneWithPrimaryKeyValue:param[self.primaryKey]];
            }
            else {
                // 没有主键
                sqliteString = [self sqlForSelectLatestOneOrderBy:self.primaryKey];

                //                NSDictionary<NSString *, NSValue *> * map =  [self.modelClass tableKeyPathsByPropertyKey];

                //                NSValue * primaryKeyStructValue = map[self.primaryKey];
                //
                //                struct YTXRestfulModelDBSerializingStruct primaryKeyStruct = [YTXRestfulModelFMDBSync structWithValue:primaryKeyStructValue];
                //                if (primaryKeyStruct.autoincrement) {
                //                    //自增的情况下
                //                }
                //                else {
                //
                //                }
            }

            FMResultSet* rs = [db executeQuery:sqliteString];
            ret = [self dictionaryWithFMResultSet:rs error:error];

            if (!ret) {
                currentError = [NSError errorWithDomain:ErrorDomain code:YTXRestfulModelDBErrorCodeNotFound userInfo:nil];
                return;
            }
        }
        else {
            *rollback = YES;
        }

    }];

    if (error) {
        *error = currentError;
    }

    return ret;
}

- (nonnull RACSignal *) saveOne:(nullable NSDictionary *)param
{
    NSError * error = nil;

    NSDictionary * ret = [self saveOneSync:param error:&error];

    return [self _createRACSingalWithNext:ret error:error];
}

/** GET Model with primary key */
- (BOOL) destroyOneSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error;
{
    __block BOOL result = YES;
    __block NSError * currentError;
    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        id value = param[self.primaryKey];
        NSAssert(value != nil,@"必须在param找到主键的value");
        [db executeUpdate:[self sqlForDeleteOneWithPrimaryKeyValue:param[self.primaryKey]] withErrorAndBindings:&currentError];
        if (currentError) {
            *rollback = YES;
            result = NO;
        }
    }];

    if (error) {
        *error = currentError;
    }

    return result;
}

/** DELETE Model with primary key */
- (nonnull RACSignal *) destroyOne:(nullable NSDictionary *)param
{
    NSError * error;

    BOOL result = [self destroyOneSync:param error:&error];

    return [self _createRACSingalWithNext:@(result) error:error];
}

/** DELETE All Model with primary key */
- (BOOL) destroyAllSyncWithError:(NSError * _Nullable * _Nullable) error
{
    __block BOOL result = YES;
    __block NSError * currentError;
    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:[self sqlForDeleteAll] withErrorAndBindings:&currentError];
        if (currentError) {
            *rollback = YES;
            result = NO;
        }
    }];

    if (error) {
        *error = currentError;
    }

    return result;
}

/** DELETE All Model with primary key */
- (nonnull RACSignal *) destroyAll
{
    NSError * error;

    BOOL result = [self destroyAllSyncWithError:&error];

    return [self _createRACSingalWithNext:@(result) error:error];
}


/** GET */
- (nullable NSDictionary *) fetchTopOneSyncWithError:(NSError * _Nullable * _Nullable) error;
{
    NSError * currentError;

    NSDictionary * ret = [self _fetchOneWithSqliteStringSync:[self sqlForSelectTopOneOrderBy:self.primaryKey] error:&currentError];

    if (error) {
        *error = currentError;
    }

    return ret;
}

/** GET */
- (nonnull RACSignal *) fetchTopOne
{
    return [self _fetchOneWithSqliteString: [self sqlForSelectTopOneOrderBy:self.primaryKey] ];
}

/** GET */
- (nullable NSDictionary *) fetchLatestOneSyncWithError:(NSError * _Nullable * _Nullable) error;
{
    NSError * currentError;

    NSDictionary * ret = [self _fetchOneWithSqliteStringSync:[self sqlForSelectLatestOneOrderBy:self.primaryKey] error:&currentError];

    if (error) {
        *error = currentError;
    }

    return ret;
}

/** GET */
- (nonnull RACSignal *) fetchLatestOne
{
    return [self _fetchOneWithSqliteString: [self sqlForSelectLatestOneOrderBy:self.primaryKey] ];
}

/** ORDER BY primaryKey ASC*/
- (nonnull NSArray<NSDictionary *> *) fetchAllSyncWithError:(NSError * _Nullable * _Nullable) error
{
    return [self fetchAllSyncWithError:error soryBy:YTXRestfulModelDBSortByASC orderBy:[self primaryKey]];
}

- (nonnull NSArray<NSDictionary *> *) fetchAllSyncWithError:(NSError * _Nullable * _Nullable)error soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) columnName, ...
{
    va_list args;
    va_start(args, columnName);

    NSArray * columnNames = [YTXRestfulModelFMDBSync arrayWithArgs:args];

    va_end(args);

    NSError * currentError;

    NSArray<NSDictionary *> * ret = [self _fetchMultipleWithSqliteStringSync:[self sqlForSelectAllSoryBy:sortBy orderBy:columnNames] error:&currentError];

    if (error) {
        *error = currentError;
    }

    return ret;
}

- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error start:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) columnName, ...
{
    va_list args;
    va_start(args, columnName);

    NSArray * columnNames = [YTXRestfulModelFMDBSync arrayWithArgs:args];

    va_end(args);

    NSError * currentError;

    NSArray<NSDictionary *> * ret = [self _fetchMultipleWithSqliteStringSync:[self sqlForSelectMultipleWithStart:start count:count soryBy:sortBy orderBy:columnNames] error:&currentError];

    if (error) {
        *error = currentError;
    }

    return ret;
}
/** GET Foreign Models with primary key */
- (nonnull NSArray<NSDictionary *> *) fetchForeignSyncWithModelClass:(nonnull Class<YTXRestfulModelDBSerializing>)modelClass primaryKeyValue:(nonnull id) value error:(NSError * _Nullable * _Nullable) error param:(nullable NSDictionary *)param
{
    NSDictionary<NSString *, NSValue *> * map =  [modelClass tableKeyPathsByPropertyKey];
    NSString * primaryKey = nil;
    NSString * foreignKey = nil;


    for (NSValue * value in map.allValues) {
        struct YTXRestfulModelDBSerializingStruct valueStruct = [YTXRestfulModelFMDBSync structWithValue:value];
        if (valueStruct.isPrimaryKey) {
            primaryKey = [NSString stringWithUTF8String:valueStruct.columnName];
        }
        if (valueStruct.foreignClassName && [NSStringFromClass(self.modelClass) isEqualToString:[NSString stringWithUTF8String:valueStruct.foreignClassName ]] ) {
            foreignKey = [NSString stringWithUTF8String:valueStruct.columnName];
        }
    }

    NSAssert(primaryKey != nil, @"传入的modelClass的tableKeyPathsByPropertyKey需要定义主键");

    YTXRestfulModelFMDBSync * sync = [YTXRestfulModelFMDBSync syncWithModelOfClass:modelClass primaryKey:primaryKey];

    NSError * currentError;

    NSArray<NSDictionary *> * ret = [sync fetchMultipleSyncWithError:&currentError whereAllTheConditionsAreMet: [YTXRestfulModelFMDBSync sqliteStringWhere:foreignKey equal:[value sqliteValue]] ];


    if (error) {
        *error = currentError;
    }

    return ret;
}

/** GET Foreign Models with primary key */
- (nonnull RACSignal *) fetchForeignWithModelClass:(nonnull Class<YTXRestfulModelDBSerializing>)modelClass primaryKeyValue:(nonnull id) value param:(nullable NSDictionary *)param
{
    NSError * error;
    NSArray<NSDictionary *> * ret = [self fetchForeignSyncWithModelClass:modelClass primaryKeyValue:value error:&error param:param];

    return [self _createRACSingalWithNext:ret error:error];
}

/** ORDER BY primaryKey ASC*/
- (nonnull RACSignal *) fetchAll
{
    return [self fetchAllSoryBy:YTXRestfulModelDBSortByASC orderBy:[self primaryKey]];
}

- (nonnull RACSignal *) fetchAllSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) columnName, ...
{
    va_list args;
    va_start(args, columnName);

    NSArray * columnNames = [YTXRestfulModelFMDBSync arrayWithArgs:args];

    va_end(args);

    return [self _fetchMultipleWithSqliteString:[self sqlForSelectAllSoryBy:sortBy orderBy:columnNames]];
}


- (nonnull RACSignal *) fetchMultipleWith:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) columnName, ...
{
    va_list args;
    va_start(args, columnName);

    NSArray * columnNames = [YTXRestfulModelFMDBSync arrayWithArgs:args];

    va_end(args);

    return [self _fetchMultipleWithSqliteString: [self sqlForSelectMultipleWithStart:start count:count soryBy:sortBy orderBy:columnNames]];
}

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMet:(nonnull NSString * ) condition, ...
{
    va_list args;
    va_start(args, condition);

    NSArray * conditions = [YTXRestfulModelFMDBSync arrayWithArgs:args];

    va_end(args);

    NSError * currentError;

    NSArray<NSDictionary *> * ret = [self _fetchMultipleWithSqliteStringSync:[self sqlForSelectMultipleWhereAllTheConditionsAreMet:conditions] error:&currentError];

    if (error)
    {
        *error = currentError;
    }

    return ret;
}

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy condtions:(nonnull NSString * ) condition, ...
{
    va_list args;
    va_start(args, condition);

    NSArray * conditions = [YTXRestfulModelFMDBSync arrayWithArgs:args];

    va_end(args);

    NSError * currentError;

    NSArray<NSDictionary *> * ret = [self _fetchMultipleWithSqliteStringSync:[self sqlForSelectMultipleWhereAllTheConditionsAreMetWithSoryBy:sortBy orderBy:orderBy conditions:conditions] error:&currentError];

    if (error)
    {
        *error = currentError;
    }

    return ret;
}

/**
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy condtions:(nonnull NSString * ) condition, ...
{
    va_list args;
    va_start(args, condition);

    NSArray * conditions = [YTXRestfulModelFMDBSync arrayWithArgs:args];

    va_end(args);

    NSError * currentError;

    NSArray<NSDictionary *> * ret = [self _fetchMultipleWithSqliteStringSync:[self sqlForSelectMultipleWhereAllTheConditionsAreMetWithStart:start count:count soryBy:sortBy orderBy:orderBy conditions:conditions] error:&currentError];

    if (error)
    {
        *error = currentError;
    }

    return ret;
}

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMet:(nonnull NSString * ) condition, ...
{
    va_list args;
    va_start(args, condition);

    NSArray * conditions = [YTXRestfulModelFMDBSync arrayWithArgs:args];

    va_end(args);

    NSError * currentError;

    NSArray<NSDictionary *> * ret = [self _fetchMultipleWithSqliteStringSync:[self sqlForSelectMultipleWherePartOfTheConditionsAreMet:conditions] error:&currentError];

    if (error)
    {
        *error = currentError;
    }

    return ret;
}

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy  condtions:(nonnull NSString * ) condition, ...
{
    va_list args;
    va_start(args, condition);

    NSArray * conditions = [YTXRestfulModelFMDBSync arrayWithArgs:args];

    va_end(args);

    NSError * currentError;

    NSArray<NSDictionary *> * ret = [self _fetchMultipleWithSqliteStringSync:[self sqlForSelectMultipleWherePartOfTheConditionsAreMetWithSoryBy:sortBy orderBy:orderBy conditions:conditions] error:&currentError];

    if (error)
    {
        *error = currentError;
    }

    return ret;
}

/**
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy condtions:(nonnull NSString * ) condition, ...
{
    va_list args;
    va_start(args, condition);

    NSArray * conditions = [YTXRestfulModelFMDBSync arrayWithArgs:args];

    va_end(args);

    NSError * currentError;

    NSArray<NSDictionary *> * ret = [self _fetchMultipleWithSqliteStringSync:[self sqlForSelectMultipleWherePartOfTheConditionsAreMetWithStart:start count:count soryBy:sortBy orderBy:orderBy conditions:conditions] error:&currentError];

    if (error)
    {
        *error = currentError;
    }

    return ret;
}


/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWhereAllTheConditionsAreMet:(nonnull NSString * ) condition, ...
{
    va_list args;
    va_start(args, condition);

    NSArray * conditions = [YTXRestfulModelFMDBSync arrayWithArgs:args];

    va_end(args);

    return [self _fetchMultipleWithSqliteString: [self sqlForSelectMultipleWhereAllTheConditionsAreMet:conditions]];
}


/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWhereAllTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy condtions:(nonnull NSString * ) condition, ...
{
    va_list args;
    va_start(args, condition);

    NSArray * conditions = [YTXRestfulModelFMDBSync arrayWithArgs:args];

    va_end(args);

    return [self _fetchMultipleWithSqliteString: [self sqlForSelectMultipleWhereAllTheConditionsAreMetWithSoryBy:sortBy orderBy:orderBy conditions:conditions]];
}


/**
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWhereAllTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy condtions:(nonnull NSString * ) condition, ...
{
    va_list args;
    va_start(args, condition);

    NSArray * conditions = [YTXRestfulModelFMDBSync arrayWithArgs:args];

    va_end(args);

    return [self _fetchMultipleWithSqliteString: [self sqlForSelectMultipleWhereAllTheConditionsAreMetWithStart:start count:count soryBy:sortBy orderBy:orderBy conditions:conditions]];
}


/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWherePartOfTheConditionsAreMet:(nonnull NSString * ) condition, ...
{
    va_list args;
    va_start(args, condition);

    NSArray * conditions = [YTXRestfulModelFMDBSync arrayWithArgs:args];

    va_end(args);

    return [self _fetchMultipleWithSqliteString: [self sqlForSelectMultipleWherePartOfTheConditionsAreMet:conditions]];
}


/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWherePartOfTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy condtions:(nonnull NSString * ) condition, ...
{
    va_list args;
    va_start(args, condition);

    NSArray * conditions = [YTXRestfulModelFMDBSync arrayWithArgs:args];

    va_end(args);

    return [self _fetchMultipleWithSqliteString: [self sqlForSelectMultipleWherePartOfTheConditionsAreMetWithSoryBy:sortBy orderBy:orderBy conditions:conditions]];
}


/**
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWherePartOfTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy condtions:(nonnull NSString * ) condition, ...
{
    va_list args;
    va_start(args, condition);

    NSArray * conditions = [YTXRestfulModelFMDBSync arrayWithArgs:args];

    va_end(args);

    return [self _fetchMultipleWithSqliteString: [self sqlForSelectMultipleWhereAllTheConditionsAreMetWithStart:start count:count soryBy:sortBy orderBy:orderBy conditions:conditions]];
}

- (nullable NSDictionary *) _fetchOneWithSqliteStringSync:(nonnull NSString *) sqliteString error:(NSError * _Nonnull * _Nonnull) error
{
    __block NSDictionary * ret;
    __block NSError * currentError;
    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet* rs = [db executeQuery:sqliteString];

        ret = [self dictionaryWithFMResultSet:rs error:&currentError];

        if (currentError) {
            *rollback = YES;
            return;
        }
        if (!ret) {
            currentError = [NSError errorWithDomain:ErrorDomain code:YTXRestfulModelDBErrorCodeNotFound userInfo:nil];
        }

    }];

    if (error) {
        *error = currentError;
    }

    return ret;
}

- (nonnull RACSignal *) _fetchOneWithSqliteString:(nonnull NSString *) sqlitString
{
    NSError * error;
    NSDictionary * ret = [self _fetchOneWithSqliteStringSync:sqlitString error:&error];

    return [self _createRACSingalWithNext:ret error:error];
}

- (nullable NSArray<NSDictionary *> *) _fetchMultipleWithSqliteStringSync:(nonnull NSString *) sqliteString error:(NSError * _Nonnull * _Nonnull) error
{
    __block NSArray * ret;
    __block NSError * currentError;
    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet * rs = [db executeQuery:sqliteString];

        ret = [self arrayWithFMResultSet:rs error:&currentError];

        if (currentError) {
            *rollback = YES;
            return;
        }
        if (!ret) {
            currentError = [NSError errorWithDomain:ErrorDomain code:YTXRestfulModelDBErrorCodeNotFound userInfo:nil];
            return;
        }

    }];

    if (error) {
        *error = currentError;
    }

    return ret;
}

- (nonnull RACSignal *) _fetchMultipleWithSqliteString:(nonnull NSString *) sqliteString
{
    NSError * error;
    id result = [self _fetchMultipleWithSqliteStringSync:sqliteString error:&error];
    return [self _createRACSingalWithNext:result error:error];
}

- (nonnull RACSignal *) _createRACSingalWithNext:(id) ret error:(nullable NSError *) error
{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (error) {
                [subscriber sendError:error];
                return;
            }
            [subscriber sendNext:ret];
            [subscriber sendCompleted];
        });
        return nil;
    }];
}

#pragma mark migration
/** 大于currentMigrationVersion将会依次执行*/
- (void) migrate:(nonnull YTXRestfulModelDBMigrationEntity *) entity
{
    [[self migrationBlocks] addObject:entity];
}

- (BOOL) createColumnWithStructSync:(struct YTXRestfulModelDBSerializingStruct)sstruct error:(NSError * _Nullable * _Nullable)error
{
    __block NSError *currentError = nil;

    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:[self sqlForAlterAddColumnWithStruct:sstruct] withErrorAndBindings:&currentError];
        if (currentError) {
            *rollback = YES;
        }
    }];

    if (error) {
        *error = currentError;
    }

    return currentError == nil;
}


- (BOOL) dropColumnWithStructSync:(struct YTXRestfulModelDBSerializingStruct)sstruct error:(NSError * _Nullable * _Nullable)error
{
    __block NSError *currentError = nil;

    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {

        [db executeUpdate:[self sqlForAlterDropColumnWithStruct:sstruct] withErrorAndBindings:&currentError];
        if (currentError) {
            *rollback = YES;
        }
    }];

    if (error) {
        *error = currentError;
    }

    return currentError == nil;
}

- (BOOL) changeCollumnOldStructSync:(struct YTXRestfulModelDBSerializingStruct) oldStruct toNewStruct:(struct YTXRestfulModelDBSerializingStruct) newStruct error:(NSError * _Nullable * _Nullable)error
{
    __block NSError *currentError = nil;

    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:[self sqlForAlterChangeColumnWithOldStruct:oldStruct newStruct:newStruct] withErrorAndBindings:&currentError];
        if (currentError) {
            *rollback = YES;
        }
    }];

    if (error) {
        *error = currentError;
    }

    return currentError == nil;
}

- (nonnull RACSignal *) createColumnWithStruct:(struct YTXRestfulModelDBSerializingStruct)sstruct
{
    NSError *error = nil;
    [self createColumnWithStructSync:sstruct error:&error];
    return [self _createRACSingalWithNext:nil error:error];
}

- (nonnull RACSignal *) dropColumnWithStruct:(struct YTXRestfulModelDBSerializingStruct)sstruct
{
    NSError *error = nil;
    [self dropColumnWithStructSync:sstruct error:&error];
    return [self _createRACSingalWithNext:nil error:error];
}

- (nonnull RACSignal *) changeCollumnOldStruct:(struct YTXRestfulModelDBSerializingStruct) oldStruct toNewStruct:(struct YTXRestfulModelDBSerializingStruct) newStruct
{
    NSError *error = nil;
    [self changeCollumnOldStructSync:oldStruct toNewStruct:newStruct error:&error];
    return [self _createRACSingalWithNext:nil error:error];
}

#pragma mark sql string

- (nonnull NSString *) sqlForCreatingTable
{
    NSDictionary<NSString *, NSValue *> * map =  [self.modelClass tableKeyPathsByPropertyKey];

    NSValue * primaryKeyStructValue = map[self.primaryKey];

    NSAssert(primaryKeyStructValue != nil, @"必须找到主键struct");

    struct YTXRestfulModelDBSerializingStruct primaryKeyStruct = [YTXRestfulModelFMDBSync structWithValue:primaryKeyStructValue];

    NSAssert(primaryKeyStruct.isPrimaryKey, @"主键struct的isPrimaryKey必须为真");

    //Table Name
    NSString* tableName = [self tableName];
    NSString* primaryKey = self.primaryKey;
    NSDictionary* typeMap = [YTXRestfulModelFMDBSync mapOfCTypeToSqliteType];

    //Attributes
    NSMutableString* columns = [NSMutableString string];
    BOOL beAssignPrimaryKey = YES;

    BOOL first = YES;
    for (NSValue * value in map.allValues) {
        struct YTXRestfulModelDBSerializingStruct sstruct = [YTXRestfulModelFMDBSync structWithValue:value];
        NSString* key = [NSString stringWithUTF8String:sstruct.columnName ? : sstruct.modelName];

        NSString* typeKey = [NSString stringWithUTF8String:(sstruct.objectClass)];
        //TODO:外键
        if (!typeMap[typeKey]) continue;

        if (!first) [columns appendString:@","];
        first = NO;

        NSString* sqlType = typeMap[typeKey][1];

        BOOL isAutoincrement = sstruct.autoincrement && sstruct.isPrimaryKey;

        if (isAutoincrement && [sqlType isEqualToString:@"REAL"]){
            sqlType = @"INTEGER";
        }

        [columns appendFormat:@"%@ %@", key, sqlType];
        if (beAssignPrimaryKey && [primaryKey isEqualToString:key]) {
            [columns appendFormat:@" PRIMARY KEY"];
            beAssignPrimaryKey = NO;
        }
        // If a column has the type INTEGER PRIMARY KEY AUTOINCREMENT then a slightly different ROWID selection algorithm is used.
        if (isAutoincrement) {
            [columns appendFormat:@" AUTOINCREMENT"];
        }
        //提供默认值
        if (sstruct.defaultValue) {
            [columns appendFormat:@" DEFAULT %@", [NSString stringWithUTF8String:sstruct.defaultValue]];
        }

        if (sstruct.unique) {
            [columns appendFormat:@" UNIQUE"];
        }
//        else {
//            //设置默认值
//            if ([sqlType isEqualToString:@"INTEGER"]) {
//                [columns appendFormat:@" DEFAULT 0"];
//            } else if ([sqlType isEqualToString:@"REAL"]) {
//                [columns appendFormat:@" DEFAULT 0.0"];
//            }
//        }
    }

    return [NSString stringWithFormat:@"CREATE TABLE %@ (%@)", tableName, columns];
}

- (nonnull NSString *) sqlForDropTable
{
    return [NSString stringWithFormat:@"DROP TABLE %@", [self tableName]];
}

- (nonnull NSString *) sqlForSelectOneWithPrimaryKeyValue:(id) value
{
    NSString * valueString = [(NSObject *)value sqliteValue];

    return [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@=%@", [self tableName], [self primaryKey], valueString];
}

- (nonnull NSString *) sqlForSelectTopOneOrderBy:(nonnull NSString *) name
{
    return [NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY %@ LIMIT 1", [self tableName], name];
}

- (nonnull NSString *) sqlForSelectLatestOneOrderBy:(nonnull NSString *) name
{
    return [NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY %@ DESC LIMIT 1", [self tableName], name];
}

- (nonnull NSString *) sqlForCreateOneWithParam:(NSDictionary *) param
{
    NSDictionary<NSString *, NSValue *> * propertyMap = [self.modelClass tableKeyPathsByPropertyKey];
    NSMutableString* columns = [NSMutableString string];
    NSMutableString* values = [NSMutableString string];
    NSDictionary* typeMap = [YTXRestfulModelFMDBSync mapOfCTypeToSqliteType];

    BOOL first = YES;
    for (NSString * key in param) {
        NSString * lowerKey = [key lowercaseString];
        id value = param[key];
        NSString * strValue = [value sqliteValue];

        if (!propertyMap[key]) continue;

        struct YTXRestfulModelDBSerializingStruct sstruct = [YTXRestfulModelFMDBSync structWithValue:propertyMap[key]];
        NSString* typeKey = [NSString stringWithUTF8String:(sstruct.objectClass)];

        if (!typeMap[typeKey]) continue;

        if (value) {
            if (!first) {
                [columns appendString:@","];
                [values appendString:@","];
            }
            first = NO;
            [columns appendString:lowerKey];
            [values appendString:strValue?strValue:@""];
        }
    }

    return [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", [self tableName], columns, values];
}

- (nonnull NSString *) sqlForUpdateOneWithParam:(NSDictionary *) param
{
    NSDictionary<NSString *, NSValue *> * propertyMap = [self.modelClass tableKeyPathsByPropertyKey];
    NSMutableString* updateString = [NSMutableString string];
    NSDictionary* typeMap = [YTXRestfulModelFMDBSync mapOfCTypeToSqliteType];
    NSString* primaryKey = [self primaryKey];

    BOOL first = YES;

    for (NSString* key in [param allKeys]) {
        if ([key isEqualToString:primaryKey]) continue;

        NSString * lowerKey = [key lowercaseString];
        id value = param[key];
        NSString * strValue = [value sqliteValue];

        if (!propertyMap[key]) continue;

        struct YTXRestfulModelDBSerializingStruct sstruct = [YTXRestfulModelFMDBSync structWithValue:propertyMap[key]];
        NSString* typeKey = [NSString stringWithUTF8String:(sstruct.objectClass)];

        if (!typeMap[typeKey]) continue;

        if (value) {
            if (!first) {
                [updateString appendString:@","];
            }
            first = NO;
            [updateString appendString:[NSString stringWithFormat:@"%@=%@", lowerKey, strValue]];
        }
    }

    return [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@=%@", [self tableName], updateString, primaryKey, [param[primaryKey] sqliteValue]];
}

- (nonnull NSString *) sqlForDeleteOneWithPrimaryKeyValue:(id) value
{
    NSString * valueString = [(NSObject *)value sqliteValue];

    return [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=%@", [self tableName], [self primaryKey], valueString];
}

- (nonnull NSString *) sqlForAlterAddColumnWithStruct:(struct YTXRestfulModelDBSerializingStruct) sstruct
{
    NSDictionary* typeMap = [YTXRestfulModelFMDBSync mapOfCTypeToSqliteType];
    NSString* typeKey = [NSString stringWithUTF8String:(sstruct.objectClass)];
    NSString* sqlType = typeMap[typeKey][1];

    return [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@ %@ %@", [self tableName], [NSString stringWithUTF8String:sstruct.columnName ],
            sqlType,
            sstruct.defaultValue? [NSString stringWithFormat:@" DEFAULT %@", [NSString stringWithUTF8String:sstruct.defaultValue]] : @""

    ];
}

- (nonnull NSString *) sqlForAlterDropColumnWithStruct:(struct YTXRestfulModelDBSerializingStruct) sstruct
{
    return [NSString stringWithFormat:@"ALTER TABLE %@ DROP COLUMN %@", [self tableName], [NSString stringWithUTF8String:sstruct.columnName]];
}

- (nonnull NSString *) sqlForAlterChangeColumnWithOldStruct:(struct YTXRestfulModelDBSerializingStruct) oldStruct newStruct:(struct YTXRestfulModelDBSerializingStruct) newStruct
{
    NSDictionary* typeMap = [YTXRestfulModelFMDBSync mapOfCTypeToSqliteType];
    NSString* typeKey = [NSString stringWithUTF8String:(newStruct.objectClass)];
    NSString* sqlType = typeMap[typeKey][1];

    return [NSString stringWithFormat:@"ALTER TABLE %@ CHANGE COLUMN %@ %@ %@ %@", [self tableName], [NSString stringWithUTF8String:oldStruct.columnName], [NSString stringWithUTF8String:newStruct.columnName], sqlType,
            newStruct.defaultValue? [NSString stringWithFormat:@" DEFAULT %@", [NSString stringWithUTF8String:newStruct.defaultValue]] : @""  ];
}

- (nonnull NSString *) sqlForDeleteAll
{
    return [NSString stringWithFormat:@"DELETE FROM %@", [self tableName]];
}

- (nonnull NSString *) sqlForSelectAllSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSArray<NSString *> * ) columnNames
{
    NSString * sortyByString = [columnNames componentsJoinedByString:@","];

    return [NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY %@ %@", [self tableName], sortyByString, [YTXRestfulModelFMDBSync stringWithYTXRestfulModelDBSortBy:sortBy]];
}

- (nonnull NSString *) sqlForSelectMultipleWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSArray<NSString *> * ) columnNames
{
    return [NSString stringWithFormat:@"%@ LIMIT %tu, %tu", [self sqlForSelectAllSoryBy:sortBy orderBy:columnNames], start, count];
}

- (nonnull NSString *) _sqlForSelectMultipleWhereConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString *) orderBy connection:(NSString *)connection conditions:(nonnull NSArray<NSString *> * )conditions
{
    return [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ ORDER BY %@ %@", [self tableName], [conditions componentsJoinedByString:[NSString stringWithFormat:@" %@ " , connection] ], orderBy, [YTXRestfulModelFMDBSync stringWithYTXRestfulModelDBSortBy:sortBy]];
}


- (nonnull NSString *) sqlForSelectMultipleWhereAllTheConditionsAreMet:(nonnull NSArray<NSString *> * )conditions
{
    return [self sqlForSelectMultipleWhereAllTheConditionsAreMetWithSoryBy:YTXRestfulModelDBSortByASC orderBy:[self primaryKey] conditions:conditions];
}

- (nonnull NSString *) sqlForSelectMultipleWhereAllTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString *) orderBy conditions:(nonnull NSArray<NSString *> * )conditions
{
    return [self _sqlForSelectMultipleWhereConditionsAreMetWithSoryBy:sortBy orderBy:orderBy connection:@"AND" conditions:conditions];
}

- (nonnull NSString *) sqlForSelectMultipleWhereAllTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString *) orderBy conditions:(nonnull NSArray<NSString *> * )conditions
{
    return [NSString stringWithFormat:@"%@ LIMIT %tu, %tu", [self sqlForSelectMultipleWhereAllTheConditionsAreMetWithSoryBy:sortBy orderBy:orderBy conditions:conditions], start, count];
}

- (nonnull NSString *) sqlForSelectMultipleWherePartOfTheConditionsAreMet:(nonnull NSArray<NSString *> * )conditions
{
    return [self sqlForSelectMultipleWherePartOfTheConditionsAreMetWithSoryBy:YTXRestfulModelDBSortByASC orderBy:[self primaryKey] conditions:conditions];
}

- (nonnull NSString *) sqlForSelectMultipleWherePartOfTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString *) orderBy conditions:(nonnull NSArray<NSString *> * )conditions
{
    return [self _sqlForSelectMultipleWhereConditionsAreMetWithSoryBy:sortBy orderBy:orderBy connection:@"OR" conditions:conditions];
}

- (nonnull NSString *) sqlForSelectMultipleWherePartOfTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString *) orderBy conditions:(nonnull NSArray<NSString *> * )conditions
{
    return [NSString stringWithFormat:@"%@ LIMIT %tu, %tu", [self sqlForSelectMultipleWherePartOfTheConditionsAreMetWithSoryBy:sortBy orderBy:orderBy conditions:conditions], start, count];
}

#pragma mark other

- (nonnull NSString *) tableName;
{
    return NSStringFromClass(self.modelClass);
}

+ (NSString *)path
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    NSString *documentsDirectory = [paths objectAtIndex:0];

    return [documentsDirectory stringByAppendingPathComponent:@"/YTXRestfulModel.db"];

}

- (NSMutableArray *)migrationBlocks
{
    if (!_migrationBlocks) {
        _migrationBlocks = [NSMutableArray array];
    }
    return _migrationBlocks;
}

#pragma makr Tools

+ (nonnull NSDictionary<NSString *, NSArray<NSString * > * > *) mapOfCTypeToSqliteType
{
    static dispatch_once_t onceToken;
    static NSDictionary<NSString *, NSArray<NSString * > * > * map;
    dispatch_once(&onceToken, ^{
        //see Objective-C Runtime Programming Guide > Type Encodings.
        map = @{\
          @"c":@[                   @"NSNumber",        @"INTEGER"],
          @"i":@[                   @"NSNumber",        @"INTEGER"],
          @"s":@[                   @"NSNumber",        @"INTEGER"],
          @"l":@[                   @"NSNumber",        @"INTEGER"],
          @"q":@[                   @"NSNumber",        @"INTEGER"],
          @"C":@[                   @"NSNumber",        @"INTEGER"],
          @"I":@[                   @"NSNumber",        @"INTEGER"],
          @"S":@[                   @"NSNumber",        @"INTEGER"],
          @"L":@[                   @"NSNumber",        @"INTEGER"],
          @"Q":@[                   @"NSNumber",        @"INTEGER"],
          @"f":@[                   @"NSNumber",        @"REAL"],
          @"d":@[                   @"NSNumber",        @"REAL"],
          @"B":@[                   @"NSNumber",        @"INTEGER"],
          @"NSString":@[            @"NSString",        @"TEXT"],
          @"NSMutableString":@[     @"NSMutableString", @"TEXT"],
          @"NSDate":@[              @"NSDate",          @"REAL"],
          @"NSNumber":@[            @"NSNumber",        @"REAL"],
          @"NSDictionary":@[        @"NSDictionary",    @"TEXT"],
          @"CGPoint":@[             @"NSValue",         @"TEXT"],
          @"CGSize":@[              @"NSValue",         @"TEXT"],
          @"CGRect":@[              @"NSValue",         @"TEXT"],
          @"CGVector":@[            @"NSValue",         @"TEXT"],
          @"CGAffineTransform":@[   @"NSValue",         @"TEXT"],
          @"UIEdgeInsets":@[        @"NSValue",         @"TEXT"],
          @"UIOffset":@[            @"NSValue",         @"TEXT"],
          @"NSRange":@[             @"NSValue",         @"TEXT"],
          @"NSString":@[            @"NSString",        @"TEXT"],
          @"NSMutableString":@[     @"NSMutableString", @"TEXT"],
          @"NSDate":@[              @"NSDate",          @"REAL"],
          @"NSDictionary":@[        @"NSDictionary",    @"TEXT"],
          @"NSArray":@[             @"NSArray",         @"TEXT"]
          };
    });
    return map;
}

+ (nonnull NSString *) stringWithYTXRestfulModelDBSortBy:(YTXRestfulModelDBSortBy) sortyBy
{
    switch (sortyBy) {
        case YTXRestfulModelDBSortByDESC:
            return @"DESC";
            break;
        case YTXRestfulModelDBSortByASC:
        default:
            return @"ASC";
            break;
    }
}

+ (nonnull NSArray *) arrayWithArgs:(va_list) args
{
    NSMutableArray * array = [NSMutableArray array];
    id arg = nil;
    while ((arg = va_arg(args,id))) {
        [array addObject:arg];
    }
    return array;
}

+ (nonnull NSValue *) valueWithStruct:(struct YTXRestfulModelDBSerializingStruct) sstruct
{
    return [NSValue value:&sstruct withObjCType:@encode(struct YTXRestfulModelDBSerializingStruct)];
}

+ (struct YTXRestfulModelDBSerializingStruct) structWithValue:(nonnull NSValue *) value
{
    struct YTXRestfulModelDBSerializingStruct sstruct;

    [value getValue:&sstruct];

    return sstruct;
}

+ (nonnull NSString *) migrationVersionKeyWithClassOfModel: (Class) modelClass
{
    return [NSString stringWithFormat:@"%@ version of %@", NSStringFromClass([self class]),  NSStringFromClass(modelClass)];
}

+ (void) saveMigrationVersionToUserDefault:(nullable NSNumber *) version classOfModel: (Class) modelClass
{
    if (version) {
        [[NSUserDefaults standardUserDefaults] setValue:version forKey:[self migrationVersionKeyWithClassOfModel:modelClass]];
    }
}

+ (nullable NSNumber *) migrationVersionWithclassOfModelFromUserDefault: (Class) modelClass
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:[self migrationVersionKeyWithClassOfModel:modelClass]];
}

+ (nonnull NSString * ) sqliteStringWhere:(nonnull NSString *) key equal:(nonnull id) value
{
    return [NSString stringWithFormat:@"%@ = %@", key, [value sqliteValue]];
}
+ (nonnull NSString * ) sqliteStringWhere:(nonnull NSString *) key greatThan:(nonnull id) value
{
    return [NSString stringWithFormat:@"%@ > %@", key, [value sqliteValue]];
}
+ (nonnull NSString * ) sqliteStringWhere:(nonnull NSString *) key greatThanOrEqaul:(nonnull id) value
{
    return [NSString stringWithFormat:@"%@ >= %@", key, [value sqliteValue]];
}
+ (nonnull NSString * ) sqliteStringWhere:(nonnull NSString *) key lessThan:(nonnull id) value
{
    return [NSString stringWithFormat:@"%@ < %@", key, [value sqliteValue]];
}
+ (nonnull NSString * ) sqliteStringWhere:(nonnull NSString *) key lessThanOrEqual:(nonnull id) value
{
    return [NSString stringWithFormat:@"%@ <= %@", key, [value sqliteValue]];
}
+ (nonnull NSString * ) sqliteStringWhere:(nonnull NSString *) key like:(nonnull id) value
{
    return [NSString stringWithFormat:@"%@ like %@", key, [value sqliteValue]];
}

@end
