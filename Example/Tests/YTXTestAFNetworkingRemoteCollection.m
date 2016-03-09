//
//  YTXTestCollection.m
//  YTXRestfulModel
//
//  Created by Chuan on 1/25/16.
//  Copyright © 2016 caojun. All rights reserved.
//

#import "YTXTestAFNetworkingRemoteCollection.h"

#import <YTXRestfulModel/AFNetworkingRemoteSync.h>

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>


@implementation YTXTestAFNetworkingRemoteCollection

+ (instancetype) shared
{
    static YTXTestAFNetworkingRemoteCollection * collection;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        collection =  [[[self class] alloc] init];
    });
    return collection;
}

- (instancetype)init
{
    if (self = [super initWithModelClass: [YTXTestAFNetworkingRemoteModel class]]) {
        self.remoteSync = [AFNetworkingRemoteSync new];
        self.remoteSync.url = [NSURL URLWithString:@"http://localhost:3000/users"];
    }
    return  self;
}

- (NSArray *)transformerProxyOfResponse:(id)response {
    return [MTLJSONAdapter modelsOfClass:[self modelClass] fromJSONArray:response error:nil];
}


@end
