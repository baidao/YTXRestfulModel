//
//  NSNumber+YTXRestfulModelFMDBSync.m
//  Pods
//
//  Created by CaoJun on 16/2/24.
//
//

#import "NSNumber+YTXRestfulModelFMDBSync.h"

@implementation NSNumber (YTXRestfulModelFMDBSync)

- (nullable NSString *) sqliteValue
{
    return [self stringValue];
}
+ (nullable id) objectForSqliteString:(nonnull NSString *) sqlstring objectType:(nonnull NSString *) type
{
    NSNumberFormatter *fmt = [[NSNumberFormatter alloc] init];
    return [fmt numberFromString:sqlstring];
}

@end
