//
//  test_YTXRestfulModelDB.m
//  YTXRestfulModel
//
//  Created by CaoJun on 16/2/25.
//  Copyright © 2016年 caojun. All rights reserved.
//

#import "YTXTestModel.h"
#import "YTXTestStudentModel.h"
#import "YTXTestTeacherModel.h"

#import <YTXRestfulModel/YTXRestfulModelDBProtocol.h>
#import <YTXRestfulModel/YTXRestfulModelFMDBSync.h>
#import <Kiwi/Kiwi.h>
#import <FMDB/FMDB.h>

SPEC_BEGIN(TestYTXRestfulModelFMDBSync)

describe(@"测试TestYTXRestfulModelFMDBSync", ^{
    __block FMDatabaseQueue *dbQueue = [FMDatabaseQueue databaseQueueWithPath:[YTXRestfulModelFMDBSync path]];

    context(@"初始化", ^{
        it(@"确认主键，表名", ^{
            YTXTestStudentModel * student = [YTXTestStudentModel new];
            [[[student.dbSync tableName] should] beNonNil];
            [[[student.dbSync primaryKey] should] beNonNil];
        });

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
            [[friendNamesValue should] beNonNil];
            struct YTXRestfulModelDBSerializingStruct friendNamesStruct = [YTXRestfulModelFMDBSync structWithValue:friendNamesValue];
            [[[NSString stringWithUTF8String:friendNamesStruct.objectClass] should] equal:@"NSArray"];
            [[[NSString stringWithUTF8String:friendNamesStruct.columnName] should] equal:@"friendNames"];
            [[[NSString stringWithUTF8String:friendNamesStruct.modelName] should] equal:@"friendNames"];
            [[@(friendNamesStruct.defaultValue == nil) should] equal:@YES];
            [[@(friendNamesStruct.isPrimaryKey) should] equal:@NO];
            [[@(friendNamesStruct.autoincrement) should] equal:@NO];

            NSValue * genderValue = studentTableKeyPath[@"gender"];
            [[genderValue should] beNonNil];
            struct YTXRestfulModelDBSerializingStruct genderStruct = [YTXRestfulModelFMDBSync structWithValue:genderValue];
            [[[NSString stringWithUTF8String:genderStruct.objectClass] should] equal:@"Q"];
            [[[NSString stringWithUTF8String:genderStruct.columnName] should] equal:@"gender"];
            [[[NSString stringWithUTF8String:genderStruct.modelName] should] equal:@"gender"];
            [[[NSString stringWithUTF8String:genderStruct.defaultValue] should] equal:@"1"];
            [[@(genderStruct.isPrimaryKey) should] equal:@NO];
            [[@(genderStruct.autoincrement) should] equal:@NO];

            NSValue * pointValue = studentTableKeyPath[@"point"];
            [[pointValue should] beNonNil];
            struct YTXRestfulModelDBSerializingStruct pointStruct = [YTXRestfulModelFMDBSync structWithValue:pointValue];
            [[[NSString stringWithUTF8String:pointStruct.objectClass] should] equal:@"CGPoint"];
            [[[NSString stringWithUTF8String:pointStruct.columnName] should] equal:@"point"];
            [[[NSString stringWithUTF8String:pointStruct.modelName] should] equal:@"point"];
            [[@(pointStruct.defaultValue == nil) should] equal:@YES];
            [[@(pointStruct.isPrimaryKey) should] equal:@NO];
            [[@(pointStruct.autoincrement) should] equal:@NO];
        });

        it(@"查看数据库表Columns", ^{
            YTXTestStudentModel * student = [YTXTestStudentModel new];
            __block NSDictionary *columns;
            [dbQueue inDatabase:^(FMDatabase *db) {
                NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@", [student.dbSync tableName]];
                FMResultSet* rs = [db executeQuery:sql];
                columns = [[rs columnNameToIndexMap] copy];
            }];

            [[columns[@"id"] should] beNonNil];
            [[columns[@"identify"] should] beNil];
            [[columns[@"name"] should] beNonNil];
            [[columns[@"birthday"] should] beNonNil];
            [[columns[@"iq"] should] beNonNil];
            [[columns[@"friendnames"] should] beNonNil];
            [[columns[@"properties"] should] beNonNil];
            [[columns[@"startschooldate"] should] beNonNil];
            [[columns[@"age"] should] beNonNil];
            [[columns[@"stupid"] should] beNonNil];
            [[columns[@"floatnumber"] should] beNonNil];
            [[columns[@"gender"] should] beNonNil];
            [[columns[@"score"] should] beNonNil];
            [[columns[@"point"] should] beNonNil];

            NSDictionary<NSString *, NSValue *> * studentTableKeyPath = [YTXTestStudentModel tableKeyPathsByPropertyKey];

            for (NSString *key in studentTableKeyPath) {
                [[columns[[key lowercaseString]] should] beNonNil];
            }
        });
    });

    context(@"同步方法", ^{
        __block NSNumber * studentJack = nil;
        
        __block NSDate * brithday = [NSDate dateWithTimeIntervalSince1970:1456819975];
        
        __block NSDate * startSchoolDate = [NSDate dateWithTimeIntervalSince1970:1456821585];
        
        it(@"存入DB包含所有属性", ^{
            YTXTestStudentModel * student = [YTXTestStudentModel new];
            
            student.name = @"Jack";
            student.birthday = brithday;
            student.friendNames = @[@"Jack", @"Jarray"];
            student.properties = @{
                                   @"eye": @2
                                   };
            student.startSchoolDate = startSchoolDate;
            student.age = 16;
            student.stupid = NO;
            student.floatNumber = 15.6;
            student.gender = GenderMale;
            student.score = 100.0;
            student.point = CGPointMake(15.5, 15.5);
            
            NSError * error;
            [student saveDBSync:nil error:&error];
            
            studentJack = student.identify;
            
            [[error should] beNil];
        });

        it(@"通过设置id查询到并且类型值正确", ^{
            YTXTestStudentModel * student = [YTXTestStudentModel new];
            student.identify = studentJack;
            NSError * error;
            [student fetchDBSync:nil error:&error];

            [[student.identify should] beNonNil];
            [[error should] beNil];
            
            [[student.name should] equal:@"Jack"];
            [[@(student.birthday.timeIntervalSince1970) should] equal:@(brithday.timeIntervalSince1970)];
            [[student.friendNames should] equal:@[@"Jack", @"Jarray"]];
            [[student.properties should] equal:@{ @"eye": @2 }];
            [[student.IQ should] equal:@"100"];
            [[@(student.startSchoolDate.timeIntervalSince1970) should] equal:@(startSchoolDate.timeIntervalSince1970)];
            [[@(student.age) should] equal:@16];
            [[@(student.stupid) should] equal:@NO];
            [[@(student.floatNumber) should] equal:[NSNumber numberWithFloat:15.6]];
            [[@(student.gender) should] equal:@(GenderMale)];
            [[@(student.score) should] equal:@100.0];
            [[@(student.point.x) should] equal:@15.5];
            [[@(student.point.y) should] equal:@15.5];
        });

        it(@"通过参数里的id查询到", ^{
            YTXTestStudentModel * student1 = [YTXTestStudentModel new];
            YTXTestStudentModel * student2 = [YTXTestStudentModel new];
            NSError * error1;
            NSError * error2;
            //id为colunmName
            [student1 fetchDBSync:@{ @"id": studentJack } error:&error1];

            [[student1.identify should] beNonNil];
            [[error1 should] beNil];
            [[student1.name should] equal:@"Jack"];
            [[@(student1.age) should] equal:@16];

            [student2 fetchDBSync:@{ @"identify": studentJack } error:&error2];

            [[student2.identify should] beNonNil];
            [[error2 should] beNil];
            [[student2.name should] equal:@"Jack"];
            [[@(student2.age) should] equal:@16];
        });
        
        it(@"更新StudentModel", ^{
            YTXTestStudentModel * studentOrigin = [YTXTestStudentModel new];
            
            //有了主键之后是更新操作
            studentOrigin.identify = studentJack;
            studentOrigin.name = @"Jack.Tom";
            studentOrigin.birthday = [brithday dateByAddingTimeInterval:60];
            studentOrigin.friendNames = @[@"Jack"];
            studentOrigin.age = 17;
            studentOrigin.stupid = YES;
            studentOrigin.floatNumber = 21.6;
            studentOrigin.gender = GenderFemale;
            studentOrigin.score = 60;
            studentOrigin.point = CGPointMake(6.5, 5);
            
            NSError * error;
            [studentOrigin saveDBSync:@{
                                        @"properties" : @{
                                             @"eye": @2,
                                             @"leg": @2
                                             },
                                        @"startSchoolDate": @([startSchoolDate dateByAddingTimeInterval:60].timeIntervalSince1970 * 1000)
                                        } error:&error];
            
            YTXTestStudentModel * studentNew = [YTXTestStudentModel new];
            studentNew.identify = studentJack;
            
            [studentNew fetchDBSync:nil error:&error];
            
            [[studentNew.identify should] beNonNil];
            [[error should] beNil];
            
            [[studentNew.name should] equal:@"Jack.Tom"];
            [[@(studentNew.birthday.timeIntervalSince1970) should] equal:@(brithday.timeIntervalSince1970+60)];
            [[studentNew.friendNames should] equal:@[@"Jack"]];
            [[studentNew.properties should] equal:@{ @"eye": @2,  @"leg": @2 }];
            [[studentNew.IQ should] equal:@"100"];
            [[@(studentNew.startSchoolDate.timeIntervalSince1970) should] equal:@(startSchoolDate.timeIntervalSince1970+60)];
            [[@(studentNew.age) should] equal:@17];
            [[@(studentNew.stupid) should] equal:@YES];
            [[@(studentNew.floatNumber) should] equal:[NSNumber numberWithFloat:21.6]];
            [[@(studentNew.gender) should] equal:@(GenderFemale)];
            [[@(studentNew.score) should] equal:@60.0];
            [[@(studentNew.point.x) should] equal:@6.5];
            [[@(studentNew.point.y) should] equal:@5];
        });
        
        it(@"确认unique是否正确", ^{
            YTXTestStudentModel * studentOne = [YTXTestStudentModel new];
            studentOne.name = @"Mary";
            studentOne.score = 159;
            YTXTestStudentModel * studentTwo = [YTXTestStudentModel new];
            studentTwo.name = @"Jack";
            studentTwo.score = 159;
            
            NSError * error;
            [studentOne saveDBSync:nil error:&error];
            [[error should] beNil];
            [studentTwo saveDBSync:nil error:&error];
            [[error should] beNonNil];
        });

        it(@"确认DefaultValue是否正确", ^{
            YTXTestTeacherModel *testTeacher = [YTXTestTeacherModel new];
            testTeacher.identify = @1;
            testTeacher.birthday = brithday;
    
            NSError * error;
            [testTeacher saveDBSync:nil error:&error];
            
            [[error should] beNil];
            [[testTeacher.name should] equal:@"Edward"];
        });
        
        it(@"确认自增ID", ^{
            YTXTestStudentModel * studentOne = [YTXTestStudentModel new];
            studentOne.name = @"Mary";
            studentOne.score = 10;
            YTXTestStudentModel * studentTwo = [YTXTestStudentModel new];
            studentTwo.name = @"Jack";
            studentTwo.score = 22;
            
            NSError * error;
            [studentOne saveDBSync:nil error:&error];
            [[error should] beNil];
            [studentTwo saveDBSync:nil error:&error];
            [[error should] beNil];
    
            [[@([studentOne.identify integerValue] + 1) should] equal:studentTwo.identify];
        });
        
        it(@"确认非自增ID", ^{
            YTXTestTeacherModel *testTeacher = [YTXTestTeacherModel new];
            testTeacher.identify = @1;
            testTeacher.birthday = brithday;
            YTXTestTeacherModel *testTeacherTwo = [YTXTestTeacherModel new];
            testTeacherTwo.identify = @2;
            testTeacherTwo.birthday = brithday;
            
            NSError * error;
            [testTeacher saveDBSync:nil error:&error];
            [testTeacherTwo saveDBSync:nil error:&error];
            
            [[error should] beNil];
        });
        
        it(@"查询非自增ID的数据", ^{
            
            YTXTestTeacherModel *testTeacherTwo = [YTXTestTeacherModel new];
            testTeacherTwo.identify = @2;
            
            NSError * error;
            [testTeacherTwo fetchDBSync:nil error:&error];
            
            [[error should] beNil];
            [[testTeacherTwo.birthday should] equal:@(brithday.timeIntervalSince1970)];
        });
    });

    afterAll(^{
        YTXRestfulModelFMDBSync * sync = [YTXRestfulModelFMDBSync syncWithModelOfClass:[YTXTestStudentModel class] primaryKey:@"id"];
        [sync dropTable];
    });

});

SPEC_END
