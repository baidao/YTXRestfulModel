//
//  YTXTestHumanModel.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/2/25.
//  Copyright © 2016年 caojun. All rights reserved.
//

#import <YTXRestfulModel/YTXRestfulModel.h>

@interface YTXTestHumanModel : YTXRestfulModel

@property (nonnull, nonatomic, copy) NSNumber * identify;
@property (nonnull, nonatomic, copy) NSString * name;
@property (nonnull, nonatomic, strong) NSDate * birthday;

@end
