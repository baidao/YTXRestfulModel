//
//  YTXTestModel.m
//  YTXRestfulModel
//
//  Created by Chuan on 1/25/16.
//  Copyright © 2016 caojun. All rights reserved.
//

#import "YTXTestModel.h"

#import <YTXRequest/YTXRequest.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>

@implementation YTXTestModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{@"keyId": @"id"};
}

- (NSString *)primaryKey
{
    return @"keyId";
}

- (instancetype)init {
    if (self = [super init]) {
        [self setRemoteSyncUrlBlock:^NSURL * _Nonnull{
            return [YTXRequest urlWithName:@"restful.posts"];
        }];
    }
    return  self;
}

@end

@implementation YTXTestCommentModel

@end
