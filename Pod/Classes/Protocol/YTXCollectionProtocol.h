//
//  YTXCollectionProtocol.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol YTXCollectionProtocol <NSObject>

@required

+ (nonnull instancetype) shared;

@property (nonnull, nonatomic, assign) Class modelClass;
@property (nonnull, nonatomic, strong) NSMutableArray * models;

@end
