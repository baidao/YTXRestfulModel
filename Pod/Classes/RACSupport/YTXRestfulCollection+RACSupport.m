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


@end
