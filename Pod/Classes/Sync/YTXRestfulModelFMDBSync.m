//
//  YTXRestfulModelFMDBSync.m
//  Pods
//
//  Created by CaoJun on 16/2/22.
//
//

#import "YTXRestfulModelFMDBSync.h"
#import <FMDB/FMDatabase+FTS3.h>
#import <FMDB/FMDatabaseAdditions.h>
#import <FMDB/FMDatabaseQueue.h>
#import <objc/runtime.h>

@interface YTXRestfulModelFMDBSync()

@property (nonatomic, strong, nonnull) FMDatabase * fmdb;

@property (nonatomic, strong, nonnull) FMDatabaseQueue * fmdbQueue;

@property (nonatomic, strong, nonnull) NSMutableArray * migrationBlocks;

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
            [subject sendError:error];
        }
    }];
    
    return subject;
}

#pragma mark sql string

- (nonnull NSString *) sqlForCreatingTable
{
    NSDictionary * map =  [self.modelClass tableKeyPathsByPropertyKey];
    
    NSValue * primaryKeyStructValue = [map objectForKey:self.primaryKey];
    
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
    for (NSValue * value in map) {
        struct YTXRestfulModelDBSerializingStruct sstruct = [YTXRestfulModelFMDBSync structWithValue:value];
        NSString* key = [NSString stringWithUTF8String:sstruct.columnName ? : sstruct.modelName];
        if (!typeMap[map[key]]) continue;
        
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

- (nonnull NSString *) sqlForAlterAddColumnWithStruct:(struct YTXRestfulModelDBSerializingStruct) sstruct
{
    NSDictionary* typeMap = kObjectCTypeToSqliteTypeMap;
    NSString* sqlType = typeMap[sstruct.objectClass][1];
    
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
    NSString* sqlType = typeMap[newStruct.objectClass][1];
    
    return [NSString stringWithFormat:@"ALTER TABLE %@ CHANGE COLUMN %@ %@ %@ %@", [self tableName], [NSString stringWithUTF8String:oldStruct.columnName], [NSString stringWithUTF8String:newStruct.columnName], sqlType,
            newStruct.defaultValue? [NSString stringWithFormat:@" DEFAULT %@", [NSString stringWithUTF8String:newStruct.defaultValue]] : @""  ];
}

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

@end
