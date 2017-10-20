//
//  KPKNumber.h
//  KeePassKit
//
//  Created by Michael Starke on 14/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, KPKNumberType) {
  KPKNumberTypeBool,
  KPKNumberTypeInteger32,
  KPKNumberTypeInteger64,
  KPKNumberTypeUnsignedInteger32,
  KPKNumberTypeUnsignedInteger64
};

/**
 *  Composite Class to hold type and Number information. Subclassing NSNumber would yield undefined behaviour since it's optimized for storage.
 */
@interface KPKNumber : NSObject <NSCopying>

@property (readonly) KPKNumberType type;

/**
 *  Supported accessor of internal values
 */
@property (readonly) int32_t integer32Value;
@property (readonly) uint32_t unsignedInteger32Value;
@property (readonly) int64_t integer64Value;
@property (readonly) uint64_t unsignedInteger64Value;
@property (readonly) BOOL boolValue;

+ (instancetype)numberWithInteger32:(int32_t)value;
+ (instancetype)numberWithUnsignedInteger32:(uint32_t)value;
+ (instancetype)numberWithInteger64:(int64_t)value;
+ (instancetype)numberWithUnsignedInteger64:(uint64_t)value;
+ (instancetype)numberWithBool:(BOOL)value;

- (instancetype)initWithInteger32:(int32_t)value NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithUnsignedInteger32:(uint32_t)value NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithInteger64:(int64_t)value NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithUnsignedInteger64:(uint64_t)value NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithBool:(BOOL)value NS_DESIGNATED_INITIALIZER;

- (BOOL)isEqualToNumber:(KPKNumber *)number;

@end
