//
//  KPKModifiedString.m
//  KeePassKit
//
//  Created by Michael Starke on 07.10.21.
//  Copyright © 2021 HicknHack Software GmbH. All rights reserved.
//

#import "KPKModifiedString.h"

@interface KPKModifiedString ()

@property (nullable, copy) NSDate *modificationDate;

@end

@implementation KPKModifiedString

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)initWithValue:(NSString *)value modificationDate:(NSDate *)date {
  self = [super init];
  if(self) {
    NSAssert(value != nil, @"value cannot be nil. Use empty string instaead!");
    _value = [value copy];
    _modificationDate = [date copy];
  }
  return self;
}

- (instancetype)initWithValue:(NSString *)value {
  self = [self initWithValue:value modificationDate:nil];
  return self;
}

- (instancetype)init {
  self = [self initWithValue:@"" modificationDate:nil];
  return self;
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.value forKey:NSStringFromSelector(@selector(value))];
  [coder encodeObject:self.modificationDate forKey:NSStringFromSelector(@selector(modificationDate))];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  NSString *value = [coder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(value))];
  NSDate *date = [coder decodeObjectOfClass:NSDate.class forKey:NSStringFromSelector(@selector(modificationDate))];
  if(value == nil) {
    value = @"";
  }
  self = [self initWithValue:value modificationDate:date];
  return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
  KPKModifiedString *copy = [[KPKModifiedString alloc] initWithValue:self.value modificationDate:self.modificationDate];
  return copy;
}

- (BOOL)isEqual:(id)object {
  if(object == self) {
    return YES;
  }
  if([object isKindOfClass:KPKModifiedString.class]) {
    return [self isEqualToModifiedString:object];
  }
  return NO;
}

- (NSUInteger)hash {
  return (self.value.hash ^ self.modificationDate.hash);
}

- (BOOL)isEqualToModifiedString:(KPKModifiedString *)other {
  if(self == other) {
    return YES;
  }
  return ([self.value isEqualToString:other.value] && [self.modificationDate isEqualToDate:other.modificationDate]);
}

- (void)setValue:(NSString *)value {
  _value = [value copy];
  self.modificationDate = NSDate.date;
}

@end
