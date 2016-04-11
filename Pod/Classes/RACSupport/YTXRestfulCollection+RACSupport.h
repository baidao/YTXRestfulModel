//
//  YTXRestfulCollection+RACSupport.h
//  Pods
//
//  Created by Chuan on 4/11/16.
//
//

#import <YTXRestfulModel/YTXRestfulCollection.h>

@interface YTXRestfulCollection (RACSupport)

/* RACSignal return self **/
- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param;

/* RACSignal return self **/
- (nonnull RACSignal *) fetchRemoteThenAdd:(nullable NSDictionary *)param;


/** GET */
- (nonnull RACSignal *) fetchStorage:(nullable NSDictionary *)param;

/** POST / PUT */
- (nonnull RACSignal *) saveStorage:(nullable NSDictionary *)param;

/** DELETE */
- (nonnull RACSignal *) destroyStorage:(nullable NSDictionary *)param;

/** GET */
- (nonnull RACSignal *) fetchStorageWithKey:(nonnull NSString *)storageKey param:(nullable NSDictionary *)param;

/** POST / PUT */
- (nonnull RACSignal *) saveStorageWithKey:(nonnull NSString *)storageKey param:(nullable NSDictionary *)param;

/** DELETE */
- (nonnull RACSignal *) destroyStorageWithKey:(nonnull NSString *)storageKey param:(nullable NSDictionary *)param;
@end
