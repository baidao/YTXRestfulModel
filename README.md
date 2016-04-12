YTXRestfulModel是遵循了REST的Model。
提供了DBSync（数据库同步）、RemoteSync（远程同步）、StorageSync（本地存储同步）三种数据同步途径的方法。


依赖：
```
FMDBSync(sqlite)。
AFNetworkingRemoteSync(AFNetWorking)。
UserDefaultStorageSync(支持不同的suiteName)。
Model的转换容器用的是Mantle。
[ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa)FRP。
```

## 安装

在podfile中

```ruby
pod "YTXRestfulModel", :path => "../", :subspecs => ["AFNetworkingRemoteSync", "FMDBSync", "UserDefaultStorageSync"]
```

## 测试
```shell
git clone https://github.com/baidao/YTXRestfulModel.git
npm install -g json-server
cd Example
pod install
cd Tests
json-server db.json
open YTXRestfulModel.xcworkspace
```
Run Target: YTXRestfulModel-Example

## 更多用法，请查看[Tests](https://github.com/baidao/YTXRestfulModel/tree/github/Example/Tests)

## 定义Model 示例
```objective-c
@interface YTXTestModel : YTXRestfulModel

@property (nonnull, nonatomic, strong) NSNumber *keyId;
@property (nonnull, nonatomic, strong) NSNumber *userId;
@property (nonnull, nonatomic, strong) NSString *title;
@property (nonnull, nonatomic, strong) NSString *body;

@end
```
```objective-c
@implementation YTXTestModel

//Mantle的model属性和目标源属性的映射表
+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    /** key 的值是 模型中的字段，value 的值是目标源上对应数据的名字。*/
    return @{@"keyId": @"id"};
}

//@"keyId"为主键名，即Model的关键字段的名字
+ (NSString *)primaryKey
{
    return @"keyId";
}

//可以重写init方法 改变sync的初始值等
- (instancetype)init {
    if (self = [super init]) {
        //这种方式可以在每次使用url的时候都重新获取
        self.remoteSync.urlHookBlock = ^NSURL * _Nonnull{
            return [URLManager urlWithName:@"restful.posts"];
        };
    }
    return  self;
}

// DB Migration（数据迁移） 当前版本号
+ (nullable NSNumber *) currentMigrationVersion
{
    return @0;
}

// 自动建表。默认关闭，当需要用DB才开启
+ (BOOL) autoCreateTable
{
    return YES;
}

//自动扩展表和migration互斥
+ (BOOL) autoAlterTable
{
    return YES;
}

// Mantle Transformer
+ (MTLValueTransformer *)startSchoolDateJSONTransformer {
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSNumber *timestamp) {
        return [NSDate dateWithTimeIntervalSince1970: timestamp.longLongValue / 1000];
    } reverseBlock:^(NSDate *date) {
        return @((SInt64)(date.timeIntervalSince1970 * 1000));
    }];
}
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

## 各种灵活的同步数据的方法
```objective-c

/** GET */
- (nullable instancetype) fetchStorageSync:(nullable NSDictionary *) param;

/** GET */
- (void) fetchRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed;

/** POST / PUT */
- (void) saveRemote:(nullable NSDictionary *)param success:(nonnull YTXRestfulModelRemoteSuccessBlock)success failed:(nonnull YTXRestfulModelRemoteFailedBlock)failed;

/** GET */
- (nonnull instancetype) fetchDBSync:(nullable NSDictionary *)param error:(NSError * _Nullable * _Nullable) error;

```

## Model的转换参考[Mantle](https://github.com/Mantle/Mantle/tree/1.5.7)
无论数据源来自Remote，Storage，DB都会经过MTLValueTransformer，如果你定义了该属性的Transformer。
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

### 接收同步操作返回的 response ，若数据格式不规范，可以重写下面的方法，在转换前对response进行处理
```objective-c
- (nonnull id) transformerProxyOfForeign:(nonnull Class)modelClass response:(nonnull id) response error:(NSError * _Nullable * _Nullable) error;
{
    return [MTLJSONAdapter modelsOfClass:modelClass fromJSONArray:response error:error];
}
```

## RACSupport
```ruby
pod "YTXRestfulModel", :path => "../", :subspecs => ["RACSupport", "AFNetworkingRemoteSync", "FMDBSync", "UserDefaultStorageSync"]
```

```objective-c

/** GET */
- (nonnull RACSignal *) rac_fetchStorage:(nullable NSDictionary *)param;

/** GET */
- (nonnull RACSignal *) rac_fetchRemote:(nullable NSDictionary *)param;

/** POST / PUT */
- (nonnull RACSignal *) rac_saveRemote:(nullable NSDictionary *)param;

/** GET */
- (nonnull RACSignal *) rac_fetchDB:(nullable NSDictionary *)param;

