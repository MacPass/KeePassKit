//
//  KPKAttribute.m
//  MacPass
//
//  Created by Michael Starke on 15.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKAttribute.h"
#import "KPKEntry.h"

@implementation KPKAttribute
/**
 Designeted initalizer
 */
- (id)initWithKey:(NSString *)key value:(NSString *)value protected:(BOOL)protected {
  self = [super init];
  if(self) {
    _key = [key copy];
    _value = [value copy];
    _protected = protected;
  }
  return self;
}

- (id)initWithKey:(NSString *)key value:(NSString *)value {
  return [self initWithKey:key value:value protected:NO];
}

- (id)init {
  return  [self initWithKey:nil value:nil protected:NO];
}

- (id)copyWithZone:(NSZone *)zone {
  return [[KPKAttribute allocWithZone:zone] initWithKey:self.key value:self.value protected:self.protected];
}

- (BOOL)validateValue:(inout __autoreleasing id *)ioValue forKey:(NSString *)inKey error:(out NSError *__autoreleasing *)outError {
  if([inKey isEqualToString:@"key"]) {
    [self.entry hasAttributeWithKey:[*ioValue stringValue]];
  }
  return YES;
}

@end
