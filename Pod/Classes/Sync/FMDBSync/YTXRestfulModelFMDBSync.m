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
            if ([modelClass autoAlterTable]) {
                [self alterTable];
            } else {
                [self migrationTable];
            }
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
    NSMutableDictionary<NSString *, NSNumber *> * registerTableMap = [[self class]_sharedRegisterTableMap];
    
    if (registerTableMap[[self tableName]] != nil) {
        return nil;
    }
    
    __block NSError * error;
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        NSNumber * currentVersion = [self.modelClass currentMigrationVersion];

        BOOL success = NO;

        if (![db tableExists:[self tableName]]) {

            NSString *sql = [self sqlForCreatingTable];
            success = [db executeUpdate:sql withErrorAndBindings:&error];
            if (success) {
                [YTXRestfulModelFMDBSync saveMigrationVersionToUserDefault:currentVersion classOfModel:self.modelClass];
                registerTableMap[[self tableName]] = @1;
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
                [self.modelClass migrationsMethodWithSync:self];
                
                [self.modelClass dbWillMigrateWithSync:self];

                [self.migrationBlocks sortUsingComparator:^NSComparisonResult(YTXRestfulModelDBMigrationEntity * obj1, YTXRestfulModelDBMigrationEntity * obj2) {
                    return obj1.version > obj2.version;
                }];
                
                for (YTXRestfulModelDBMigrationEntity *entity in self.migrationBlocks) {
                    if (entity.version > migrationVersion) {
                        entity.block(db, &error);
                    }
                    if (error) {
                        *rollback = YES;
                        return;
                    }
                }

                [YTXRestfulModelFMDBSync saveMigrationVersionToUserDefault:currentVersion classOfModel:self.modelClass];
                
                [self.modelClass dbDidMigrateWithSync:self];
            }
        }
    }];

    return error;
}

- (nonnull NSError *) alterTable
{
    __block NSError * error;
    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        if ([db tableExists:[self tableName]]) {
            
            NSNumber * currentVersion = [self.modelClass currentMigrationVersion];
            NSNumber * migrationVersion = [YTXRestfulModelFMDBSync migrationVersionWithclassOfModelFromUserDefault:self.modelClass];
            //migration doing
            if (migrationVersion && [migrationVersion integerValue] < [currentVersion integerValue]) {
                NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@", [self tableName]];
                FMResultSet* rs = [db executeQuery:sql];
                NSArray *columns = [[rs columnNameToIndexMap] copy];
                [rs close];
                
                [db executeUpdate:[self sqlForAlterTableWithColumnInfo:columns] withErrorAndBindings:&error];
                
                if (error) {
                    *rollback = YES;
                    return;
                }
                
                [YTXRestfulModelFMDBSync saveMigrationVersionToUserDefault:currentVersion classOfModel:self.modelClass];
            }
        }
    }];
    
    return error;
}

- (nonnull NSError *) dropTable
{
    __block NSError *error = nil;

    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        BOOL success = [db executeUpdate:[self sqlForDropTable] withErrorAndBindings:&error];
        
        if (success) {
            NSMutableDictionary<NSString *, NSNumber *> * registerTableMap = [[self class]_sharedRegisterTableMap];
            [registerTableMap removeObjectForKey:[self tableName]];
        }
    }];

    return error;
}

