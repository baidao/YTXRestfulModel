//
//  NSDate+YTXRestfulModelFMDBSync.m
//  Pods
//
//  Created by CaoJun on 16/2/24.
//
//

#import "NSDate+YTXRestfulModelFMDBSync.h"

@implementation NSDate (YTXRestfulModelFMDBSync)

- (nullable NSString *) sqliteValue
{
    return [NSString stringWithFormat:@"%f", [self timeIntervalSince1970]];
}
+ (nullable id) objectForSqliteString:(nonnull NSString *) sqlstring objectType:(nonnull NSString *) type
{
    return @([sqlstring doubleValue]);
}

@end
