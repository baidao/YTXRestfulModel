//
//  YTXTestStudentModel.m
//  YTXRestfulModel
//
//  Created by CaoJun on 16/2/25.
//  Copyright © 2016年 caojun. All rights reserved.
//

#import "YTXTestStudentModel.h"

#import <YTXRestfulModel/NSObject+YTXRestfulModelFMDBSync.h>
#import <YTXRestfulModel/YTXRestfulModelFMDBSync.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>

@implementation YTXTestStudentModel

+ (instancetype) shared
{
    static YTXTestStudentModel * model;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        model =  [[[self class] alloc] init];
    });
    return model;
}

- (instancetype)init
{
    if (self = [super init]) {
        _IQ = @"100";
    }
    return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{@"identify": @"id"};
}

+ (NSString *)primaryKey
{
    return @"identify";
}

+ (nullable NSMutableDictionary<NSString *, YTXRestfulModelDBSerializingModel *> *) tableKeyPathsByPropertyKey
{
    NSMutableDictionary<NSString *, YTXRestfulModelDBSerializingModel *> * tmpDictionary = [super tableKeyPathsByPropertyKey];
    
    YTXRestfulModelDBSerializingModel * genderStruct = tmpDictionary[@"gender"];
    genderStruct.defaultValue = [@(GenderFemale) sqliteValue];
    tmpDictionary[@"gender"] = genderStruct;
    
    YTXRestfulModelDBSerializingModel * scoreStruct = tmpDictionary[@"score"];
    scoreStruct.unique = YES;
    tmpDictionary[@"score"] = scoreStruct;
    
    YTXRestfulModelDBSerializingModel * teacherIdStruct = tmpDictionary[@"teacherId"];
    teacherIdStruct.defaultValue = [@1 sqliteValue];
    teacherIdStruct.foreignClassName = @"YTXTestTeacherModel";
    tmpDictionary[@"teacherId"] = teacherIdStruct;
    
    return tmpDictionary;
}

+ (nullable NSNumber *) currentMigrationVersion
{
    return @0;
}

+ (BOOL) autoAlterTable
{
    return NO;
}

+ (BOOL) autoCreateTable
{
    return YES;
}

+ (void) migrationsMethodWithSync:(nonnull id<YTXRestfulModelDBProtocol>)sync;
{
    YTXRestfulModelDBMigrationEntity *migration = [YTXRestfulModelDBMigrationEntity new];
    migration.version = @1;
    migration.block = ^(_Nonnull id db, NSError * _Nullable * _Nullable error) {
        YTXRestfulModelDBSerializingModel *runtimePStruct = [YTXRestfulModelDBSerializingModel new];
        runtimePStruct.objectClass = @"NSString";
        runtimePStruct.columnName = @"runtimeP";
        runtimePStruct.modelName = @"runtimeP";
        runtimePStruct.isPrimaryKey = NO;
        runtimePStruct.autoincrement = NO;
        runtimePStruct.unique = NO;
        [sync createColumnWithDB:db structSync:runtimePStruct error:error];
    };
    [sync migrate:migration];
}

+ (MTLValueTransformer *)startSchoolDateJSONTransformer {
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSNumber *timestamp) {
        return [NSDate dateWithTimeIntervalSince1970: timestamp.longLongValue / 1000];
    } reverseBlock:^(NSDate *date) {
        return @((SInt64)(date.timeIntervalSince1970 * 1000));
    }];
}

+ (MTLValueTransformer *)birthdayJSONTransformer {
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSNumber *timestamp) {
        return [NSDate dateWithTimeIntervalSince1970: timestamp.longLongValue / 1000];
    } reverseBlock:^(NSDate *date) {
        return @((SInt64)(date.timeIntervalSince1970 * 1000));
    }];
}

+ (nullable NSNumber *) newMigrationVersion
{
    return @1;
}

@end
