//
//  NSDictionary+YTXRestfulModelFMDBSync.m
//  Pods
//
//  Created by CaoJun on 16/2/24.
//
//

#import "NSDictionary+YTXRestfulModelFMDBSync.h"

@implementation NSDictionary (YTXRestfulModelFMDBSync)

- (nullable NSString *) sqliteValue
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self
                                                       options:kNilOptions
                                                         error:&error];
    NSString *jsonStr = [[NSString alloc] initWithData:jsonData
                                              encoding:NSUTF8StringEncoding];
    
    if (error) {
        return nil;
    }
    
    return jsonStr;
}
+ (nullable id) objectForSqliteString:(nonnull NSString *) sqlstring objectType:(nonnull NSString *) type
{
    NSError *error;
    NSData *objectData = [sqlstring dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&error];
    if (error) {
        return nil;
    }
    
    return dict;
}

@end
