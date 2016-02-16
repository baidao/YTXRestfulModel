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

/* reset **/
- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param;

/** 注入自己时使用 */
- (nonnull instancetype) removeAllModels;

- (nonnull instancetype) resetModels:(nonnull NSArray *) array;

- (nonnull instancetype) addModels:(nonnull NSArray *) array;

- (nonnull instancetype) insertFrontModels:(nonnull NSArray *) array;

/** 主键可能是NSNumber或NSString，统一转成NSString来判断*/
- (nullable YTXRestfulModel *) modelWithPrimaryKey:(nonnull NSString *) primaryKey;

- (BOOL) addModel:(nonnull YTXRestfulModel *) model;

- (BOOL) insertFrontModel:(nonnull YTXRestfulModel *) model;

/** 插入到index之后*/
- (BOOL) insertModel:(nonnull YTXRestfulModel *) model afterIndex:(NSInteger) index;

/** 插入到index之前*/
- (BOOL) insertModel:(nonnull YTXRestfulModel *) model beforeIndex:(NSInteger) index;

- (BOOL) removeModelAtIndex:(NSInteger) index;

/** 主键可能是NSNumber或NSString，统一转成NSString来判断*/
- (BOOL) removeModelWithPrimaryKey:(nonnull NSString *) primaryKey;

- (BOOL) removeModelWithModel:(nonnull YTXRestfulModel *) model;

@end
