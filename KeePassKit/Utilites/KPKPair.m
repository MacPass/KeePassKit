//
//  KPKPair.m
//  KeePassKit
//
//  Created by Michael Starke on 12.05.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "KPKPair.h"
#import "KPKPair_Private.h"

@implementation KPKPair

+ (instancetype)pairWithKey:(NSString *)key value:(NSString *)value {
  return [[KPKPair alloc] initWithKey:key value:value];
}

- (instancetype)initWithKey:(NSString *)key value:(NSString *)value {
  self = [super init];
  if(self) {
    _key = [key copy];
    _value = [value copy];
  }
  return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [KPKPair pairWithKey:self.key value:self.value];
}

- (BOOL)isEqual:(id)object {
  return [self isEqualToPair:object];
}

- (BOOL)isEqualToPair:(KPKPair *)pair {
  if(self == pair) {
    return YES;
  }
  if(![pair isKindOfClass:KPKPair.class]) {
    return NO;
  }
  return ([self.key isEqualToString:pair.key] && [self.value isEqualToString:pair.value]);
}

- (NSUInteger)hash {
  return ((self.value.hash + 21) ^ self.key.hash);
}

@end

@implementation KPKMutablePair

@dynamic value;
@dynamic key;

- (void)setKey:(NSString *)key {
  if(![_key isEqualToString:key]) {
    _key = [key copy];
  }
}

- (void)setValue:(NSString *)value {
  if(![_value isEqualToString:value]) {
    _value = [value copy];
  }
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [KPKMutablePair pairWithKey:self.key value:self.value];
}


@end
