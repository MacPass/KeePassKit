//
//  NSNumber+TypedNumber.h
//  KeePassKit
//
//  Created by Michael Starke on 06/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, KPKNumberType) {
  kKPKNumberTypeNone,
  kKPKNumberTypeBool,
  kKPKNumberTypeInt32,
  kKPKNumberTypeInt64,
  kKPKNumberTypeUInt32,
  kKPKNumberTypeUInt64
};

@interface NSNumber (TypedNumber)

@property (nonatomic,readonly) KPKNumberType type;

+ (instancetype)typedNumberWithLong:(long)value;
+ (instancetype)typedNumberWithUnsignedLong:(unsigned long)value;
+ (instancetype)typedNumberWithLongLong:(long long)value;
+ (instancetype)typedNumberWithUnsignedLongLong:(unsigned long long)value;
+ (instancetype)typedNumberWithBool:(BOOL)value;
@end
