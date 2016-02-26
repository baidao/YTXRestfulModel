//
//  test_YTXRestfulModelDB.m
//  YTXRestfulModel
//
//  Created by CaoJun on 16/2/25.
//  Copyright © 2016年 caojun. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "YTXTestModel.h"
#import "YTXTestStudentModel.h"

SPEC_BEGIN(TestYTXRestfulModelFMDBSync)

describe(@"测试TestYTXRestfulModelFMDBSync", ^{
    context(@"初始化", ^{
        it(@"创建model和sync", ^{
            YTXTestStudentModel * student = [YTXTestStudentModel new];
            [[student should] beNonNil];
        });
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
