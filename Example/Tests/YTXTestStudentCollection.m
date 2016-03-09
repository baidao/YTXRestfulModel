//
//  YTXTestStudentCollection.m
//  YTXRestfulModel
//
//  Created by Chuan on 3/3/16.
//  Copyright © 2016 caojun. All rights reserved.
//

#import "YTXTestStudentCollection.h"
#import "YTXTestStudentModel.h"

#import <YTXRequest/YTXRequest.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>

@implementation YTXTestStudentCollection

+ (instancetype) shared
{
    static YTXTestStudentCollection * collection;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        collection =  [[[self class] alloc] init];
    });
    return collection;
}

- (instancetype)init
{
    if (self = [super initWithModelClass: [YTXTestStudentModel class]]) {
    }
    return  self;
}

- (NSArray *)transformerProxyOfResponse:(id)response {
    return [MTLJSONAdapter modelsOfClass:[self modelClass] fromJSONArray:response error:nil];
}

@end
