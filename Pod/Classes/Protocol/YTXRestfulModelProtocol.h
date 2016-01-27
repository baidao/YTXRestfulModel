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

/** 设置网络请求的地址 */
- (void)setRemoteSyncUrl:(nonnull NSURL *)url;
/** 设置网络请求的地址，通过Block形式，每次访问都会重新执行，以处理shared中URL会变的情况。同时使用URL和URLBlock会优先使用Block */
- (void)setRemoteSyncUrlBlock:(nonnull NSURL * _Nonnull (^)(void))urlBlock;
/** 需要告诉我主键PrimaryKey是什么 */
- (nonnull NSString *) primaryKey;
/** 要用keyId判断 */
- (BOOL) isNew;


@end
