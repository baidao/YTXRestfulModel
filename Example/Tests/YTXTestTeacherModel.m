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
    
    struct YTXRestfulModelDBSerializingStruct nameStruct;
    
    [tmpDictionary[@"name"] getValue:&nameStruct];
    
    nameStruct.defaultValue = [[@"Edward" sqliteValue] UTF8String];
    
    tmpDictionary[@"name"] = [NSValue value:&nameStruct withObjCType:@encode(struct YTXRestfulModelDBSerializingStruct)];

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

+ (BOOL) isPrimaryKeyAutoincrement
{
    return NO;
}

@end
