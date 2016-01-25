//
//  YTXRestfulModelRemoteSync.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import "YTXRestfulModelYTXRequestRemoteProtocol.h"

#import <Foundation/Foundation.h>

@interface YTXRestfulModelYTXRequestRemoteSync : NSObject <YTXRestfulModelRemoteProtocol>

@property (nonnull, nonatomic, strong) NSURL * url;

@property (nonnull, nonatomic, copy) NSString * primaryKey;

- (nonnull NSURL *) setupUrlWithPathNameOfYTXRequestJSON:(nonnull NSString * )pathName;

/** GET :id/comment */
- (nonnull RACSignal *) fetchRemoteForeignWithName:(nonnull NSString *)name param:(nullable NSDictionary *)param;

/** GET */
- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param;

/** POST */
- (nonnull RACSignal *) createRemote:(nullable NSDictionary *)param;

/** PUT */
- (nonnull RACSignal *) updateRemote:(nullable NSDictionary *)param;

/** DELETE */
- (nonnull RACSignal *) destroyRemote:(nullable NSDictionary *)param;

@end
