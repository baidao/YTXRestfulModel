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
- (nonnull RACSignal *) rac_fetchRemote:(nullable NSDictionary *)param;

/* RACSignal return self **/
- (nonnull RACSignal *) rac_fetchRemoteThenAdd:(nullable NSDictionary *)param;

#pragma mark - storage
/** GET */
- (nonnull RACSignal *) rac_fetchStorage:(nullable NSDictionary *)param;

/** POST / PUT */
- (nonnull RACSignal *) rac_saveStorage:(nullable NSDictionary *)param;

/** DELETE */
- (nonnull RACSignal *) rac_destroyStorage:(nullable NSDictionary *)param;

/** GET */
- (nonnull RACSignal *) rac_fetchStorageWithKey:(nonnull NSString *)storageKey param:(nullable NSDictionary *)param;

/** POST / PUT */
- (nonnull RACSignal *) rac_saveStorageWithKey:(nonnull NSString *)storageKey param:(nullable NSDictionary *)param;

/** DELETE */
- (nonnull RACSignal *) rac_destroyStorageWithKey:(nonnull NSString *)storageKey param:(nullable NSDictionary *)param;

#pragma mark - db
- (nonnull RACSignal *) rac_fetchDBAll;

- (nonnull RACSignal *) rac_fetchDBAllSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )columnName, ...;

- (nonnull RACSignal *) rac_fetchDBMultipleWith:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )columnName, ...;

- (nonnull RACSignal *) rac_fetchDBMultipleWhereAllTheConditionsAreMet:(nonnull NSString * )condition, ...;

- (nonnull RACSignal *) rac_fetchDBMultipleWhereAllTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy conditions:(nonnull NSString * )condition, ...;

- (nonnull RACSignal *) rac_fetchDBMultipleWhereAllTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditions:(nonnull NSString * )condition, ...;

- (nonnull RACSignal *) rac_fetchDBMultipleWherePartOfTheConditionsAreMet:(nonnull NSString * )condition, ...;

- (nonnull RACSignal *) rac_fetchDBMultipleWherePartOfTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy conditions:(nonnull NSString * )condition, ...;

- (nonnull RACSignal *) rac_fetchDBMultipleWherePartOfTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditions:(nonnull NSString * )condition, ...;

/* RACSignal return BOOL **/
- (nonnull RACSignal *) rac_destroyDBAll;
@end
