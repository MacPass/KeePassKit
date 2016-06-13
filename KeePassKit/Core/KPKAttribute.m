//
//  KPKAttribute.m
//  KeePassKit
//
//  Created by Michael Starke on 15.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "KPKAttribute.h"
#import "KPKEntry.h"
#import "KPKFormat.h"
#import "KPKGroup.h"
#import "KPKErrors.h"

#import "NSString+Commands.h"
#import "NSString+XMLUtilities.h"
#import "NSData+Random.h"
#import "NSMutableData+KeePassKit.h"
/*
 References are formatted as follows:
 T	Title
 U	User name
 P	Password
 A	URL
 N	Notes
 I	UUID
 O	Other custom strings (KeePass 2.x only)
 
 {REF:P@I:46C9B1FFBD4ABC4BBB260C6190BAD20C}
 {REF:<WantedField>@<SearchIn>:<Text>}
*/

@interface KPKAttribute () {
  NSUInteger _lenght;
  NSData *_xorPad;
  NSMutableData *_protectedData;
}
@end

@implementation KPKAttribute

@dynamic editable;

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)initWithKey:(NSString *)key value:(NSString *)value isProtected:(BOOL)protected {
  self = [super init];
  if(self) {
    [self _encodeValue:value];
    _key = [key copy];
    _isProtected = protected;
  }
  return self;
}

- (instancetype)initWithKey:(NSString *)key value:(NSString *)value {
  return [self initWithKey:key value:value isProtected:NO];
}

- (instancetype)init {
  return [self initWithKey:@"" value:@"" isProtected:NO];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [self init];
  if(self) {
    _key = [aDecoder decodeObjectOfClass:[NSString class] forKey:@"key"];
    _xorPad = [aDecoder decodeObjectOfClass:[NSData class] forKey:@"xorPad"];
    _protectedData = [aDecoder decodeObjectOfClass:[NSData class] forKey:@"protectedData"];
    _isProtected = [aDecoder decodeBoolForKey:@"isProtected"];
    _lenght = [aDecoder decodeIntegerForKey:@"lenght"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeBool:self.isProtected forKey:@"isProtected"];
  [aCoder encodeObject:self.key forKey:@"key"];
  [aCoder encodeObject:_xorPad forKey:@"xorPad"];
  [aCoder encodeObject:_protectedData forKey:@"protectedData"];
  [aCoder encodeInteger:_lenght forKey:@"lenght"];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[KPKAttribute allocWithZone:zone] initWithKey:self.key value:self.value isProtected:self.isProtected];
}

- (BOOL)isEqual:(id)object {
  if([object isKindOfClass:[self class]]) {
    return [self isEqualToAttribute:object];
  }
  return NO;
}

- (BOOL)isEqualToAttribute:(KPKAttribute *)attribtue {
  NSAssert([attribtue isKindOfClass:[self class]], @"Only KPKAttributes are allowed in this test");
  return ([self.value isEqualToString:attribtue.value]
          && [self.key isEqualToString:attribtue.key]);
}

- (BOOL)validateKey:(inout __autoreleasing id *)ioValue error:(out NSError *__autoreleasing *)outError {
  if(![*ioValue isKindOfClass:[NSString class]] ) {
    KPKCreateError(outError, KPKErrorAttributeKeyValidationFailed, @"ERROR_ATTRIBUTE_KEY_VALIDATION_FAILED", "");
    return NO; // No string, so we cannot process it further
  }
  /* We need to make the key valid, as they are never protected */
  *ioValue = ((NSString *)*ioValue).XMLCompatibleString;
  if([self.entry hasAttributeWithKey:*ioValue]) {
    NSString *copy = [*ioValue copy];
    *ioValue = [self.entry proposedKeyForAttributeKey:copy];
  }
  return YES;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"Key:%@ Value:%@", self.key, self.value];
}

- (NSString *)value {
  return [self _decodedValue];
}

- (NSString *)evaluatedValue {
  return [self.value finalValueForEntry:self.entry];
}

- (void)setValue:(NSString *)value {
  [self.entry touchModified];
  [self _encodeValue:value];
}

- (void)setKey:(NSString *)key {
  if(![_key isEqualToString:key]) {
    [self.entry touchModified];
    _key = [key copy];
  }
}

- (BOOL)isDefault {
  return [[KPKFormat sharedFormat].entryDefaultKeys containsObject:self.key];
}

- (BOOL)isEditable {
  if(!self.entry) {
    return YES;
  }
  return self.entry.isEditable;
}

- (NSString *)referencedValue {
  //KPKGroup *rootGroup = [self.entry rootGroup];
  // Determin what type to look for
  return nil;
}

- (NSString *)placeholderValue {
  return nil;
}

- (void)_encodeValue:(NSString *)string {
  NSMutableData *stringData = [[string dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
  _lenght = stringData.length;
  if(_xorPad.length < _lenght) {
    _xorPad = [NSData dataWithRandomBytes:_lenght];
  }
  [stringData xorWithKey:_xorPad];
  if(!_protectedData) {
    _protectedData = stringData;
  }
  else {
    [_protectedData setData:stringData];
  }
}

- (NSString *)_decodedValue {
  if(_lenght == 0) {
    return @"";
  }
  NSMutableData *stringData = [_protectedData mutableCopy];
  [stringData xorWithKey:_xorPad];
  return [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];
}

@end
