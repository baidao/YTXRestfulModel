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

#import <FMDB/FMDatabase+FTS3.h>
#import <FMDB/FMDatabaseAdditions.h>
#import <FMDB/FMDatabaseQueue.h>
#import <objc/runtime.h>

static NSString * ErrorDomain = @"YTXRestfulModelFMDBSync";

@interface YTXRestfulModelFMDBSync()

@property (nonatomic, strong, nonnull) FMDatabase * fmdb;

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
        _fmdb = [FMDatabase databaseWithPath:self.path];
        _fmdbQueue = [FMDatabaseQueue databaseQueueWithPath:self.path];
        _modelClass = modelClass;
        _primaryKey = key;
        [self createTable];
    }
    return self;
}

#pragma mark db operation

- (nonnull RACSignal *) createTable
{
    RACSubject * subject = [RACSubject subject];
    
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        NSNumber * currentVersion = [self.modelClass currentMigrationVersion];
        
        BOOL success = NO;
        NSError *error = nil;
        
        if (![db tableExists:[self tableName]]) {
            NSString *sql = [self sqlForCreatingTable];
            success = [db executeUpdate:sql withErrorAndBindings:&error];
            NSLog(@"[%d]CREATE TABLE SQL:%@", success, sql);
            if (success) {
                [YTXRestfulModelFMDBSync saveMigrationVersionToUserDefault:currentVersion classOfModel:self.modelClass];
                [subject sendNext:nil];
                [subject sendCompleted];
            }
            else
            {
                [subject sendError:error];
                NSLog(@"CREATE TABLE ERROR:%@",error);
            }
        }
        else {
            NSNumber * migrationVersion = [YTXRestfulModelFMDBSync migrationVersionWithclassOfModelFromUserDefault:self.modelClass];
            //migration doing
            if (migrationVersion || migrationVersion < currentVersion) {
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
                }] subscribeError:^(NSError *error) {
                    [subject sendError:error];
                } completed:^{
                    @strongify(self);
                    [subject sendNext:nil];
                    [subject sendCompleted];
                    [[self modelClass] dbDidMigrate];
                }];
            }
        }
    }];
    
    return subject;
}

- (nonnull RACSignal *) dropTable
{
    RACSubject * subject = [RACSubject subject];
    
    [self.fmdbQueue inDatabase:^(FMDatabase *db) {
        NSError *error = nil;
        [db executeUpdate:[self sqlForDropTable] withErrorAndBindings:&error];
        if (!error) {
            [subject sendNext:nil];
            [subject sendCompleted];
        }
        else {
            [subject sendError:error];
        }
    }];
    
    return subject;
}

/** GET Model with primary key */
- (nonnull RACSignal *) fetchOne:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    
    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        id value = param[self.primaryKey];
        NSAssert(value != nil,@"必须在param找到主键的value");
        NSError * error;
        
        FMResultSet* rs = [db executeQuery:[self sqlForSelectOneWithPrimaryKeyValue:param[self.primaryKey]]];
        NSArray* columns = [[rs columnNameToIndexMap] allKeys];
        NSDictionary<NSString *, NSValue *> * map =  [self.modelClass tableKeyPathsByPropertyKey];
        
        NSMutableDictionary * ret = [NSMutableDictionary dictionary];
        
        [rs nextWithError:&error];
        
        if (!error) {
            for (NSString * columnName in columns) {
                struct YTXRestfulModelDBSerializingStruct sstruct = [YTXRestfulModelFMDBSync structWithValue:map[columnName]];
                Class cls = sstruct.objectClass;
                
                id value = [cls objectForSqliteString:[rs stringForColumn:columnName] objectType:NSStringFromClass(cls)];
                
                [ret setObject:columnName forKey:value];
            }
            [subject sendNext:ret];
            [subject sendCompleted];
        }
        else {
            [subject sendError:error];
        }
        
        [rs close];
    }];
    
    return subject;
}

