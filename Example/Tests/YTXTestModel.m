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

+ (instancetype) shared
{
    static YTXTestModel * model;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        model =  [[[self class] alloc] init];
    });
    return model;
}

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
        self.remoteSync.urlHookBlock = ^NSURL * _Nonnull{
            return [YTXRequest urlWithName:@"restful.posts"];
        };
    }
    return  self;
}

@end

@implementation YTXTestCommentModel

@end
