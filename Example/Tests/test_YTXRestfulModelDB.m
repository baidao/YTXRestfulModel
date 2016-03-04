//
//  test_YTXRestfulModelDB.m
//  YTXRestfulModel
//
//  Created by CaoJun on 16/2/25.
//  Copyright © 2016年 caojun. All rights reserved.
//

#import "YTXTestYTXRequestRemoteModel.h"
#import "YTXTestStudentModel.h"
#import "YTXTestTeacherModel.h"
#import "YTXTestStudentCollection.h"

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
            NSDictionary<NSString *, YTXRestfulModelDBSerializingModel *> * studentTableKeyPath = [YTXTestStudentModel tableKeyPathsByPropertyKey];

            NSDictionary<NSString *, YTXRestfulModelDBSerializingModel *> * humanTableKeyPath = [YTXTestHumanModel tableKeyPathsByPropertyKey];
            [[humanTableKeyPath[@"gender"] should] beNil];

            YTXRestfulModelDBSerializingModel * idStruct = studentTableKeyPath[@"id"];
            [[idStruct should] beNonNil];
            [[idStruct.objectClass should] equal:@"NSNumber"];
            [[idStruct.columnName should] equal:@"id"];
            [[idStruct.modelName should] equal:@"identify"];
            [[@(idStruct.defaultValue == nil) should] equal:@YES];
            [[@(idStruct.isPrimaryKey) should] equal:@YES];
            [[@(idStruct.autoincrement) should] equal:@YES];

            
            YTXRestfulModelDBSerializingModel * friendNamesStruct = studentTableKeyPath[@"friendNames"];
            [[friendNamesStruct should] beNonNil];
            
            [[friendNamesStruct.objectClass should] equal:@"NSArray"];
            [[friendNamesStruct.columnName should] equal:@"friendNames"];
            [[friendNamesStruct.modelName should] equal:@"friendNames"];
            [[@(friendNamesStruct.defaultValue == nil) should] equal:@YES];
            [[@(friendNamesStruct.isPrimaryKey) should] equal:@NO];
            [[@(friendNamesStruct.autoincrement) should] equal:@NO];
            
            YTXRestfulModelDBSerializingModel * genderStruct = studentTableKeyPath[@"gender"];
            [[genderStruct should] beNonNil];
            [[genderStruct.objectClass should] equal:@"Q"];
            [[genderStruct.columnName should] equal:@"gender"];
            [[genderStruct.modelName should] equal:@"gender"];
            [[genderStruct.defaultValue should] equal:@"1"];
            [[@(genderStruct.isPrimaryKey) should] equal:@NO];
            [[@(genderStruct.autoincrement) should] equal:@NO];
            
            YTXRestfulModelDBSerializingModel * pointStruct = studentTableKeyPath[@"point"];
            [[pointStruct should] beNonNil];
            [[pointStruct.objectClass should] equal:@"CGPoint"];
            [[pointStruct.columnName should] equal:@"point"];
            [[pointStruct.modelName should] equal:@"point"];
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

            NSDictionary<NSString *, YTXRestfulModelDBSerializingModel *> * studentTableKeyPath = [YTXTestStudentModel tableKeyPathsByPropertyKey];

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
        
        it(@"删除数据库记录", ^{
            YTXTestTeacherModel *testTeacherTwo = [YTXTestTeacherModel new];
            testTeacherTwo.identify = @2;
            
            NSError * error;
            [testTeacherTwo destroyDBSync:nil error:&error];
            [[error should] beNil];
            
            [testTeacherTwo fetchDBSync:nil error:&error];
            [[error should] beNonNil];
        });
    });
    
    context(@"异步方法", ^{
        __block NSNumber * studentDacula = nil;
        
        it(@"增加INSERT", ^{
            YTXTestStudentModel *testStudent = [YTXTestStudentModel new];
            testStudent.name = @"Dacula";
            
            __block YTXTestStudentModel *ret;
            [[testStudent saveDB:nil] subscribeNext:^(id x) {
                ret = x;
                studentDacula = ret.identify;
            }];
            
            [[expectFutureValue(ret) shouldEventually] equal:testStudent];
            [[expectFutureValue(studentDacula) shouldEventually] beNonNil];
        });
        
        it(@"查询SELECT", ^{
            YTXTestStudentModel *testStudent = [YTXTestStudentModel new];
            testStudent.identify = studentDacula;
            
            __block YTXTestStudentModel *ret;
            [[testStudent fetchDB:nil] subscribeNext:^(id x) {
                ret = x;
            }];
            
            [[expectFutureValue(ret) shouldEventually] equal:testStudent];
            [[expectFutureValue(ret.identify) shouldEventually] equal:studentDacula];
            [[expectFutureValue(ret.name) shouldEventually] equal:@"Dacula"];
        });
        
        it(@"修改UPDATE", ^{
            YTXTestStudentModel *testStudent = [YTXTestStudentModel new];
            testStudent.identify = studentDacula;
            testStudent.age = 99999;
            
            __block YTXTestStudentModel *ret;
            [[testStudent saveDB:nil] subscribeNext:^(id x) {
                ret = x;
            }];
            
            [[expectFutureValue(ret) shouldEventually] equal:testStudent];
            [[expectFutureValue(ret.identify) shouldEventually] equal:studentDacula];
            [[expectFutureValue(ret.name) shouldEventually] equal:@"Dacula"];
            [[expectFutureValue(@(ret.age)) shouldEventually] equal:@99999];
        });
        
        it(@"删除DELETE", ^{
            YTXTestStudentModel *testStudent = [YTXTestStudentModel new];
            testStudent.identify = studentDacula;
            
            __block BOOL ret;
            [[testStudent destroyDB:nil] subscribeNext:^(id x) {
                ret = x;
            }];
            
            [[expectFutureValue(@(ret)) shouldEventually] equal:@YES];
        });
    });
    
    context(@"collection同步方法", ^{
        beforeAll(^{
            YTXTestStudentModel * studentOne = [YTXTestStudentModel new];
            studentOne.name = @"Yahhh";
            studentOne.score = 4;
            
            YTXTestStudentModel * studentTwo = [YTXTestStudentModel new];
            studentTwo.name = @"YTX";
            studentTwo.score = 325;
            
            NSError * error;
            [studentOne saveDBSync:nil error:&error];
            [studentTwo saveDBSync:nil error:&error];
        });
        
        it(@"取所有数据", ^{
            YTXTestStudentCollection *studentCollection = [YTXTestStudentCollection new];
            NSError * error;
            [studentCollection fetchDBSyncAllWithError:&error];
            [[error should] beNil];
            [[@(studentCollection.models.count > 0) should] equal:@YES];
        });
        
        it(@"取所有数据并按score降序排序", ^{
            YTXTestStudentCollection *studentCollection = [YTXTestStudentCollection new];
            NSError * error;
            [studentCollection fetchDBSyncAllWithError:&error soryBy:YTXRestfulModelDBSortByDESC orderBy:@"score", nil];
            [[error should] beNil];
            [[@(studentCollection.models.count > 0) should] equal:@YES];
            for (int i = 0; i < studentCollection.models.count - 1; i++) {
                [[@(((YTXTestStudentModel *)studentCollection.models[i]).score > ((YTXTestStudentModel *)studentCollection.models[i + 1]).score) should] equal:@YES];
            }
        });
        
        it(@"从跳过2条数据开始取3条数据，按主键顺序排序", ^{
            YTXTestStudentCollection *studentCollection = [YTXTestStudentCollection new];
            NSError * error;
            [studentCollection fetchDBSyncMultipleWithError:&error start:2 count:3 soryBy:YTXRestfulModelDBSortByASC orderBy:[YTXTestStudentModel syncPrimaryKey], nil];
            [[error should] beNil];
            [[((YTXTestStudentModel *)studentCollection.models[0]).identify should] equal:@3];
            [[@(studentCollection.models.count == 3) should] equal:@YES];
        });
        
        it(@"多条件查询数据IQ='100' score>=10", ^{
            YTXTestStudentCollection *studentCollection = [YTXTestStudentCollection new];
            NSError * error;
            [studentCollection fetchDBSyncMultipleWithError:&error whereAllTheConditionsAreMet:[YTXRestfulModelFMDBSync sqliteStringWhere:@"IQ" equal:@100], [YTXRestfulModelFMDBSync sqliteStringWhere:@"score" greatThanOrEqaul:@10], [YTXRestfulModelFMDBSync sqliteStringWhere:@"name" like:@"Y%"], nil];
            [[error should] beNil];
            for (YTXTestStudentModel *student in studentCollection.models) {
                [[student.IQ should] equal:@"100"];
                [[student.name should] equal:@"YTX"];
                [[@(student.score >= 10) should] equal:@YES];
            }
        });
        
        it(@"查询IQ='100' score>=10，并按score倒序排序", ^{
            YTXTestStudentCollection *studentCollection = [YTXTestStudentCollection new];
            NSError * error;
            [studentCollection fetchDBSyncMultipleWithError:&error whereAllTheConditionsAreMetWithSoryBy:YTXRestfulModelDBSortByDESC orderBy:@"score" conditions:@"IQ = '100'", @"score >= 10", nil];
            [[error should] beNil];
            for (int i = 0; i < studentCollection.models.count - 1; i++) {
                [[((YTXTestStudentModel *)studentCollection.models[i]).IQ should] equal:@"100"];
                [[@(((YTXTestStudentModel *)studentCollection.models[i]).score >= 10) should] equal:@YES];
                [[@(((YTXTestStudentModel *)studentCollection.models[i]).score > ((YTXTestStudentModel *)studentCollection.models[i + 1]).score) should] equal:@YES];
            }
        });
        
        it(@"查询IQ='100' score>=10，并按score倒序排序，从第三行开始查两个", ^{
            YTXTestStudentCollection *studentCollection = [YTXTestStudentCollection new];
            NSError * error;
            [studentCollection fetchDBSyncMultipleWithError:&error whereAllTheConditionsAreMetWithStart:2 count:2 soryBy:YTXRestfulModelDBSortByDESC orderBy:@"score" conditions:@"IQ = '100'", @"score >= 10", nil];
            [[error should] beNil];
            [[@(studentCollection.models.count == 2) should] equal:@YES];
            for (int i = 0; i < studentCollection.models.count - 1; i++) {
                [[((YTXTestStudentModel *)studentCollection.models[i]).IQ should] equal:@"100"];
                [[@(((YTXTestStudentModel *)studentCollection.models[i]).score >= 10) should] equal:@YES];
                [[@(((YTXTestStudentModel *)studentCollection.models[i]).score > ((YTXTestStudentModel *)studentCollection.models[i + 1]).score) should] equal:@YES];
            }
        });
        
        it(@"查询部分满足条件", ^{
            YTXTestStudentCollection *studentCollection = [YTXTestStudentCollection new];
            NSError * error;
            [studentCollection fetchDBSyncMultipleWithError:&error wherePartOfTheConditionsAreMet:[YTXRestfulModelFMDBSync sqliteStringWhere:@"IQ" equal:@100], @"score >= 10", [YTXRestfulModelFMDBSync sqliteStringWhere:@"name" like:@"Yah%"], nil];
            [[error should] beNil];
            for (YTXTestStudentModel *student in studentCollection.models) {
                [[@(student.score >= 10 || [student.IQ isEqualToString:@"100"] || [student.name isEqualToString:@"Yahhh"]) should] equal:@YES];
            }
        });
        
        it(@"查询部分满足 IQ='100' OR score>=10，并按score升序排序", ^{
            YTXTestStudentCollection *studentCollection = [YTXTestStudentCollection new];
            NSError * error;
            [studentCollection fetchDBSyncMultipleWithError:&error wherePartOfTheConditionsAreMetWithSoryBy:YTXRestfulModelDBSortByASC orderBy:@"score" conditions:@"IQ = '100'", @"score >= 10", nil];
            [[error should] beNil];
            for (int i = 0; i < studentCollection.models.count - 1; i++) {
                [[@(((YTXTestStudentModel *)studentCollection.models[i]).score >= 10 || [((YTXTestStudentModel *)studentCollection.models[i]).IQ isEqualToString:@"100"] ) should] equal:@YES];
                [[@(((YTXTestStudentModel *)studentCollection.models[i]).score < ((YTXTestStudentModel *)studentCollection.models[i + 1]).score) should] equal:@YES];
            }
        });
        
        it(@"查询部分满足 IQ='100' OR score>=10，并按score升序排序，从第零行开始查三个", ^{
            YTXTestStudentCollection *studentCollection = [YTXTestStudentCollection new];
            NSError * error;
            [studentCollection fetchDBSyncMultipleWithError:&error wherePartOfTheConditionsAreMetWithStart:0 count:3 soryBy:YTXRestfulModelDBSortByASC orderBy:@"score" conditions:@"IQ = '100'", @"score >= 10", nil];
            [[error should] beNil];
            [[@(studentCollection.models.count == 3) should] equal:@YES];
            for (int i = 0; i < studentCollection.models.count - 1; i++) {
                [[((YTXTestStudentModel *)studentCollection.models[i]).IQ should] equal:@"100"];
                [[@(((YTXTestStudentModel *)studentCollection.models[i]).score >= 10 || [((YTXTestStudentModel *)studentCollection.models[i]).IQ isEqualToString:@"100"] ) should] equal:@YES];
                [[@(((YTXTestStudentModel *)studentCollection.models[i]).score < ((YTXTestStudentModel *)studentCollection.models[i + 1]).score) should] equal:@YES];
            }
        });
    });

    afterAll(^{
        YTXRestfulModelFMDBSync * studentSync = [YTXRestfulModelFMDBSync syncWithModelOfClass:[YTXTestStudentModel class] primaryKey:@"id"];
        [studentSync dropTable];
        YTXRestfulModelFMDBSync * teacherSync = [YTXRestfulModelFMDBSync syncWithModelOfClass:[YTXTestTeacherModel class] primaryKey:@"id"];
        [teacherSync dropTable];
    });

});

SPEC_END