/** POST Model with primary key */
- (nonnull RACSignal *) createOne:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    
    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSError *error = nil;
        [db executeUpdate:[self sqlForCreateOneWithParam:param] withErrorAndBindings:&error];
        if (!error) {
            [subject sendNext:nil];
            [subject sendCompleted];
        }
        else {
            *rollback = YES;
            [subject sendError:error];
        }
    }];
    
    return subject;
}

/** PUT Model with primary key */
- (nonnull RACSignal *) updateOne:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    
    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSAssert(param[self.primaryKey] != nil,@"必须在param找到主键的value");
        NSError *error = nil;
        [db executeUpdate:[self sqlForUpdateOneWithParam:param[self.primaryKey]] withErrorAndBindings:&error];
        if (!error) {
            [subject sendNext:nil];
            [subject sendCompleted];
        }
        else {
            *rollback = YES;
            [subject sendError:error];
        }
    }];
    
    return subject;
}

/** DELETE Model with primary key */
- (nonnull RACSignal *) destroyOne:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    
    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        id value = param[self.primaryKey];
        NSAssert(value != nil,@"必须在param找到主键的value");
        NSError *error = nil;
        [db executeUpdate:[self sqlForDeleteOneWithPrimaryKeyValue:param[self.primaryKey]] withErrorAndBindings:&error];
        if (!error) {
            [subject sendNext:nil];
            [subject sendCompleted];
        }
        else {
            *rollback = YES;
            [subject sendError:error];
        }
    }];
    
    return subject;
}

/** DELETE All Model with primary key */
- (nonnull RACSignal *) destroyAll
{
    RACSubject * subject = [RACSubject subject];
    
    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSError *error = nil;
        [db executeUpdate:[self sqlForDeleteAll] withErrorAndBindings:&error];
        if (!error) {
            [subject sendNext:nil];
            [subject sendCompleted];
        }
        else {
            *rollback = YES;
            [subject sendError:error];
        }
    }];
    
    return subject;
}


/** ORDER BY primaryKey ASC*/
- (nonnull RACSignal *) fetchAll
{
    RACSubject * subject = [RACSubject subject];
    
    return subject;
}

- (nonnull RACSignal *) fetchAllSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) columnName, ...
{
    RACSubject * subject = [RACSubject subject];
    
    return subject;
}


- (nonnull RACSignal *) fetchMultipleWith:(NSUInteger) start limit:(NSUInteger) limit soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) columnName, ...
{
    RACSubject * subject = [RACSubject subject];
    
    return subject;
}


/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWhereAllTheConditionsAreMet:(nonnull NSString * ) condition, ...
{
    RACSubject * subject = [RACSubject subject];
    
    return subject;
}


/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWhereAllTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count condtions:(nonnull NSString * ) condition, ...
{
    RACSubject * subject = [RACSubject subject];
    
    return subject;
}


/**
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' AND old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWhereAllTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) columnName condtions:(nonnull NSString * ) condition, ...
{
    RACSubject * subject = [RACSubject subject];
    
    return subject;
}


/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWherePartOfTheConditionsAreMet:(nonnull NSString * ) condition, ...
{
    RACSubject * subject = [RACSubject subject];
    
    return subject;
}


/**
 * ORDER BY primaryKey ASC
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWherePartOfTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count  condtions:(nonnull NSString * ) condition, ...
{
    RACSubject * subject = [RACSubject subject];
    
    return subject;
}


/**
 * condition: @"name = 'CJ'", @"old >= 10" => name = 'CJ' OR old >= 10
 */
- (nonnull RACSignal *) fetchMultipleWherePartOfTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) columnName condtions:(nonnull NSString * ) condition, ...
{
    RACSubject * subject = [RACSubject subject];
    
    return subject;
}

