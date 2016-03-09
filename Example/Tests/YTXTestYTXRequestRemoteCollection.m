//
//  YTXTestCollection.m
//  YTXRestfulModel
//
//  Created by Chuan on 1/25/16.
//  Copyright © 2016 caojun. All rights reserved.
//

#import "YTXTestYTXRequestRemoteCollection.h"

#import <YTXRequest/YTXRequest.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>

@implementation YTXTestYTXRequestRemoteCollection

+ (instancetype) shared
{
    static YTXTestYTXRequestRemoteCollection * collection;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        collection =  [[[self class] alloc] init];
    });
    return collection;
}

- (instancetype)init
{
    if (self = [super initWithModelClass: [YTXTestYTXRequestRemoteModel class]]) {
        self.remoteSync.url = [YTXRequest urlWithName:@"restful.posts"];
    }
    return  self;
}

- (NSArray *)transformerProxyOfResponse:(id)response {
    return [MTLJSONAdapter modelsOfClass:[self modelClass] fromJSONArray:response error:nil];
}


@end