```

```objective-c
#import <YTXRestfulModel/YTXRestfulModelRACSupport.h>

YTXTestAFNetworkingRemoteCollection * collection = [YTXTestAFNetworkingRemoteCollection new];
[[collection rac_fetchRemote:@{@"_start": @"1", @"_limit": @"2"}] subscribeNext:^(YTXTestAFNetworkingRemoteCollection *x) {
    
} error:^(NSError *error) {

}];
```

## 遵循Rest，数据同步的使用 示例
```objective-c
  /**
  远程请求：http://jsonplaceholder.typicode.com/posts/1
  返回数据：
  {
  "userId": 1,
  "id": 1,
  "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
  "body": "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto"
  }
  */
  /**
  keyId = @1，按照JSONKeyPathsByPropertyKey方法中的映射转成retDictionary @{@"id":@1}；
  由于param为空，所以保留参数{@"id":@"1"}不做修改，直接执行同步操作，同步目标源中 id = 1 的数据；
  */
  YTXTestModel * currentTestModel = [[YTXTestModel alloc] init];
  currentTestModel.keyId = @1;
  [[currentTestModel rac_fetchRemote:nil] subscribeNext:^(YTXTestModel *responseModel) {

  } error:^(NSError *error) {

  }];

  /**
  Model的属性会按照映射转成retDictionary @{@"title":@"ytx test", @"body":@"test content", @"userId":@1}
  param按照映射转成mapParam，@{@"id":@2}；（param = @{@"id":@2} 时也会转成 @{@"id":@2}）。
  mapParam的value会替换retDictionary 的value,所以执行同步的参数是@{@"title":@"ytx_test", @"body":@"test_content", @"userId":@1, @"id":@1}
  由于retDictionary 中没有主键，所以不符合rest原则，最后发送的请求是: *******?title=ytx_test&body=test_content&userId=1&id=1
  */
  YTXTestModel * testModel = [[YTXTestModel alloc] init];
  testModel.title = @"ytx test";
  testModel.body = @"test content";
  testModel.userId = @1;
  [[testModel rac_saveRemote:@{@"keyId":@1}] subscribeNext:^(YTXTestModel *responseModel) {

  } error:^(NSError *error) {

  }];

  YTXTestModel * currentTestModel = [[YTXTestModel alloc] init];
  __block id ret;
  currentTestModel.keyId = @1;
  [[currentTestModel rac_fetchRemoteForeignWithName:@"comments" modelClass:[YTXTestCommentModel class] param:nil] subscribeNext:^(id x) {
      ret = x;
  } error:^(NSError *error) {

  }];

  YTXTestModel * dbTestModel = [[YTXTestModel alloc] init];
  dbTestModel.keyId = @1;
  [[dbTestModel rac_fetchDB:nil] subscribeNext:^(YTXTestModel *responseModel) {

  } error:^(NSError *error) {

  }];

  YTXTestModel * storageTestModel = [[YTXTestModel alloc] init];
  storageTestModel.keyId = @1;
  [[storageTestModel rac_fetchStorage:nil] subscribeNext:^(YTXTestModel *responseModel) {

  } error:^(NSError *error) {

  }];
```

## RACSignal的组合使用
```objective-c
#import <YTXRestfulModel/YTXRestfulModelRACSupport.h>

@interface YTXXXXModel : YTXRestfulModel

- (nonnull RACSignal *) rac_fetchFromRemoteAndStorage;

@end

@implementation YTXXXXXModel

