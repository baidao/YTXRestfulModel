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
- (nonnull RACSignal *) rac_fetchRemoteForeignWithName:(nonnull NSString *)name modelClass:(nonnull Class)modelClass param:(nullable NSDictionary *)param;
/** GET */
- (nonnull RACSignal *) rac_fetchRemote:(nullable NSDictionary *)param;
/** POST / PUT */
- (nonnull RACSignal *) rac_saveRemote:(nullable NSDictionary *)param;
/** DELETE */
- (nonnull RACSignal *) rac_destroyRemote:(nullable NSDictionary *)param;

#pragma mark - storage

- (nonnull RACSignal *) rac_fetchStorage:(nullable NSDictionary *)param;

- (nonnull RACSignal *) rac_saveStorage:(nullable NSDictionary *)param;
/** DELETE */
- (nonnull RACSignal *) rac_destroyStorage:(nullable NSDictionary *)param;

- (nonnull RACSignal *) rac_fetchStorageWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *)param;

- (nonnull RACSignal *) rac_saveStorageWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *)param;
/** DELETE */
- (nonnull RACSignal *) rac_destroyStorageWithKey:(nonnull NSString *)storage param:(nullable NSDictionary *)param;

#pragma mark - db

/** GET */
- (nonnull RACSignal *) rac_fetchDB:(nullable NSDictionary *)param;
/**
 * POST / PUT
 * 数据库不存在时创建，否则更新
 * 更新必须带主键
 */
- (nonnull RACSignal *) rac_saveDB:(nullable NSDictionary *)param;
/** DELETE */
- (nonnull RACSignal *) rac_destroyDB:(nullable NSDictionary *)param;
/** GET Foreign Models with primary key */
- (nonnull RACSignal *) rac_fetchDBForeignWithModelClass:(nonnull Class<YTXRestfulModelDBSerializing>)modelClass param:(nullable NSDictionary *)param;

@end
