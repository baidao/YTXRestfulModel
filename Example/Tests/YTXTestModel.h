//
//  YTXTestModel.h
//  YTXRestfulModel
//
//  Created by Chuan on 1/25/16.
//  Copyright © 2016 caojun. All rights reserved.
//

#import <YTXRestfulModel/YTXRestfulModel.h>

@interface YTXTestModel : YTXRestfulModel

@property (nonnull, nonatomic, strong) NSNumber *keyId;
@property (nonnull, nonatomic, strong) NSNumber *userId; //可选属性为nullable 不可选为nonnull
@property (nonnull, nonatomic, strong) NSString *title;
@property (nonnull, nonatomic, strong) NSString *body;

@end

@interface YTXTestCommentModel : YTXRestfulModel

@end
