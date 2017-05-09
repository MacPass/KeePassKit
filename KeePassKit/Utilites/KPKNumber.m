//
//  KPKNumber.m
//  KeePassKit
//
//  Created by Michael Starke on 14/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKNumber.h"



@interface KPKNumber ()

@property (copy) NSNumber *number;
@property KPKNumberType type;
@end

@implementation KPKNumber

+ (instancetype)numberWithInteger32:(int32_t)value {
  return [[KPKNumber alloc] initWithInteger32:value];
}

+ (instancetype)numberWithUnsignedInteger32:(uint32_t)value {
  return [[KPKNumber alloc] initWithUnsignedInteger32:value];
}

+ (instancetype)numberWithInteger64:(int64_t)value {
  return [[KPKNumber alloc] initWithInteger64:value];
}

+ (instancetype)numberWithUnsignedInteger64:(uint64_t)value {
  return [[KPKNumber alloc] initWithUnsignedInteger64:value];
}

+ (instancetype)numberWithBool:(BOOL)value {
  return [[KPKNumber alloc] initWithBool:value];
}

- (instancetype)init {
  self = [self initWithBool:NO];
  return self;
}

- (instancetype)initWithInteger32:(int32_t)value {
  self = [super init];
  if(self) {
    self.number = [[NSNumber alloc] initWithLong:value];
    self.type = KPKNumberTypeInteger32;
  }
  return self;
}

- (instancetype)initWithUnsignedInteger32:(uint32_t)value {
  self = [super init];
  if(self) {
    self.number = [[NSNumber alloc] initWithUnsignedLong:value];
    self.type = KPKNumberTypeUnsignedInteger32;
  }
  return self;
}

- (instancetype)initWithInteger64:(int64_t)value  {
  self = [super init];
  if(self) {
    self.number = [[NSNumber alloc] initWithLongLong:value];
    self.type = KPKNumberTypeInteger64;
  }
  return self;
}

- (instancetype)initWithUnsignedInteger64:(uint64_t)value {
  self = [super init];
  if(self) {
    self.number = [[NSNumber alloc] initWithUnsignedLongLong:value];
    self.type = KPKNumberTypeUnsignedInteger64;
  }
  return self;
}

- (instancetype)initWithBool:(BOOL)value {
  self = [super init];
  if(self) {
    self.number = [[NSNumber alloc] initWithBool:value];
    self.type = KPKNumberTypeBool;
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  KPKNumber *copy = [[KPKNumber alloc] init];
  copy.number = self.number;
  copy.type = self.type;
  return copy;
}

- (NSUInteger)hash {
  return (self.type ^ self.number.hash);
}

- (BOOL)isEqual:(id)object {
  if(![object isKindOfClass:KPKNumber.class]) {
    return NO;
  }
  return [self isEqualToNumber:object];
}

- (BOOL)isEqualToNumber:(KPKNumber *)number {
  if(self.type != number.type) {
    return NO;
  }
  return [self.number isEqualToNumber:number.number];
}

- (int32_t)integer32Value {
  /* explicit cast for 64bit systems */
  [self _checkTypeConversion:KPKNumberTypeInteger32];
  return (int32_t)self.number.longValue;
}

- (uint32_t)unsignedInteger32Value {
  [self _checkTypeConversion:KPKNumberTypeUnsignedInteger32];
  return (uint32_t)self.number.unsignedLongLongValue;
}

- (int64_t)integer64Value {
  [self _checkTypeConversion:KPKNumberTypeInteger64];
  return self.number.longLongValue;
}

- (uint64_t)unsignedInteger64Value {
  [self _checkTypeConversion:KPKNumberTypeUnsignedInteger64];
  return self.number.unsignedLongLongValue;
}

- (BOOL)boolValue {
  [self _checkTypeConversion:KPKNumberTypeBool];
  return self.number.boolValue;
}

- (void)_checkTypeConversion:(KPKNumberType)type {
  static NSDictionary *typeNames;
  if(!typeNames) {
    typeNames = @{ @(KPKNumberTypeBool) : @"Bool",
                   @(KPKNumberTypeInteger32) : @"int32_t",
                   @(KPKNumberTypeInteger64) : @"int64_t",
                   @(KPKNumberTypeUnsignedInteger32) : @"uint32_t",
                   @(KPKNumberTypeUnsignedInteger64) : @"uint64_t" };
  }
  if(self.type != type) {
    NSLog(@"Warnging. Requesting casted type %@. Native type is %@", typeNames[@(type)], typeNames[@(self.type)]);
  }
}

@end
