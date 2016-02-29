//
//  test_YTXRestfulModelDB.m
//  YTXRestfulModel
//
//  Created by CaoJun on 16/2/25.
//  Copyright © 2016年 caojun. All rights reserved.
//

#import "YTXTestModel.h"
#import "YTXTestStudentModel.h"

#import <YTXRestfulModel/YTXRestfulModelDBProtocol.h>
#import <YTXRestfulModel/YTXRestfulModelFMDBSync.h>
#import <Kiwi/Kiwi.h>
#import <FMDB/FMDB.h>

SPEC_BEGIN(TestYTXRestfulModelFMDBSync)

describe(@"测试TestYTXRestfulModelFMDBSync", ^{
    __block FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:[YTXRestfulModelFMDBSync path]];
    
    context(@"初始化", ^{
        it(@"创建model，创建后数据库存在", ^{
            __block BOOL ret = NO;
            YTXTestStudentModel * student = [YTXTestStudentModel new];
            [[student should] beNonNil];
            
            [dbQueue inDatabase:^(FMDatabase *db) {
                ret = [db open];
            }];
            [[@(ret) should] equal:@YES];
        });
        
        it(@"创建model，数据库建表成功", ^{
            __block BOOL ret = NO;
            YTXTestStudentModel * student = [YTXTestStudentModel new];
            
            [dbQueue inDatabase:^(FMDatabase *db) {
                ret = [db tableExists:[student.dbSync tableName]];
            }];
            [[@(ret) should] equal:@YES];
        });
        
        it(@"删除数据表", ^{
            __block BOOL ret = NO;
            YTXRestfulModelFMDBSync * sync = [YTXRestfulModelFMDBSync syncWithModelOfClass:[YTXTestStudentModel class] primaryKey:@"id"];
            [sync dropTable];
            
            [dbQueue inDatabase:^(FMDatabase *db) {
                ret = [db tableExists:[sync tableName]];
            }];
            [[@(ret) should] equal:@NO];
        });
        
        it(@"创建数据库表", ^{
            __block BOOL ret = NO;
            YTXRestfulModelFMDBSync * sync = [YTXRestfulModelFMDBSync syncWithModelOfClass:[YTXTestStudentModel class] primaryKey:@"id"];
            [sync dropTable];
            
            [sync createTable];
            
            [dbQueue inDatabase:^(FMDatabase *db) {
                ret = [db tableExists:[sync tableName]];
            }];
            [[@(ret) should] equal:@YES];
        });
        
        it(@"tableKeyPathsByPropertyKey的正确性", ^{
            NSDictionary<NSString *, NSValue *> * studentTableKeyPath = [YTXTestStudentModel tableKeyPathsByPropertyKey];
            
            NSDictionary<NSString *, NSValue *> * humanTableKeyPath = [YTXTestHumanModel tableKeyPathsByPropertyKey];
            [[humanTableKeyPath[@"gender"] should] beNil];
            
            NSValue * idValue = studentTableKeyPath[@"id"];
            [[idValue should] beNonNil];
            struct YTXRestfulModelDBSerializingStruct idStruct = [YTXRestfulModelFMDBSync structWithValue:idValue];
            [[[NSString stringWithUTF8String:idStruct.objectClass] should] equal:@"NSNumber"];
            [[[NSString stringWithUTF8String:idStruct.columnName] should] equal:@"id"];
            [[[NSString stringWithUTF8String:idStruct.modelName] should] equal:@"identify"];
            [[@(idStruct.defaultValue == nil) should] equal:@YES];
            [[@(idStruct.isPrimaryKey) should] equal:@YES];
            [[@(idStruct.autoincrement) should] equal:@YES];
            
            NSValue * friendNamesValue = studentTableKeyPath[@"friendNames"];
            [[idValue should] beNonNil];
            struct YTXRestfulModelDBSerializingStruct friendNamesStruct = [YTXRestfulModelFMDBSync structWithValue:friendNamesValue];
            [[[NSString stringWithUTF8String:friendNamesStruct.objectClass] should] equal:@"NSArray"];
            [[[NSString stringWithUTF8String:friendNamesStruct.columnName] should] equal:@"friendNames"];
            [[[NSString stringWithUTF8String:friendNamesStruct.modelName] should] equal:@"friendNames"];
            [[@(friendNamesStruct.defaultValue == nil) should] equal:@YES];
            [[@(friendNamesStruct.isPrimaryKey) should] equal:@NO];
            [[@(friendNamesStruct.autoincrement) should] equal:@NO];
            
            NSValue * genderValue = studentTableKeyPath[@"gender"];
            [[idValue should] beNonNil];
            struct YTXRestfulModelDBSerializingStruct genderStruct = [YTXRestfulModelFMDBSync structWithValue:genderValue];
            [[[NSString stringWithUTF8String:genderStruct.objectClass] should] equal:@"Q"];
            [[[NSString stringWithUTF8String:genderStruct.columnName] should] equal:@"gender"];
            [[[NSString stringWithUTF8String:genderStruct.modelName] should] equal:@"gender"];
            [[[NSString stringWithUTF8String:genderStruct.defaultValue] should] equal:@"1"];
            [[@(genderStruct.isPrimaryKey) should] equal:@NO];
            [[@(genderStruct.autoincrement) should] equal:@NO];

        });
        
        it(@"查看数据库表Columns", ^{
            YTXTestStudentModel * student = [YTXTestStudentModel new];
            
        });
    });
    
    context(@"异步方法", ^{
        it(@"存Model到DB", ^{
            YTXTestStudentModel * student = [YTXTestStudentModel new];
            student.age = 24;
            student.name = @"Jack";
            
            __block YTXTestStudentModel * ret = nil;
            [[student saveDB:nil] subscribeNext:^(id x) {
                ret = x;
            } error:^(NSError *error) {
                
            }];
            
            [[expectFutureValue(ret.identify) shouldEventually] beNonNil];
            [[expectFutureValue(ret.name) shouldEventually] equal:@"Jack"];
            [[expectFutureValue(@(ret.age)) shouldEventually] equal:@24];
        });
        
    });
    
    afterAll(^{
        YTXRestfulModelFMDBSync * sync = [YTXRestfulModelFMDBSync syncWithModelOfClass:[YTXTestStudentModel class] primaryKey:@"id"];
        [sync dropTable];
    });
    
});

SPEC_END
