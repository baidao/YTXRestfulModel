//
//  YTXRestfulModelProtocol.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import <Foundation/Foundation.h>

//尽量想写成Restful
@protocol YTXRestfulModelProtocol <NSObject>

@required
+ (nonnull instancetype) shared;
- (nonnull instancetype) mergeWithAnother:(_Nonnull id) model;

/** 需要告诉我主键PrimaryKey是什么 */
- (nonnull NSString *) primaryKey;
/** 要用keyId判断 */
- (BOOL) isNew;


@end
