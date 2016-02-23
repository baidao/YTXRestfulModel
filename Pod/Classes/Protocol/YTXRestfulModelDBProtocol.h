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

/** NSSet<YTXRestfulModelDBSerializingStruct>  */
+ (nullable NSDictionary *) tableKeyPathsByPropertyKey;

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
- (nonnull RACSignal *) fetch:(nullable NSDictionary *)param;

/** POST Model with primary key */
- (nonnull RACSignal *) create:(nullable NSDictionary *)param;

/** PUT Model with primary key */
- (nonnull RACSignal *) update:(nullable NSDictionary *)param;

/** DELETE Model with primary key */
- (nonnull RACSignal *) destroy:(nullable NSDictionary *)param;

/** GET Foreign Model with primary key */
- (nonnull RACSignal *) fetchForeignModelWithName:(nonnull NSString *)foreignName param:(nullable NSDictionary *)param;

/** GET Models {@"name": @"= CJ", @"old":">= 10"}*/
- (nonnull RACSignal *) fetchModelsWithConditionOfKeyValue:(nullable NSDictionary *) dictionary;

/** GET Models {@"name": @"= CJ", @"old":">= 10"}*/
- (nonnull RACSignal *) fetchModelsWithConditionOfKeyValue:(nullable NSDictionary *) dictionary start:(NSUInteger) start limit:(NSUInteger) limit;


//Migration

/** 数字越大越后面执行*/

/** 返回当前版本*/
@property (nonatomic, strong, readonly, nonnull) NSArray * migrationBlocks;

/** 大于currentMigrationVersion将会依次执行，数字越大越后执行*/
- (void) migrate:(nonnull YTXRestfulModelDBMigrationEntity *) entity;

- (nonnull RACSignal *) createColumnWithStruct:(struct YTXRestfulModelDBSerializingStruct)sstruct;

- (nonnull RACSignal *) dropColumnWithStruct:(struct YTXRestfulModelDBSerializingStruct)sstruct;

- (nonnull RACSignal *) changeCollumnOldStruct:(struct YTXRestfulModelDBSerializingStruct) oldStruct toNewStruct:(struct YTXRestfulModelDBSerializingStruct) newStruct;

@optional

@end
