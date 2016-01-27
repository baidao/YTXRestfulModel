//
//  YTXRestfulModelRemoteProtocol.h
//  YTXRestfulModel
//
//  Created by CaoJun on 16/1/25.
//  Copyright © 2016年 Elephants Financial Service. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>
#import <Foundation/Foundation.h>

@protocol YTXRestfulModelRemoteProtocol <NSObject>

@required

@property (nonnull, nonatomic, strong) NSURL * url;

@property (nonnull, nonatomic, strong) NSURL * _Nonnull (^urlBlock)(void);

@property (nonnull, nonatomic, copy, readonly) NSString * primaryKey;

+ (nonnull instancetype) syncWithURL:(nonnull NSURL *)URL primaryKey:(nonnull NSString *) primaryKey;

+ (nonnull instancetype) syncWithPrimaryKey:(nonnull NSString *) primaryKey;

- (nonnull instancetype) initWithURL:(nonnull NSURL *)URL primaryKey:(nonnull NSString *) primaryKey;

- (nonnull instancetype) initWithPrimaryKey:(nonnull NSString *) primaryKey;

/** GET :id/commont */
- (nonnull RACSignal *) fetchRemoteForeignWithName:(nonnull NSString *)name param:(nullable NSDictionary *)param;

/** GET */
- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param;

/** POST */
- (nonnull RACSignal *) createRemote:(nullable NSDictionary *)param;

/** put */
- (nonnull RACSignal *) updateRemote:(nullable NSDictionary *)param;

/** DELETE */
- (nonnull RACSignal *) destroyRemote:(nullable NSDictionary *)param;

@end
