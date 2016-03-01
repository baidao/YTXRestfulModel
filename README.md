# YTXRestfulModel

YTXRestfulModel是遵循了REST的Model。提供了DBSync、RemoteSync、StorageSync来做数据同步。


DBSync实现是FMDB(sqlite)。


RemoteSync实现是YTXRequest实际上是AFNetWorking。


StorageSync实现是NSUserDefault(支持不同的suiteName)。


Model的转换容器用的是Mantle。


ReactiveCocoa来使用FRP。


## 我们可以按照协议实现自己的Sync去灵活替换原有的Sync。像这样：
```objective-c
- (instancetype)init
{
    if(self = [super init])
    {
        self.storageSync = [YTXRestfulModelXXXFileStorageSync new];
    }
    return self;
}

YTXTestModel * model = [YTXTestModel new];
model.storageSync = [YTXRestfulModelXXXFileStorageSync new];

```

## 各种灵活的同步数据方式
```objective-c

/** GET */
- (nullable instancetype) fetchStorageSync:(nullable NSDictionary *) param;
/** GET */
- (nonnull RACSignal *) fetchStorage:(nullable NSDictionary *)param;

/** GET */
- (nonnull RACSignal *) fetchRemote:(nullable NSDictionary *)param;

/** POST / PUT */
- (nonnull RACSignal *) saveRemote:(nullable NSDictionary *)param;

/** GET */
- (nonnull instancetype) fetchDBSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error;

/** GET */
- (nonnull RACSignal *) fetchDB:(nullable NSDictionary *)param;

```

## 遵循Rest
```objective-c
  YTXTestModel * currentTestModel = [[YTXTestModel alloc] init];
  currentTestModel.keyId = @1;
  [[currentTestModel fetchRemote:nil] subscribeNext:^(YTXTestModel *responseModel) {

  } error:^(NSError *error) {

  }];

  YTXTestModel * dbTestModel = [[YTXTestModel alloc] init];
  dbTestModel.keyId = @1;
  [[dbTestModel fetchDB:nil] subscribeNext:^(YTXTestModel *responseModel) {

  } error:^(NSError *error) {

  }];

  YTXTestModel * storageTestModel = [[YTXTestModel alloc] init];
  storageTestModel.keyId = @1;
  [[storageTestModel fetchStorage:nil] subscribeNext:^(YTXTestModel *responseModel) {

  } error:^(NSError *error) {

  }];

  YTXTestModel * testModel = [[YTXTestModel alloc] init];
  testModel.title = @"ytx test hahahaha";
  testModel.body = @"teststeststesettsetsetttsetttest";
  testModel.userId = @1;
  [[testModel saveRemote:nil] subscribeNext:^(YTXTestModel *responseModel) {

  } error:^(NSError *error) {

  }];

  YTXTestModel * currentTestModel = [[YTXTestModel alloc] init];
  __block id ret;
  currentTestModel.keyId = @1;
  [[currentTestModel fetchRemoteForeignWithName:@"comments" modelClass:[YTXTestCommentModel class] param:nil] subscribeNext:^(id x) {
      ret = x;
  } error:^(NSError *error) {

  }];
```

## 组合使用
```objective-c

@interface YTXXXXModel : YTXRestfulModel

- (nonnull RACSignal *) fetchFromRemoteAndStorage;

@end

@implementation YTXXXXXModel

- (nonnull RACSignal *) fetchFromRemoteAndStorage
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[RACSignal combineLatest:@[[self fetchRemote], [self fetchStorage]] reduce:^id{
        return ...;
    }] subscribeNext:^(id x) {
        @strongify(self);
        NSError * error = nil;
        [self transformerProxyOfReponse:x error:&error];
        if (!error) {
            [subject sendNext:self];
            [subject sendCompleted];
        }
        else {
            [subject sendError:error];
        }
    } error:^(NSError *error) {
        [subject sendError:error];
    }];
    return subject;
}

@end

```

## Model的转换参考[Mantl](https://github.com/Mantle/Mantle/tree/1.5.7)

## 安装

在podfile中

```ruby
source 'https://github.com/CocoaPods/Specs.git'
pod 'YTXRestfulModel'
```

## 更多用法，请查看[Tests](http://gitlab.baidao.com/ios/YTXRestfulModel/tree/master/Example/Tests)
```shell
git clone http://gitlab.baidao.com/ios/YTXRestfulModel.git
cd YTXRestfulModel/Example
pod install
```


## 依赖
- 'YTXRequest', '~> 0.1.6'
- 'Mantle', '~> 1.5.4'
- 'ReactiveCocoa', '~> 2.3.1'
- 'FMDB', '~> 2.6'


## Author

caojun, 78612846@qq.com