#pragma mark migration
/** 大于currentMigrationVersion将会依次执行*/
- (void) migrate:(nonnull YTXRestfulModelDBMigrationEntity *) entity
{
    [[self migrationBlocks] addObject:entity];
}

- (nonnull RACSignal *) createColumnWithStruct:(struct YTXRestfulModelDBSerializingStruct)sstruct
{
    RACSubject * subject = [RACSubject subject];
    
    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSError *error = nil;
        [db executeUpdate:[self sqlForAlterAddColumnWithStruct:sstruct] withErrorAndBindings:&error];
        if (!error) {
            [subject sendNext:nil];
            [subject sendCompleted];
        }
        else {
            *rollback = YES;
            [subject sendError:error];
        }
    }];
    
    return subject;
}

- (nonnull RACSignal *) dropColumnWithStruct:(struct YTXRestfulModelDBSerializingStruct)sstruct
{
    RACSubject * subject = [RACSubject subject];
    
    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSError *error = nil;
        [db executeUpdate:[self sqlForAlterDropColumnWithStruct:sstruct] withErrorAndBindings:&error];
        if (!error) {
            [subject sendNext:nil];
            [subject sendCompleted];
        }
        else {
            *rollback = YES;
            [subject sendError:error];
        }
    }];
    
    return subject;
}

- (nonnull RACSignal *) changeCollumnOldStruct:(struct YTXRestfulModelDBSerializingStruct) oldStruct toNewStruct:(struct YTXRestfulModelDBSerializingStruct) newStruct
{
    RACSubject * subject = [RACSubject subject];
    
    [self.fmdbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSError *error = nil;
        [db executeUpdate:[self sqlForAlterChangeColumnWithOldStruct:oldStruct newStruct:newStruct] withErrorAndBindings:&error];
        if (!error) {
            [subject sendNext:nil];
            [subject sendCompleted];
        }
        else {
            *rollback = YES;
            [subject sendError:error];
        }
    }];
    
    return subject;
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
    NSString* primaryKey = [self primaryKey];
    NSDictionary* typeMap = kObjectCTypeToSqliteTypeMap;
    
    //Attributes
    NSMutableString* columns = [NSMutableString string];
    BOOL beAssignPrimaryKey = YES;
    
    BOOL first = YES;
    for (NSValue * value in map.allValues) {
        struct YTXRestfulModelDBSerializingStruct sstruct = [YTXRestfulModelFMDBSync structWithValue:value];
        NSString* key = [NSString stringWithUTF8String:sstruct.columnName ? : sstruct.modelName];
        
        NSString* typeKey = NSStringFromClass(sstruct.objectClass);
        //TODO:外键
        if (!typeMap[map[typeKey]]) continue;
        
        if (!first) [columns appendString:@","];
        first = NO;
        
        NSString* sqlType = typeMap[sstruct.objectClass][1];
        [columns appendFormat:@"%@ %@", key, sqlType];
        if (beAssignPrimaryKey && [primaryKey isEqualToString:key]) {
            [columns appendFormat:@" PRIMARY KEY"];
            beAssignPrimaryKey = NO;
        }
        //提供默认值
        if (sstruct.defaultValue) {
            [columns appendFormat:@" DEFAULT %@", [NSString stringWithUTF8String:sstruct.defaultValue]];
        }
        else {
            //设置默认值
            if ([sqlType isEqualToString:@"INTEGER"]) {
                [columns appendFormat:@" DEFAULT 0"];
            } else if ([sqlType isEqualToString:@"REAL"]) {
                [columns appendFormat:@" DEFAULT 0.0"];
            }
        }
    }
    
    return [NSString stringWithFormat:@"CREATE VIRTUAL TABLE %@ USING fts3(%@)", tableName, columns];
}

- (nonnull NSString *) sqlForDropTable
{
    return [NSString stringWithFormat:@"DROP TABLE %@", [self tableName]];
}

