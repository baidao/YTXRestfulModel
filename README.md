# YTXRestfulModel

YTXRestfulModel是遵循了REST的Model。
提供了DBSync（数据库同步）、RemoteSync（远程同步）、StorageSync（本地存储同步）三种数据同步途径的方法。


依赖：
```
FMDBSync(sqlite)。
YTXRequestRemoteSync(YTXRequest AFNetWorking)。
AFNetworkingRemoteSync(AFNetWorking)。
UserDefaultStorageSync(支持不同的suiteName)。
Model的转换容器用的是Mantle。
[ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa)FRP。
```

## 安装

在podfile中

```ruby
source 'https://github.com/CocoaPods/Specs.git'

// "YTXRequestRemoteSync", "AFNetworkingRemoteSync", "FMDBSync", "UserDefaultStorageSync"

pod "YTXRestfulModel", :path => "../", :subspecs => ["AFNetworkingRemoteSync", "FMDBSync", "UserDefaultStorageSync"]
```

## 测试
```shell
npm install -g json-server
cd Example/Tests
json-server db.json
```

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

//主键（关键字段）适配。
/**@"keyId"为主键名，Model上的字段的名字*/
/**@"id"为目标源在数据库中的列名或者服务器上的名字*/
+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{@"keyId": @"id"};
}
+ (NSString *)primaryKey
{
    return @"keyId";
}

//可以重写init方法 改变sync的初始值等
- (instancetype)init {
    if (self = [super init]) {
        //这种方式可以在每次使用url的时候都重新获取
        self.remoteSync.urlHookBlock = ^NSURL * _Nonnull{
            return [YTXRequest urlWithName:@"restful.posts"];
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

## 遵循Rest，数据同步的使用 示例
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

## RACSignal的组合使用
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

##我们可以按照协议实现自己的Sync去灵活替换原有的Sync。

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
## DB Migration(数据库迁移)
如果出现数据库随版本迁移，可在Model中重写migrationsMethodWithSync:方法。
```objective-c
//数据库迁移操作是从当前版本到最新版本依次进行的，所以本方法中要存储所有版本的迁移操作。
+ (void) migrationsMethodWithSync:(nonnull id<YTXRestfulModelDBProtocol>)sync;
{
  /** 创建 数据库迁移的操作*/
    YTXRestfulModelDBMigrationEntity *migration = [YTXRestfulModelDBMigrationEntity new];
    /** 设置 版本号*/
    migration.version = @1;
    /** 设置 迁移操作（增、删、改）*/
    migration.block = ^(_Nonnull id db, NSError * _Nullable * _Nullable error) {
        YTXRestfulModelDBSerializingModel *runtimePStruct = [YTXRestfulModelDBSerializingModel new];
        runtimePStruct.objectClass = @"NSString";
        runtimePStruct.columnName = @"runtimeP";
        runtimePStruct.modelName = @"runtimeP";
        runtimePStruct.isPrimaryKey = NO;
        runtimePStruct.autoincrement = NO;
        runtimePStruct.unique = NO;
        /** 创建新的列*/
        [sync createColumnWithDB:db structSync:runtimePStruct error:error];
    };
    /** 存储 迁移操作*/
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

## 更多用法，请查看[Tests](http://gitlab.baidao.com/ios/YTXRestfulModel/tree/master/Example/Tests)
```shell
git clone http://gitlab.baidao.com/ios/YTXRestfulModel.git
cd YTXRestfulModel/Example
pod install
```


## 依赖
- 'Mantle', '~> 1.5.4'
- 'ReactiveCocoa', '~> 2.3.1'

## subspec依赖
- YTXRequestRemoteSync: 'YTXRequest', '~> 0.1.6'
- AFNetworkingRemoteSync: 'AFNetworking', '~> 2.6.3'
- FMDBSync: 'FMDB', '~> 2.6'
- UserDefaultStorageSync:


## Author

caojun, 78612846@qq.com

