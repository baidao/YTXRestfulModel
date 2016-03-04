//
//  YTXTestModel.m
//  YTXRestfulModel
//
//  Created by Chuan on 1/25/16.
//  Copyright © 2016 caojun. All rights reserved.
//

#import "YTXTestAFNetworkingRemoteModel.h"

#import <YTXRestfulModel/AFNetworkingRemoteSync.h>

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>

@implementation YTXTestAFNetworkingRemoteModel

//可以重写init方法 改变sync的初始值

+ (instancetype) shared
{
    static YTXTestAFNetworkingRemoteModel * model;
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

+ (NSString *)primaryKey
{
    return @"keyId";
}

- (instancetype)init {
    if (self = [super init]) {
        self.remoteSync = [AFNetworkingRemoteSync syncWithPrimaryKey:[[self class] syncPrimaryKey]];
        self.remoteSync.urlHookBlock = ^NSURL * _Nonnull{
            return [NSURL URLWithString:@"http://localhost:3000/users"];
        };
    }
    return  self;
}

//mantle Transoformer
+ (MTLValueTransformer *) bodyJSONTransformer
{
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSString * body) {
        return body;
    } reverseBlock:^(NSString * body) {
        return body;
    }];
}


@end

@implementation YTXTestAFNetworkingRemoteToDoModel


@end
