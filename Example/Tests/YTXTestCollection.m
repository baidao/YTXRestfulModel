//
//  YTXTestCollection.m
//  YTXRestfulModel
//
//  Created by Chuan on 1/25/16.
//  Copyright © 2016 caojun. All rights reserved.
//

#import "YTXTestCollection.h"

#import <YTXRequest/YTXRequest.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>

@implementation YTXTestCollection

+ (instancetype) shared
{
    static YTXTestCollection * collection;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        collection =  [[[self class] alloc] init];
    });
    return collection;
}

- (instancetype)init
{
    if (self = [super initWithModelClass: [YTXTestModel class]]) {
        self.remoteSync.url = [YTXRequest urlWithName:@"restful.posts"];
    }
    return  self;
}

- (NSArray *)transformerProxyOfReponse:(id)response {
    return [MTLJSONAdapter modelsOfClass:[self modelClass] fromJSONArray:response error:nil];
}


@end
