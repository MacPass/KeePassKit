//
//  NSNumber+TypedNumber.m
//  KeePassKit
//
//  Created by Michael Starke on 06/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "NSNumber+TypedNumber.h"
@import ObjectiveC;

@implementation NSNumber (TypedNumber)

+ (instancetype)typedNumberWithLong:(long)value {
  return [[NSNumber alloc] initTypedWithLong:value];
}

+ (instancetype)typedNumberWithUnsignedLong:(unsigned long)value {
  return [[NSNumber alloc] initTypedWithUnsignedLong:value];
}
+ (instancetype)typedNumberWithLongLong:(long long)value {
  return [[NSNumber alloc] initWithLongLong:value];
}
+ (instancetype)typedNumberWithUnsignedLongLong:(unsigned long long)value {
  return [[NSNumber alloc] initTypedWithUnsignedLongLong:value];
}

+ (instancetype)typedNumberWithBool:(BOOL)value {
  return [[NSNumber alloc] initTypedWithBool:value];
}

- (void)setType:(KPKNumberType)type {
  objc_setAssociatedObject(self, @selector(type), @(type), OBJC_ASSOCIATION_ASSIGN);
}

- (KPKNumberType)type {
  NSNumber *typeNumber = objc_getAssociatedObject(self, @selector(type));
  return typeNumber.unsignedIntegerValue;
}

- (instancetype)initTypedWithLong:(long)value {
  self = [self initWithLong:value];
  if(self) {
    self.type = kKPKNumberTypeInt32;
  }
  return self;
}

- (instancetype)initTypedWithUnsignedLong:(unsigned long)value {
  self = [self initWithUnsignedLong:value];
  if(self) {
    self.type = kKPKNumberTypeUInt32;
  }
  return self;
}

- (instancetype)initTypedWithLongLong:(long long)value {
  self = [self initWithLongLong:value];
  if(self) {
    self.type = kKPKNumberTypeInt64;
  }
  return self;
}
- (instancetype)initTypedWithUnsignedLongLong:(unsigned long long)value {
  self = [self initWithUnsignedLongLong:value];
  if(self) {
    self.type = kKPKNumberTypeUInt64;
  }
  return self;
}

- (instancetype)initTypedWithBool:(BOOL)value {
  self = [self initWithBool:value];
  if(self) {
    self.type = kKPKNumberTypeBool;
  }
  return self;
}


@end
