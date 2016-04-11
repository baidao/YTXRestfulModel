//
//  YTXRestfulCollection+RACSupport.m
//  Pods
//
//  Created by Chuan on 4/11/16.
//
//

#import "YTXRestfulCollection+RACSupport.h"

@implementation YTXRestfulCollection (RACSupport)

#pragma mark - remote

- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    [self fetchRemote:param success:^(id  _Nullable response) {
        [subject sendNext:response];
        [subject sendCompleted];
    } failed:^(NSError * _Nullable error) {
        [subject sendError:error];
    }];
    return subject;
}

- (nonnull RACSignal *) fetchRemoteThenAdd:(nullable NSDictionary *)param
{
    RACSubject * subject = [RACSubject subject];
    [self fetchRemoteThenAdd:param success:^(id  _Nullable response) {
        [subject sendNext:response];
        [subject sendCompleted];
    } failed:^(NSError * _Nullable error) {
        [subject sendError:error];
    }];
    return subject;
}

#pragma mark - storage

/** GET */
- (nonnull RACSignal *) fetchStorage:(nullable NSDictionary *)param
{
    return [self fetchStorageWithKey:[self storageKey] param:param];
}

/** POST / PUT */
- (nonnull RACSignal *) saveStorage:(nullable NSDictionary *)param
{
    return [self saveStorageWithKey:[self storageKey] param:param];
}

/** DELETE */
- (nonnull RACSignal *) destroyStorage:(nullable NSDictionary *)param
{
    return [self destroyStorageWithKey:[self storageKey] param:param];
}

- (RACSignal *)fetchStorageWithKey:(NSString *)storageKey param:(NSDictionary *)param
{
    NSArray * x = [self.storageSync fetchStorageSyncWithKey:storageKey param:param];
    NSError * error = nil;
    if (x) {
        NSArray * ret = [self transformerProxyOfResponse:x error:&error];
        [self resetModels:ret];
    }
    else {
        error = [NSError errorWithDomain:NSStringFromClass([self class]) code:404 userInfo:nil];
    }
    
    
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (!error) {
                    [subscriber sendNext:self];
                    [subscriber sendCompleted];
                }
                else {
                    [subscriber sendError:error];
                }
        });
        
        return nil;
    }];
}

- (RACSignal *)saveStorageWithKey:(NSString *)storageKey param:(NSDictionary *)param
{
    [self.storageSync saveStorageSyncWithKey:storageKey withObject:[self transformerProxyOfModels:[self.models copy]] param:param];
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        @strongify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [subscriber sendNext:self];
            [subscriber sendCompleted];
        });
        
        return nil;
    }];
}

- (RACSignal *)destroyStorageWithKey:(NSString *)storageKey param:(NSDictionary *)param
{
    [self.storageSync destroyStorageSyncWithKey:storageKey param:param];
    return [RACSignal createSignal:^RACDisposable *(id subscriber) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [subscriber sendNext:nil];
            [subscriber sendCompleted];
        });
        
        return nil;
    }];
}

#pragma mark - db
- (nonnull RACSignal *) fetchDBAll
{
    NSError * error = nil;
    return [self _createRACSingalWithNext:[self fetchDBSyncAllWithError:&error] error:error];
}

- (nonnull RACSignal *) fetchDBAllSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )columnName, ...
{
    NSError * error = nil;
    va_list args;
    va_start(args, columnName);
    
    NSArray * columnNames = [self arrayWithArgs:args firstArgument:columnName];
    
    va_end(args);
    
    columnNames = [self arrayOfMappedArgsWithOriginArray:columnNames];
    
    return [self _createRACSingalWithNext:[self fetchDBSyncAllWithError:&error soryBy:sortBy orderByColumnNames:columnNames] error:error];
}

- (nonnull RACSignal *) fetchDBMultipleWith:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )columnName, ...
{
    NSError * error = nil;
    va_list args;
    va_start(args, columnName);
    
    NSArray * columnNames = [self arrayWithArgs:args firstArgument:columnName];
    
    va_end(args);
    
    columnNames = [self arrayOfMappedArgsWithOriginArray:columnNames];
    
    return [self _createRACSingalWithNext:[self fetchDBSyncMultipleWithError:&error start:start count:count soryBy:sortBy orderByColumnNames:columnNames] error:error];
}

