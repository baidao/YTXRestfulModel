//
//  YTXTestTeacherModel.m
//  YTXRestfulModel
//
//  Created by Chuan on 3/2/16.
//  Copyright © 2016 caojun. All rights reserved.
//

#import "YTXTestTeacherModel.h"
#import <YTXRestfulModel/NSObject+YTXRestfulModelFMDBSync.h>

@implementation YTXTestTeacherModel

+ (instancetype) shared
{
    static YTXTestTeacherModel * model;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        model =  [[[self class] alloc] init];
    });
    return model;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{@"identify": @"id"};
}

+ (NSString *)primaryKey
{
    return @"identify";
}

+ (nullable NSMutableDictionary<NSString *, NSValue *> *) tableKeyPathsByPropertyKey
{
    NSMutableDictionary<NSString *, NSValue *> * tmpDictionary = [[super tableKeyPathsByPropertyKey] mutableCopy];
    
    id primaryValue = [self syncPrimaryKey];
    struct YTXRestfulModelDBSerializingStruct primaryStruct = [YTXRestfulModelFMDBSync structWithValue:tmpDictionary[primaryValue]];
    primaryStruct.autoincrement = NO;
    tmpDictionary[primaryValue] = [YTXRestfulModelFMDBSync valueWithStruct:primaryStruct];
    
    struct YTXRestfulModelDBSerializingStruct nameStruct = [YTXRestfulModelFMDBSync structWithValue:tmpDictionary[@"name"]];
    nameStruct.defaultValue = [[@"Edward" sqliteValue] UTF8String];
    tmpDictionary[@"name"] = [YTXRestfulModelFMDBSync valueWithStruct:nameStruct];
    
    return tmpDictionary;
}

+ (nullable NSNumber *) currentMigrationVersion
{
    return @0;
}

+ (BOOL) autoCreateTable
{
    return YES;
}

@end