- (nullable NSDictionary *) dictionaryWithFMResultSet:(FMResultSet *) rs error:(NSError * _Nullable * _Nullable) error
{
    NSArray* columns = [[rs columnNameToIndexMap] allKeys];
    NSDictionary<NSString *, YTXRestfulModelDBSerializingModel *> * map =  [self.modelClass tableKeyPathsByPropertyKey];
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

            YTXRestfulModelDBSerializingModel * sstruct = map[key];

            NSString * objectTypeString = typeMap[sstruct.objectClass][0];

            NSString * modelPropertyName = sstruct.columnName;

            Class cls = NSClassFromString(objectTypeString);

            NSString * stringValue = [rs stringForColumn:columnName];

            if (stringValue == nil) {
                continue;
            }

            id value = [cls objectForSqliteString:stringValue objectType: sstruct.objectClass];

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
    NSDictionary<NSString *, YTXRestfulModelDBSerializingModel *> * map =  [self.modelClass tableKeyPathsByPropertyKey];
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

            YTXRestfulModelDBSerializingModel * sstruct = map[key];

            NSString * objectTypeString = typeMap[sstruct.objectClass][0];

            NSString * modelPropertyName = sstruct.columnName;

            Class cls = NSClassFromString(objectTypeString);

            NSString * stringValue = [rs stringForColumn:columnName];

            if (stringValue == nil) {
                continue;
            }

            id value = [cls objectForSqliteString:stringValue objectType:sstruct.objectClass];

            if (value != nil) {
                [dict setObject:value forKey:modelPropertyName];
            }
        }
        
        [ret addObject:dict];
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
    NSAssert(param[self.primaryKey] != nil,@"必须在param找到主键的value");

    return [self _fetchOneWithSqliteStringSync:[self sqlForSelectOneWithPrimaryKeyValue:param[self.primaryKey]] error:error];
}


/** POST / PUT Model with primary key */
- (nullable NSDictionary *) saveOneSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error
{
    __block NSDictionary * ret = nil;
    __block NSError * currentError;
    __block BOOL success;
    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSDictionary<NSString *, YTXRestfulModelDBSerializingModel *> * map =  [self.modelClass tableKeyPathsByPropertyKey];
        
        YTXRestfulModelDBSerializingModel * primaryKeyStruct = map[self.primaryKey];
        
        NSAssert(primaryKeyStruct != nil, @"必须找到主键struct");
        
        NSAssert(primaryKeyStruct.isPrimaryKey, @"主键struct的isPrimaryKey必须为真");
        
        id value = param[self.primaryKey];
        NSString *saveSqlString;
        
        if (value != nil && [self _isExitWithDB:db primaryKeyValue:value])
        {
            saveSqlString = [self sqlForUpdateOneWithParam:param];
        }
        else {
            if (!primaryKeyStruct.autoincrement) {
                NSAssert(value != nil, @"如果不是自增的情况，更新或者创建都需要主键。");
            }
            saveSqlString = [self sqlForCreateOneWithParam:param];
        }

        success = [db executeUpdate:saveSqlString withErrorAndBindings:&currentError];
        
        if (!currentError && success) {
            NSString * sqliteString = nil;
            if (value != nil){
                // 有主键，再把结果查出来
                sqliteString = [self sqlForSelectOneWithPrimaryKeyValue:param[self.primaryKey]];
            }
            else {
                // 没有主键
                sqliteString = [self sqlForSelectLatestOneOrderBy:self.primaryKey];
            }

            FMResultSet* rs = [db executeQuery:sqliteString];
            ret = [self dictionaryWithFMResultSet:rs error:error];

            if (!ret) {
                currentError = [NSError errorWithDomain:ErrorDomain code:YTXRestfulModelDBErrorCodeNotFound userInfo:nil];
                return;
            }
            [rs close];
        }
        else {
            *rollback = YES;
        }

    }];

    if (error) {
        *error = currentError;
        
        if (!success && currentError == nil) {
            *error = [NSError errorWithDomain:ErrorDomain code:YTXRestfulModelDBErrorCodeUnkonw userInfo:nil];
        }
    }

    return ret;
}

/** GET Model with primary key */
- (BOOL) destroyOneSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error;
{
    __block BOOL result = YES;
    __block NSError * currentError;
    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSAssert(param[self.primaryKey] != nil,@"必须在param找到主键的value");
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

/** GET */
- (nullable NSDictionary *) fetchTopOneSyncWithError:(NSError * _Nullable * _Nullable) error;
{
    return [self _fetchOneWithSqliteStringSync:[self sqlForSelectTopOneOrderBy:self.primaryKey] error:error];
}

/** GET */
- (nullable NSDictionary *) fetchLatestOneSyncWithError:(NSError * _Nullable * _Nullable) error
{
    return [self _fetchOneWithSqliteStringSync:[self sqlForSelectLatestOneOrderBy:self.primaryKey] error:error];
}

/** ORDER BY primaryKey ASC*/
- (nonnull NSArray<NSDictionary *> *) fetchAllSyncWithError:(NSError * _Nullable * _Nullable) error
{
    return [self fetchAllSyncWithError:error soryBy:YTXRestfulModelDBSortByASC orderBy:@[[self primaryKey]]];
}

- (nonnull NSArray<NSDictionary *> *) fetchAllSyncWithError:(NSError * _Nullable * _Nullable)error soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSArray<NSString *> * )columnNames
{
    return [self _fetchMultipleWithSqliteStringSync:[self sqlForSelectAllSoryBy:sortBy orderBy:columnNames] error:error];
}

- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error start:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSArray<NSString *> * )columnNames
{
    return [self _fetchMultipleWithSqliteStringSync:[self sqlForSelectMultipleWithStart:start count:count soryBy:sortBy orderBy:columnNames] error:error];
}
/** GET Foreign Models with primary key */
- (nonnull NSArray<NSDictionary *> *) fetchForeignSyncWithModelClass:(nonnull Class<YTXRestfulModelDBSerializing>)modelClass primaryKeyValue:(nonnull id) value error:(NSError * _Nullable * _Nullable) error param:(nullable NSDictionary *)param
{
    NSDictionary<NSString *, YTXRestfulModelDBSerializingModel *> * map =  [modelClass tableKeyPathsByPropertyKey];
    NSString * primaryKey = nil;
    NSString * foreignKey = nil;


    for (YTXRestfulModelDBSerializingModel * valueStruct in map.allValues) {
        if (valueStruct.isPrimaryKey) {
            primaryKey = valueStruct.columnName;
        }
        if (valueStruct.foreignClassName && [NSStringFromClass(self.modelClass) isEqualToString:valueStruct.foreignClassName ] ) {
            foreignKey = valueStruct.columnName;
        }
    }

    NSAssert(primaryKey != nil, @"传入的modelClass的tableKeyPathsByPropertyKey需要定义主键");

    YTXRestfulModelFMDBSync * sync = [YTXRestfulModelFMDBSync syncWithModelOfClass:modelClass primaryKey:primaryKey];

    return [sync fetchMultipleSyncWithError:error whereAllTheConditionsAreMet:@[[YTXRestfulModelFMDBSync sqliteStringWhere:foreignKey equal:[value sqliteValue]]]];
}

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMet:(nonnull NSArray<NSString *> * )conditions
{
    return [self _fetchMultipleWithSqliteStringSync:[self sqlForSelectMultipleWhereAllTheConditionsAreMet:conditions] error:error];
}

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy conditions:(nonnull NSArray<NSString *> * )conditions
{
    return [self _fetchMultipleWithSqliteStringSync:[self sqlForSelectMultipleWhereAllTheConditionsAreMetWithSoryBy:sortBy orderBy:orderBy conditions:conditions] error:error];
}

/**
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error whereAllTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditions:(nonnull NSArray<NSString *> * )conditions
{
    return [self _fetchMultipleWithSqliteStringSync:[self sqlForSelectMultipleWhereAllTheConditionsAreMetWithStart:start count:count soryBy:sortBy orderBy:orderBy conditions:conditions] error:error];
}

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMet:(nonnull NSArray<NSString *> * )conditions
{
    return [self _fetchMultipleWithSqliteStringSync:[self sqlForSelectMultipleWherePartOfTheConditionsAreMet:conditions] error:error];
}

/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy  conditions:(nonnull NSArray<NSString *> * )conditions
{
    return [self _fetchMultipleWithSqliteStringSync:[self sqlForSelectMultipleWherePartOfTheConditionsAreMetWithSoryBy:sortBy orderBy:orderBy conditions:conditions] error:error];
}

/**
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull NSArray<NSDictionary *> *) fetchMultipleSyncWithError:(NSError * _Nullable * _Nullable)error wherePartOfTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditions:(nonnull NSArray<NSString *> * )conditions
{
    return [self _fetchMultipleWithSqliteStringSync:[self sqlForSelectMultipleWherePartOfTheConditionsAreMetWithStart:start count:count soryBy:sortBy orderBy:orderBy conditions:conditions] error:error];
}

- (nullable NSDictionary *) _fetchOneWithSqliteStringSync:(nonnull NSString *) sqliteString error:(NSError * _Nullable * _Nullable) error
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

        [rs close];
    }];

    if (error) {
        *error = currentError;
    }

    return ret;
}

#pragma mark migration
/** 大于currentMigrationVersion将会依次执行*/
- (void) migrate:(nonnull YTXRestfulModelDBMigrationEntity *) entity
{
    [[self migrationBlocks] addObject:entity];
}

