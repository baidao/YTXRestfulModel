//
//  YTXRestfulModel+RACSupport.h
//  Pods
//
//  Created by Chuan on 4/11/16.
//
//

#import <YTXRestfulModel/YTXRestfulModel.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>

@interface YTXRestfulModel (RACSupport)

#pragma mark - remote
/** :id/comment 这种形式的时候使用GET; modelClass is MTLModel*/
- (nonnull RACSignal *) fetchRemoteForeignWithName:(nonnull NSString *)name modelClass:(nonnull Class)modelClass param:(nullable NSDictionary *)param;
/** GET */
- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param;
/** POST / PUT */
- (nonnull RACSignal *) saveRemote:(nullable NSDictionary *)param;
/** DELETE */
- (nonnull RACSignal *) destroyRemote:(nullable NSDictionary *)param;

#pragma mark - storage

- (nonnull RACSignal *) fetchStorage:(nullable NSDictionary *)param;

- (nonnull RACSignal *) saveStorage:(nullable NSDictionary *)param;
/** DELETE */
- (nonnull RACSignal *) destroyStorage:(nullable NSDictionary *)param;

- (nonnull RACSignal *) fetchStorageWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *)param;

- (nonnull RACSignal *) saveStorageWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *)param;
/** DELETE */
- (nonnull RACSignal *) destroyStorageWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *)param;

#pragma mark - db

/** GET */
- (nonnull RACSignal *) fetchDB:(nullable NSDictionary *)param;
/**
 * POST / PUT
 * 数据库不存在时创建，否则更新
 * 更新必须带主键
 */
- (nonnull RACSignal *) saveDB:(nullable NSDictionary *)param;
/** DELETE */
- (nonnull RACSignal *) destroyDB:(nullable NSDictionary *)param;
/** GET Foreign Models with primary key */
- (nonnull RACSignal *) fetchDBForeignWithModelClass:(nonnull Class<YTXRestfulModelDBSerializing>)modelClass param:(nullable NSDictionary *)param;

@end
