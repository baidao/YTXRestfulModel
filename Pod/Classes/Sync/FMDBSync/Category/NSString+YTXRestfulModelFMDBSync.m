//
//  NSString+YTXRestfulModelFMDBSync.m
//  Pods
//
//  Created by CaoJun on 16/2/24.
//
//

#import "NSString+YTXRestfulModelFMDBSync.h"

@implementation NSString (YTXRestfulModelFMDBSync)

- (nullable NSString *) sqliteValue
{
    return [NSString stringWithFormat:@"'%@'", [self stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
}
+ (nullable NSString *) objectForSqliteString:(nonnull NSString *) sqlstring objectType:(nonnull NSString *) type
{
    return sqlstring;
}

@end
