//
//  YTXRestfulModelRemoteSync.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import "YTXRestfulModelYTXRequestRemoteProtocol.h"

#import <Foundation/Foundation.h>

@interface YTXRestfulModelYTXRequestRemoteSync : NSObject <YTXRestfulModelYTXRequestRemoteProtocol>

@property (nonnull, nonatomic, strong) NSURL * url;

- (nonnull NSURL *) setupUrlWithPathNameOfYTXRequestJSON:(nonnull NSString * )pathName;

/** GET */
- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param;

/** POST */
- (nonnull RACSignal *) createRemote:(nullable NSDictionary *)param;

/** put */
- (nonnull RACSignal *) updateRemote:(nullable NSDictionary *)param;

/** DELETE */
- (nonnull RACSignal *) destroyRemote:(nullable NSDictionary *)param;

@end
