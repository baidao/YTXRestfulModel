//
//  YTXRestfulCollection+RACSupport.h
//  Pods
//
//  Created by Chuan on 4/11/16.
//
//

#import <YTXRestfulModel/YTXRestfulCollection.h>

#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>

@interface YTXRestfulCollection (RACSupport)

#pragma mark - remote
/* RACSignal return self **/
- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param;

/* RACSignal return self **/
- (nonnull RACSignal *) fetchRemoteThenAdd:(nullable NSDictionary *)param;

#pragma mark - storage
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

#pragma mark - db
- (nonnull RACSignal *) fetchDBAll;

- (nonnull RACSignal *) fetchDBAllSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )columnName, ...;

- (nonnull RACSignal *) fetchDBMultipleWith:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )columnName, ...;

- (nonnull RACSignal *) fetchDBMultipleWhereAllTheConditionsAreMet:(nonnull NSString * )condition, ...;

- (nonnull RACSignal *) fetchDBMultipleWhereAllTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy conditions:(nonnull NSString * )condition, ...;

- (nonnull RACSignal *) fetchDBMultipleWhereAllTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditions:(nonnull NSString * )condition, ...;

- (nonnull RACSignal *) fetchDBMultipleWherePartOfTheConditionsAreMet:(nonnull NSString * )condition, ...;

- (nonnull RACSignal *) fetchDBMultipleWherePartOfTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy conditions:(nonnull NSString * )condition, ...;

- (nonnull RACSignal *) fetchDBMultipleWherePartOfTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditions:(nonnull NSString * )condition, ...;

/* RACSignal return BOOL **/
- (nonnull RACSignal *) destroyDBAll;
@end