- (BOOL) createColumnWithDB:(nonnull FMDatabase *)db structSync:(nonnull YTXRestfulModelDBSerializingModel *)sstruct error:(NSError * _Nullable * _Nullable)error
{
    return [db executeUpdate:[self sqlForAlterAddColumnWithStruct:sstruct] withErrorAndBindings:error];
}

#pragma mark sql string

- (nonnull NSString *) sqlForCreatingTable
{
    NSMutableDictionary<NSString *, YTXRestfulModelDBSerializingModel *> * map =  [self.modelClass tableKeyPathsByPropertyKey];

    YTXRestfulModelDBSerializingModel * primaryKeyStruct = map[self.primaryKey];
    
    NSAssert(primaryKeyStruct != nil, @"必须找到主键struct");
    
    NSAssert(primaryKeyStruct.isPrimaryKey, @"主键struct的isPrimaryKey必须为真");

    //Table Name
    NSString* tableName = [self tableName];
    NSString* primaryKey = self.primaryKey;
    NSDictionary* typeMap = [YTXRestfulModelFMDBSync mapOfCTypeToSqliteType];

    //Attributes
    NSMutableString* columns = [NSMutableString string];
    BOOL beAssignPrimaryKey = YES;

    if ([self.modelClass isPrimaryKeyAutoincrement]) {
        NSArray<NSString * > *  sqliteTypeArr = [[self class] mapOfCTypeToSqliteType][ primaryKeyStruct.objectClass ];
        
        if (primaryKeyStruct.autoincrement) {
            NSAssert([sqliteTypeArr[1] isEqualToString:@"INTEGER"] || [sqliteTypeArr[0] isEqualToString:@"NSNumber"], @"自增的类型必须是NSNumber或者转为INTEGER");
            [sqliteTypeArr count];
        }
    }
    
    
    BOOL first = YES;
    for (YTXRestfulModelDBSerializingModel * sstruct in map.allValues) {
        NSString* key = sstruct.columnName ? : sstruct.modelName;

        NSString* typeKey = sstruct.objectClass;
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
            [columns appendFormat:@" DEFAULT %@", sstruct.defaultValue];
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

- (nonnull NSString *)sqlForAlterTableWithColumnInfo:(NSArray *)columnInfo
{
    NSMutableDictionary<NSString *, YTXRestfulModelDBSerializingModel *> * map =  [self.modelClass tableKeyPathsByPropertyKey];
    
    NSDictionary* typeMap = [YTXRestfulModelFMDBSync mapOfCTypeToSqliteType];
    //Table Name
    NSString* tableName = [self tableName];
    
    NSMutableString* alterSql = [NSMutableString string];
    
    NSMutableDictionary *columnMap = [NSMutableDictionary dictionary];
    for (NSString *columnName in columnInfo) {
        columnMap[columnName] = @YES;
    }
    
    for (YTXRestfulModelDBSerializingModel * sstruct in map.allValues) {
        if (!typeMap[sstruct.objectClass]) continue;
        
        if (![columnMap[[sstruct.columnName lowercaseString]] boolValue]) {
            [alterSql appendString: [NSString stringWithFormat:@"%@;", [self sqlForAlterAddColumnWithStruct:sstruct] ] ] ;
        }
    }
    
    return alterSql;
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
    NSDictionary<NSString *, YTXRestfulModelDBSerializingModel *> * propertyMap = [self.modelClass tableKeyPathsByPropertyKey];
    NSMutableString* columns = [NSMutableString string];
    NSMutableString* values = [NSMutableString string];
    NSDictionary* typeMap = [YTXRestfulModelFMDBSync mapOfCTypeToSqliteType];

    BOOL first = YES;
    for (NSString * key in param) {
        NSString * lowerKey = [key lowercaseString];
        id value = param[key];
        NSString * strValue = [value sqliteValue];

        if (!propertyMap[key]) continue;

        YTXRestfulModelDBSerializingModel * sstruct = propertyMap[key];
        NSString* typeKey = sstruct.objectClass;

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
    NSDictionary<NSString *, YTXRestfulModelDBSerializingModel *> * propertyMap = [self.modelClass tableKeyPathsByPropertyKey];
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

        YTXRestfulModelDBSerializingModel * sstruct = propertyMap[key];
        NSString* typeKey = sstruct.objectClass;

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

- (nonnull NSString *) sqlForAlterAddColumnWithStruct:(nonnull YTXRestfulModelDBSerializingModel *) sstruct
{
    NSDictionary* typeMap = [YTXRestfulModelFMDBSync mapOfCTypeToSqliteType];
    NSString* typeKey = sstruct.objectClass;
    NSString* sqlType = typeMap[typeKey][1];

    return [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@ %@ %@", [self tableName], sstruct.columnName,
            sqlType,
            sstruct.defaultValue? [NSString stringWithFormat:@" DEFAULT %@", sstruct.defaultValue] : @""

    ];
}

- (nonnull NSString *) sqlForAlterDropColumnWithStruct:(nonnull YTXRestfulModelDBSerializingModel *) sstruct
{
    return [NSString stringWithFormat:@"ALTER TABLE %@ DROP COLUMN %@", [self tableName], sstruct.columnName];
}

- (nonnull NSString *) sqlForAlterChangeColumnWithOldStruct:(nonnull YTXRestfulModelDBSerializingModel *) oldStruct newStruct:(nonnull YTXRestfulModelDBSerializingModel *) newStruct
{
    NSDictionary* typeMap = [YTXRestfulModelFMDBSync mapOfCTypeToSqliteType];
    NSString* typeKey = newStruct.objectClass;
    NSString* sqlType = typeMap[typeKey][1];

    return [NSString stringWithFormat:@"ALTER TABLE %@ ALTER COLUMN %@ %@ %@ %@", [self tableName], oldStruct.columnName, newStruct.columnName, sqlType,
            newStruct.defaultValue? [NSString stringWithFormat:@" DEFAULT %@", newStruct.defaultValue] : @""  ];
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

- (nonnull NSString *) tableName
{
    return NSStringFromClass(self.modelClass);
}

+ (nonnull NSMutableDictionary<NSString *, NSNumber *> *)_sharedRegisterTableMap
{
    static dispatch_once_t onceToken;
    static NSMutableDictionary<NSString *, NSNumber *> * map;
    dispatch_once(&onceToken, ^{
        map = [NSMutableDictionary dictionary];
    });
    return map;
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
            @"NSDate":@[              @"NSNumber",        @"REAL"],
            @"NSNumber":@[            @"NSNumber",        @"REAL"],
            @"NSDictionary":@[        @"NSDictionary",    @"TEXT"],
            @"NSMutableDictionary":@[ @"NSDictionary",    @"TEXT"],
            @"NSArray":@[             @"NSArray",         @"TEXT"],
            @"NSMutableArray":@[      @"NSArray",         @"TEXT"],
            
            @"CGPoint":@[             @"NSValue",         @"TEXT"],
            @"CGSize":@[              @"NSValue",         @"TEXT"],
            @"CGRect":@[              @"NSValue",         @"TEXT"],
            @"CGVector":@[            @"NSValue",         @"TEXT"],
            @"CGAffineTransform":@[   @"NSValue",         @"TEXT"],
            @"UIEdgeInsets":@[        @"NSValue",         @"TEXT"],
            @"UIOffset":@[            @"NSValue",         @"TEXT"],
            @"NSRange":@[             @"NSValue",         @"TEXT"]
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

+ (nonnull NSArray *) arrayOfMappedArgsWithOriginArray:(nonnull NSArray *)originArray propertiesMap:(nonnull NSDictionary *)propertiesMap
{
    NSMutableArray *retArray = [NSMutableArray array];
    for (id arg in originArray) {
        [retArray addObject:propertiesMap[arg] ?: arg];
    }
    return retArray;
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
    return [NSString stringWithFormat:@"%@ LIKE %@", key, [value sqliteValue]];
}

@end
