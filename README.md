# YTXRestfulModel

YTXRestfulModel是遵循了REST的Model。提供了DBSync、RemoteSync、StorageSync来做数据同步。


DBSync实现是FMDB(sqlite)。


RemoteSync实现是YTXRequest实际上是AFNetWorking。


StorageSync实现是NSUserDefault(支持不同的suiteName)。


Model的转换容器用的是Mantle。


ReactiveCocoa来使用FRP。

## 定义Model
```objective-c
@interface YTXTestModel : YTXRestfulModel

@property (nonnull, nonatomic, strong) NSNumber *keyId;
@property (nonnull, nonatomic, strong) NSNumber *userId; //可选属性为nullable 不可选为nonnull
@property (nonnull, nonatomic, strong) NSString *title;
@property (nonnull, nonatomic, strong) NSString *body;

@end

@implementation YTXTestModel

//Mantle的model属性和目标源属性的映射表。DBSync也会使用。
+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{@"keyId": @"id"};
}

//主键名。在Model上的名字
+ (NSString *)primaryKey
{
    return @"keyId";
}

//可以重写init方法 改变sync的初始值等
- (instancetype)init {
    if (self = [super init]) {
        //这种方式可以解决切换公司时的切换URL
        self.remoteSync.urlHookBlock = ^NSURL * _Nonnull{
            return [YTXRequest urlWithName:@"restful.posts"];
        };
    }
    return  self;
}

//mantle Transoformer
+ (MTLValueTransformer *) bodyJSONTransformer
{
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSString * body) {
        return body;
    } reverseBlock:^(NSString * body) {
        return body;
    }];
}

@end

```

## Model的转换参考[Mantle](https://github.com/Mantle/Mantle/tree/1.5.7)
```objective-c
+ (MTLValueTransformer *)birthdayJSONTransformer {
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSNumber *timestamp) {
        return [NSDate dateWithTimeIntervalSince1970: timestamp.longLongValue / 1000];
    } reverseBlock:^(NSDate *date) {
        return @((SInt64)(date.timeIntervalSince1970 * 1000));
    }];
}

//解密
+ (MTLValueTransformer *)passwordJSONTransformer {
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSString *value) {
        return [self encryption:value];
    } reverseBlock:^(NSString *value) {
        return [self decryption:value];
    }];
}
```


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

## DB数据库的映射
YTXRestfulModel将会自动映射属性到表。当当主键是NSNumber 或者 NSUInteger NSInteger int 之类的类型会被设置为自动自增。
```objective-c
struct YTXRestfulModelDBSerializingStruct dataStruct = {
    propertyClassName, //CType
    [columnName UTF8String],
    [modelProperyName UTF8String],
    isPrimaryKey,
    NO,
    nil,
    NO,
    nil, //'YTXXXModel'
};
```

开启自动创建数据库表
```objective-c
+ (BOOL) autoCreateTable
{
    return YES;
}
```

定义DB的Column的Struct
```objective-c
struct YTXRestfulModelDBSerializingStruct {
    /** 数据类型 */
    const char * _Nonnull objectClass;

    /** 表名 */
    const char * _Nullable  columnName;

    /** Model原始的属性名字 */
    const char * _Nonnull  modelName;

    bool isPrimaryKey;

    bool autoincrement;

    const char * _Nullable defaultValue;

    bool unique;

    /** 外键类名 可以使用fetchForeignWithName */
    const char * _Nullable foreignClassName;

};
```

在子类中更改DB的映射
```objective-c
+ (nullable NSMutableDictionary<NSString *, NSValue *> *) tableKeyPathsByPropertyKey
{
    NSMutableDictionary<NSString *, NSValue *> * tmpDictionary = [[super tableKeyPathsByPropertyKey] mutableCopy];

    struct YTXRestfulModelDBSerializingStruct genderStruct = [YTXRestfulModelFMDBSync structWithValue:tmpDictionary[@"gender"]];
    genderStruct.defaultValue = [[@(GenderFemale) sqliteValue] UTF8String];

    tmpDictionary[@"gender"] = [YTXRestfulModelFMDBSync valueWithStruct:genderStruct];

    return tmpDictionary;
}
```

## Migration(迁移)


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

