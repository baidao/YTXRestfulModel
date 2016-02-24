//
//  NSValue+YTXRestfulModelFMDBSync.m
//  Pods
//
//  Created by CaoJun on 16/2/24.
//
//

#import "NSValue+YTXRestfulModelFMDBSync.h"
#import "NSObject+YTXRestfulModelFMDBSync.h"
#import <UIKit/UIKit.h>

@implementation NSValue (YTXRestfulModelFMDBSync)

+ (nonnull NSString*) formateObjectType:(const char* _Nonnull )objcType
{
    if (!objcType || !strlen(objcType)) return nil;
    NSString* type = [NSString stringWithCString:objcType encoding:NSUTF8StringEncoding];
    
    switch (objcType[0]) {
        case '@':
            type = [type substringWithRange:NSMakeRange(2, strlen(objcType)-3)];
            break;
        case '{':
            type = [type substringWithRange:NSMakeRange(1, strchr(objcType, '=')-objcType-1)];
            break;
        default:
            break;
    }
    return type;
}

- (nullable NSString *) sqliteValue
{
    NSString* type = [NSValue formateObjectType:[self objCType]];
    
    if ([type isEqualToString:@"CGPoint"]) {
        return [NSStringFromCGPoint([self CGPointValue]) sqliteValue];
    } else if ([type isEqualToString:@"CGSize"]) {
        return [NSStringFromCGSize([self CGSizeValue]) sqliteValue];
    } else if ([type isEqualToString:@"CGRect"]) {
        return [NSStringFromCGRect([self CGRectValue]) sqliteValue];
    } else if ([type isEqualToString:@"CGVector"]) {
        return [NSStringFromCGVector([self CGVectorValue]) sqliteValue];
    } else if ([type isEqualToString:@"CGAffineTransform"]) {
        return [NSStringFromCGAffineTransform([self CGAffineTransformValue]) sqliteValue];
    } else if ([type isEqualToString:@"UIEdgeInsets"]) {
        return [NSStringFromUIEdgeInsets([self UIEdgeInsetsValue]) sqliteValue];
    } else if ([type isEqualToString:@"UIOffset"]) {
        return [NSStringFromUIOffset([self UIOffsetValue]) sqliteValue];
    } else if ([type isEqualToString:@"NSRange"]) {
        return [NSStringFromRange([self rangeValue]) sqliteValue];
    }
    
    return nil;
}
+ (nullable id) objectForSqliteString:(nonnull NSString *) sqlstring objectType:(nonnull NSString *) type
{
    if ([type isEqualToString:@"CGPoint"]) {
        return [NSValue valueWithCGPoint:CGPointFromString(sqlstring)];
    } else if ([type isEqualToString:@"CGSize"]) {
        return [NSValue valueWithCGSize:CGSizeFromString(sqlstring)];
    } else if ([type isEqualToString:@"CGRect"]) {
        return [NSValue valueWithCGRect:CGRectFromString(sqlstring)];
    } else if ([type isEqualToString:@"CGVector"]) {
        return [NSValue valueWithCGVector:CGVectorFromString(sqlstring)];
    } else if ([type isEqualToString:@"CGAffineTransform"]) {
        return [NSValue valueWithCGAffineTransform:CGAffineTransformFromString(sqlstring)];
    } else if ([type isEqualToString:@"UIEdgeInsets"]) {
        return [NSValue valueWithUIEdgeInsets:UIEdgeInsetsFromString(sqlstring)];
    } else if ([type isEqualToString:@"UIOffset"]) {
        return [NSValue valueWithUIOffset:UIOffsetFromString(sqlstring)];
    } else if ([type isEqualToString:@"NSRange"]) {
        return [NSValue valueWithRange:NSRangeFromString(sqlstring)];
    }
    return nil;
}

@end