- (nonnull RACSignal *) fetchDBMultipleWhereAllTheConditionsAreMet:(nonnull NSString * )condition, ...
{
    va_list args;
    va_start(args, condition);
    
    NSArray * conditions = [self arrayWithArgs:args firstArgument:condition];
    
    va_end(args);
    
    NSError * error = nil;
    return [self _createRACSingalWithNext:[self fetchDBSyncMultipleWithError:&error whereAllTheConditionsAreMetConditions:conditions] error:error];
}

- (nonnull RACSignal *) fetchDBMultipleWhereAllTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy conditions:(nonnull NSString * )condition, ...
{
    va_list args;
    va_start(args, condition);
    
    NSArray * conditions = [self arrayWithArgs:args firstArgument:condition];
    
    va_end(args);
    
    NSError * error = nil;
    return [self _createRACSingalWithNext:[self fetchDBSyncMultipleWithError:&error whereAllTheConditionsAreMetWithSoryBy:sortBy orderBy:orderBy conditionsArray:conditions] error:error];
}

- (nonnull RACSignal *) fetchDBMultipleWhereAllTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditions:(nonnull NSString * )condition, ...
{
    va_list args;
    va_start(args, condition);
    
    NSArray * conditions = [self arrayWithArgs:args firstArgument:condition];
    
    va_end(args);
    
    NSError * error = nil;
    return [self _createRACSingalWithNext:[self fetchDBSyncMultipleWithError:&error whereAllTheConditionsAreMetWithStart:start count:count soryBy:sortBy orderBy:orderBy conditionsArray:conditions] error:error];
}

- (nonnull RACSignal *) fetchDBMultipleWherePartOfTheConditionsAreMet:(nonnull NSString * )condition, ...
{
    va_list args;
    va_start(args, condition);
    
    NSArray * conditions = [self arrayWithArgs:args firstArgument:condition];
    
    va_end(args);
    
    NSError * error = nil;
    return [self _createRACSingalWithNext:[self fetchDBSyncMultipleWithError:&error wherePartOfTheConditionsAreMetConditionsArray:conditions] error:error];
}

- (nonnull RACSignal *) fetchDBMultipleWherePartOfTheConditionsAreMetWithSoryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * )orderBy conditions:(nonnull NSString * )condition, ...
{
    va_list args;
    va_start(args, condition);
    
    NSArray * conditions = [self arrayWithArgs:args firstArgument:condition];
    
    va_end(args);
    
    NSError * error = nil;
    return [self _createRACSingalWithNext:[self fetchDBSyncMultipleWithError:&error wherePartOfTheConditionsAreMetWithSoryBy:sortBy orderBy:orderBy conditionsArray:conditions] error:error];
}

- (nonnull RACSignal *) fetchDBMultipleWherePartOfTheConditionsAreMetWithStart:(NSUInteger) start count:(NSUInteger) count soryBy:(YTXRestfulModelDBSortBy)sortBy orderBy:(nonnull NSString * ) orderBy conditions:(nonnull NSString * )condition, ...
{
    va_list args;
    va_start(args, condition);
    
    NSArray * conditions = [self arrayWithArgs:args firstArgument:condition];
    
    va_end(args);
    
    NSError * error = nil;
    return [self _createRACSingalWithNext:[self fetchDBSyncMultipleWithError:&error wherePartOfTheConditionsAreMetWithStart:start count:count soryBy:sortBy orderBy:orderBy conditionsArray:conditions] error:error];
}

/* RACSignal return BOOL **/
- (nonnull RACSignal *) destroyDBAll
{
    NSError * error = nil;
    return [self _createRACSingalWithNext:@([self destroyDBSyncAllWithError:&error]) error:error];
}

- (nonnull RACSignal *) _createRACSingalWithNext:(id) ret error:(nullable NSError *) error
{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (error) {
                [subscriber sendError:error];
                return;
            }
            [subscriber sendNext:ret];
            [subscriber sendCompleted];
        });
        return nil;
    }];
}
@end
