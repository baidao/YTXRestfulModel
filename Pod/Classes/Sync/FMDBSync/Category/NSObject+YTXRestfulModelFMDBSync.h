//
//  NSObject+YTXRestfulModelFMDBSync.h
//  Pods
//
//  Created by CaoJun on 16/2/24.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (YTXRestfulModelFMDBSync)

- (nullable NSString *) sqliteValue;
+ (nullable id) objectForSqliteString:(nonnull NSString *) sqlstring objectType:(nonnull NSString *) type;

@end
