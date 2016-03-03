//
//  YTXTestSubModel.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/2/25.
//  Copyright © 2016年 caojun. All rights reserved.
//

#import "YTXTestHumanModel.h"

typedef NS_ENUM(NSUInteger, Gender) {
    GenderMale,
    GenderFemale
};

@interface YTXTestStudentModel : YTXTestHumanModel

@property (nonnull, nonatomic, strong ,readonly) NSString *IQ;
@property (nonnull, nonatomic, strong) NSArray * friendNames;
@property (nonnull, nonatomic, strong) NSDictionary * properties;
@property (nonnull, nonatomic, strong) NSDate * startSchoolDate;
@property (nonatomic, assign) NSUInteger age;
@property (nonatomic, assign) BOOL stupid;
@property (nonatomic, assign) float floatNumber;
@property (nonatomic, assign) Gender gender;
@property (nonatomic, assign) double score;
@property (nonatomic, assign) CGPoint point;

@end