- (nonnull RACSignal *) rac_fetchFromRemoteAndStorage
{
    RACSubject * subject = [RACSubject subject];
    @weakify(self);
    [[RACSignal combineLatest:@[[self rac_fetchRemote], [self rac_fetchStorage]] reduce:^id{
        return ...;
    }] subscribeNext:^(id x) {
        @strongify(self);
        NSError * error = nil;
        [self transformerProxyOfResponse:x error:&error];
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

## 我们可以按照协议实现自己的Sync去灵活替换原有的Sync。

协议对应模型的字段
```objective-c
id<YTXRestfulModelStorageProtocol> storageSync;
id<YTXRestfulModelRemoteProtocol> remoteSync;
id<YTXRestfulModelDBProtocol> dbSync;
```
 替换过方法：
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

 如果有必要你也可以直接使用sync。像这样：
```objective-c
#import <YTXRestfulModel/YTXRestfulModelUserDefaultStorageSync.h>

YTXRestfulModelUserDefaultStorageSync * sync = [[YTXRestfulModelUserDefaultStorageSync alloc] initWithUserDefaultSuiteName:suitName1]
```

## DB数据库的映射
定义DB的Column的Struct
```objective-c
YTXRestfulModelDBSerializingModel * dbsm = [YTXRestfulModelDBSerializingModel new];
dbsm.objectClass = propertyClassName;
dbsm.columnName = columnName;
dbsm.modelName = modelProperyName;
dbsm.isPrimaryKey = isPrimaryKey;
dbsm.autoincrement = isPrimaryKeyAutoincrement;
dbsm.unique = NO;
```
```objective-c
@interface YTXRestfulModelDBSerializingModel : NSObject

/** 可以是CType @"d"这种*/
@property (nonatomic, nonnull, copy) NSString * objectClass;

/** 表名 */
@property (nonatomic, nonnull, copy) NSString *  columnName;

/** Model原始的属性名字 */
@property (nonatomic, nonnull, copy) NSString *  modelName;

/** 是否 主键*/
@property (nonatomic, assign) BOOL isPrimaryKey;

/** 是否自增*/
@property (nonatomic, assign) BOOL autoincrement;

/** 是否唯一*/
@property (nonatomic, assign) BOOL unique;

/** 默认值*/
@property (nonatomic, nonnull, copy) NSString * defaultValue;

/** 外键类名 可以使用fetchForeignWithName */
@property (nonatomic, nonnull, copy) NSString * foreignClassName;

@end
```

在子类中更改DB的映射
```objective-c
+ (nullable NSMutableDictionary<NSString *, YTXRestfulModelDBSerializingModel *> *) tableKeyPathsByPropertyKey
{
    NSMutableDictionary<NSString *, YTXRestfulModelDBSerializingModel *> * tmpDictionary = [super tableKeyPathsByPropertyKey];

    YTXRestfulModelDBSerializingModel * genderStruct = tmpDictionary[@"gender"];
    genderStruct.defaultValue = [@(GenderFemale) sqliteValue];
    tmpDictionary[@"gender"] = genderStruct;

    YTXRestfulModelDBSerializingModel * scoreStruct = tmpDictionary[@"score"];
    scoreStruct.unique = YES;
    tmpDictionary[@"score"] = scoreStruct;
    return tmpDictionary;
}
```

开启自动创建数据库表。需要使用DB时才这样做。
```objective-c
+ (BOOL) autoCreateTable
{
    return YES;
}
```

关闭主键默认自增
```objective-c
+ (BOOL) isPrimaryKeyAutoincrement
{
    return NO;
}
```

Model支持的属性类型(CType)    数据库转换后类型       SQLite中定义的类型
```objective-c
@{
  @"c":@[                   @"NSNumber",        @"INTEGER"],
  @"i":@[                   @"NSNumber",        @"INTEGER"],
  @"s":@[                   @"NSNumber",        @"INTEGER"],
  @"l":@[                   @"NSNumber",        @"INTEGER"],
  @"q":@[                   @"NSNumber",        @"INTEGER"],
  @"C":@[                   @"NSNumber",        @"INTEGER"],
  @"I":@[                   @"NSNumber",        @"INTEGER"],
  @"S":@[                   @"NSNumber",        @"INTEGER"],
  @"L":@[                   @"NSNumber",        @"INTEGER"],
  @"Q":@[                   @"NSNumber",        @"INTEGER"],
  @"f":@[                   @"NSNumber",        @"REAL"],
  @"d":@[                   @"NSNumber",        @"REAL"],
  @"B":@[                   @"NSNumber",        @"INTEGER"],
  @"NSString":@[            @"NSString",        @"TEXT"],
  @"NSMutableString":@[     @"NSMutableString", @"TEXT"],
  @"NSDate":@[              @"NSDate",          @"REAL"],
  @"NSNumber":@[            @"NSNumber",        @"REAL"],
  @"NSDictionary":@[        @"NSDictionary",    @"TEXT"],
  @"NSMutableDictionary":@[ @"NSDictionary",    @"TEXT"],
  @"NSArray":@[             @"NSArray",         @"TEXT"],
  @"NSMutableArray":@[      @"NSArray",         @"TEXT"],
//这里以下和Remote一般不兼容
  @"CGPoint":@[             @"NSValue",         @"TEXT"],
  @"CGSize":@[              @"NSValue",         @"TEXT"],
  @"CGRect":@[              @"NSValue",         @"TEXT"],
  @"CGVector":@[            @"NSValue",         @"TEXT"],
  @"CGAffineTransform":@[   @"NSValue",         @"TEXT"],
  @"UIEdgeInsets":@[        @"NSValue",         @"TEXT"],
  @"UIOffset":@[            @"NSValue",         @"TEXT"],
  @"NSRange":@[             @"NSValue",         @"TEXT"]
}
```
## DB Alter(自动扩展字段到表中)

```objective-c
//开启时，不会使用migration
+ (BOOL) autoAlterTable
{
    return YES;//Default
}

//一样通过version来表示是否已经扩展
+ (nullable NSNumber *) currentMigrationVersion
{
    return @0;
}

```

| currentMigrationVersion        | Property             | DB Column            |
| ------------------------------ |:--------------------:| --------------------:|
| 0                              | Name,KeyId           | name,keyid           |
| 1                              | Name,KeyId,title     | name,keyid,title     |
| 2                              | Name,KeyId,title,age | name,keyId,title,age |
| 3                              | Name,KeyId,title     | name,keyId,title,age |


## DB Migration(数据库迁移)
```objective-c
// DB Migration（数据迁移） 当前版本号。
+ (nullable NSNumber *) currentMigrationVersion
{
    return @0;
}

+ (BOOL) autoAlterTable
{
    return NO;//Not Default
}
```

| currentMigrationVersion        | Property             | DB Column                   |
| ------------------------------ |:--------------------:| ---------------------------:|
| 0                              | KeyId,age            | keyid,age                   |
| 1                              | KeyId,age,title      | keyId,age,title             |
| 2                              | KeyId,age,name       | keyId,age,title,title=>name |

sqlite并没有提供rename和drop column的方法。

## 然后在Model中重写migrationsMethodWithSync:方法。

```objective-c

//数据库迁移操作是从当前版本到最新版本依次进行的，所以本方法中要存储所有版本的迁移操作。
+ (void) migrationsMethodWithSync:(nonnull id<YTXRestfulModelDBProtocol>)sync;
{
  // 创建 数据库迁移的操作
    YTXRestfulModelDBMigrationEntity *migration = [YTXRestfulModelDBMigrationEntity new];
    // 设置 进行本次操作时的版本号
    migration.version = @1;
    // 设置 迁移操作（增、删、改）
    migration.block = ^(_Nonnull id db, NSError * _Nullable * _Nullable error) {
        YTXRestfulModelDBSerializingModel *runtimePStruct = [YTXRestfulModelDBSerializingModel new];
        runtimePStruct.objectClass = @"NSString";
        runtimePStruct.columnName = @"runtimeP";
        runtimePStruct.modelName = @"runtimeP";
        runtimePStruct.isPrimaryKey = NO;
        runtimePStruct.autoincrement = NO;
        runtimePStruct.unique = NO;
        // 创建新的列
        [sync createColumnWithDB:db structSync:runtimePStruct error:error];
    };
    // 存储 迁移操作
    [sync migrate:migration];
}

```

增/删/改 的方法
```objective-c
- (BOOL) createColumnWithDB:(nonnull id)db structSync:(nonnull YTXRestfulModelDBSerializingModel *)sstruct error:(NSError * _Nullable * _Nullable)error;

@optional

- (BOOL) renameColumnWithDB:(nonnull id)db originName:(nonnull NSString *)originName newName:(nonnull NSString *)newName error:(NSError * _Nullable * _Nullable)error;

- (BOOL) dropColumnWithDB:(nonnull id)db structSync:(nonnull YTXRestfulModelDBSerializingModel *)sstruct error:(NSError * _Nullable * _Nullable)error;

- (BOOL) changeCollumnDB:(nonnull id)db oldStructSync:(nonnull YTXRestfulModelDBSerializingModel *) oldStruct toNewStruct:(nonnull YTXRestfulModelDBSerializingModel *) newStruct error:(NSError * _Nullable * _Nullable)error;
```

相关的代理方法
```objective-c
+ (void)dbWillMigrateWithSync:(nonnull id<YTXRestfulModelDBProtocol>)sync
{
}

+ (void)dbDidMigrateWithSync:(nonnull id<YTXRestfulModelDBProtocol>)sync
{
}
```
## Remote Hook
所有请求都会附带这些参数，hook的优先级最低，总是会被其他同名参数覆盖
```objective-c
NSDictionary *(^hook)() = ^NSDictionary *() {
    return @{
             @"deviceToken": objectOrEmptyStr([NotificationManager sharedManager].deviceToken),
             @"deviceId": objectOrEmptyStr([AppInfo deviceUUID]),
             @"marketId": objectOrEmptyStr([AppInfo marketId]),
             @"appVersion": objectOrEmptyStr([AppInfo appVersion])
    };
};

AFNetworkingRemoteSync.HookExtraParamBlock = hook;
```

## 依赖
- 'Mantle', '~> 1.5.4'

## subspec依赖
- AFNetworkingRemoteSync: 'AFNetworking', '~> 2.6.3'
- FMDBSync: 'FMDB', '~> 2.6'
- UserDefaultStorageSync:
- RACSupport:'ReactiveCocoa', '~> 2.3.1'


## Author

caojun, 78612846@qq.com

## License

YTXRestfulModel was built by caojun. It is licensed under the MIT License.

If you use YTXRestfulModel in one of your apps, I'd love to hear about it.