- (nonnull NSString *) sqlForSelectOneWithPrimaryKeyValue:(id) value
{
    NSString * valueString = [(NSObject *)value sqliteValue];
    
    return [NSString stringWithFormat:@"SELECT 1 FROM %@ WHERE %@=%@", [self tableName], [self primaryKey], valueString];
}

- (nonnull NSString *) sqlForCreateOneWithParam:(NSDictionary *) param
{
    NSDictionary<NSString *, NSValue *> * propertyMap = [self.modelClass tableKeyPathsByPropertyKey];
    NSMutableString* columns = [NSMutableString string];
    NSMutableString* values = [NSMutableString string];
    NSDictionary* typeMap = kObjectCTypeToSqliteTypeMap;

    BOOL first = YES;
    for (NSString * key in [param allValues]) {
        id value = param[key];
        NSString * strValue = [value sqliteValue];
        NSString* typeKey = NSStringFromClass( [value class] );
        if (!typeMap[param[typeKey]] || !propertyMap[key]) continue;
        
        if (value) {
            if (!first) {
                [columns appendString:@","];
                [values appendString:@","];
            }
            first = NO;
            [columns appendString:key];
            [values appendString:strValue?strValue:@""];
        }
    }
    
    return [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", [self tableName], columns, values];
}

- (nonnull NSString *) sqlForUpdateOneWithParam:(NSDictionary *) param
{
    NSDictionary<NSString *, NSValue *> * propertyMap = [self.modelClass tableKeyPathsByPropertyKey];
    NSMutableString* updateString = [NSMutableString string];
    NSDictionary* typeMap = kObjectCTypeToSqliteTypeMap;
    NSString* primaryKey = [self primaryKey];
    
    BOOL first = YES;
    
    for (NSString* key in [param allKeys]) {
        id value = param[key];
        NSString * strValue = [value sqliteValue];
        NSString* typeKey = NSStringFromClass( [value class] );
        if (!typeMap[param[typeKey]] || !propertyMap[key]) continue;
        
        if (value) {
            if (!first) {
                [updateString appendString:@","];
            }
            first = NO;
            [updateString appendString:[NSString stringWithFormat:@"%@=%@", key, strValue]];
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
    NSDictionary* typeMap = kObjectCTypeToSqliteTypeMap;
    NSString* sqlType = typeMap[ NSStringFromClass(sstruct.objectClass) ][1];
    
    return [NSString stringWithFormat:@"ALTER TABLE %@ ADD %@ %@ %@", [self tableName], [NSString stringWithUTF8String:sstruct.columnName],
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
    NSDictionary* typeMap = kObjectCTypeToSqliteTypeMap;
    NSString* sqlType = typeMap[ NSStringFromClass(newStruct.objectClass) ][1];
    
    return [NSString stringWithFormat:@"ALTER TABLE %@ CHANGE COLUMN %@ %@ %@ %@", [self tableName], [NSString stringWithUTF8String:oldStruct.columnName], [NSString stringWithUTF8String:newStruct.columnName], sqlType,
            newStruct.defaultValue? [NSString stringWithFormat:@" DEFAULT %@", [NSString stringWithUTF8String:newStruct.defaultValue]] : @""  ];
}

- (nonnull NSString *) sqlForDeleteAll
{
    return [NSString stringWithFormat:@"DELETE FROM %@", [self tableName]];
}

- (nonnull NSString *) sqlForSelectAll
{
    return [NSString stringWithFormat:@"SELECT * FROM %@  ORDER BY %@ ASC", [self tableName], [self primaryKey]];
}

//- (nonnull NSString *) sqlForSelectMultipleWithStart:(NSNumber *) start limit:(NSNumber *) limit
//{
//    return [NSString stringWithFormat:@"SELECT * FROM %@ ", [self tableName]];
//}


#pragma mark other

- (nonnull NSString *) tableName;
{
    return NSStringFromClass(self.modelClass);
}

- (NSString *)path
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

@end
