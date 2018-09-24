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
#import "KPKAttribute_Private.h"
#import "KPKEntry.h"
#import "KPKFormat.h"
#import "KPKGroup.h"
#import "KPKErrors.h"

#import "KPKData.h"

#import "NSString+KPKCommands.h"
#import "NSString+KPKXmlUtilities.h"
#import "NSData+KPKRandom.h"
#import "NSData+KPKXor.h"

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

@interface KPKAttribute ()

@property (strong) KPKData *data;

@end

@implementation KPKAttribute

@dynamic editable;

+ (BOOL)supportsSecureCoding {
  return YES;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingEditable {
  
  static NSSet *pathSet;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSString *entryHistoryPath = [NSString stringWithFormat:@"%@.%@", NSStringFromSelector(@selector(entry)), NSStringFromSelector(@selector(isEditable))];
    pathSet = [NSSet setWithArray:@[ NSStringFromSelector(@selector(entry)), entryHistoryPath ]];
  });
  return pathSet;
}

- (instancetype)initWithKey:(NSString *)key value:(NSString *)value isProtected:(BOOL)protected {
  self = [super init];
  if(self) {
    [self _encodeValue:value];
    _key = [key copy];
    _protect = protected;
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
    self.key = [aDecoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(key))];
    self.protect = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(protect))];
    self.data = [aDecoder decodeObjectOfClass:KPKData.class forKey:NSStringFromSelector(@selector(data))];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeBool:self.protect forKey:NSStringFromSelector(@selector(protect))];
  [aCoder encodeObject:self.key forKey:NSStringFromSelector(@selector(key))];
  [aCoder encodeObject:self.data forKey:NSStringFromSelector(@selector(data))];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [[KPKAttribute allocWithZone:zone] initWithKey:self.key value:self.value isProtected:self.protect];
}

- (BOOL)isEqual:(id)object {
  if(self == object) {
    return YES;
  }
  if([object isKindOfClass:self.class]) {
    return [self isEqualToAttribute:object];
  }
  return NO;
}

- (BOOL)isEqualToAttribute:(KPKAttribute *)attribute {
  if(self == attribute) {
    return YES;
  }
  NSAssert([attribute isKindOfClass:self.class], @"Only KPKAttributes are allowed in this test");
  return ([self.value isEqualToString:attribute.value]
          && [self.key isEqualToString:attribute.key]);
}

- (BOOL)validateKey:(inout __autoreleasing id *)ioValue error:(out NSError *__autoreleasing *)outError {
  if(![*ioValue isKindOfClass:NSString.class] ) {
    KPKCreateError(outError, KPKErrorAttributeKeyValidationFailed);
    return NO; // No string, so we cannot process it further
  }
  /* We need to make the key valid, as they are never protected */
  *ioValue = ((NSString *)*ioValue).kpk_xmlCompatibleString;
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
  return [self.value kpk_finalValueForEntry:self.entry];
}

- (void)setValue:(NSString *)value {
  if(self.value != value) {
    if(!self.isDefault) {
      [(KPKAttribute *)[self.entry.undoManager prepareWithInvocationTarget:self] setValue:self.value];
      NSString *template = NSLocalizedStringFromTableInBundle(@"SET_CUSTOM_ATTTRIBUTE_%@", nil, [NSBundle bundleForClass:[self class]], @"Action name for setting value of a custom attribute. Contains %@ placeholder");
      [self.entry.undoManager setActionName:[NSString stringWithFormat:template, self.key ]];
    }
    [self.entry touchModified];
    [self _encodeValue:value];
  }
}

- (void)setKey:(NSString *)key {
  if(![_key isEqualToString:key]) {
    if([self.entry hasAttributeWithKey:key]) {
      key = [self.entry proposedKeyForAttributeKey:key];
    }
    [[self.entry.undoManager prepareWithInvocationTarget:self] setKey:self.key];
    [self.entry touchModified];
    _key = [key copy];
  }
}

- (void)setProtect:(BOOL)protected {
  if(_protect != protected) {
    if(!self.isDefault) {
      [[self.entry.undoManager prepareWithInvocationTarget:self] setProtect:_protect];
      if(protected) {
        NSString *template = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"PROTECT_%@", nil, [NSBundle bundleForClass:self.class], @"Action name for setting a custom string value protected"), self.key];
        [self.entry.undoManager setActionName:template];
      }
      else {
        NSString *template = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"PROTECT_%@", nil, [NSBundle bundleForClass:self.class], @"Action name for setting a custom string value protected"), self.key];
        [self.entry.undoManager setActionName:template];
      }
    }
    _protect = protected;
  }
}

- (BOOL)isDefault {
  return [KPKFormat.sharedFormat.entryDefaultKeys containsObject:self.key];
}

- (BOOL)isEditable {
  if(!self.entry) {
    return YES;
  }
  return self.entry.isEditable;
}

- (void)_encodeValue:(NSString *)string {
  if(!self.data) {
    self.data = [[KPKData alloc] init];
  }
  self.data.data = [string dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)_decodedValue {
  if(self.data.data.length == 0) {
    return @"";
  }
  return [[NSString alloc] initWithData:self.data.data encoding:NSUTF8StringEncoding];
}

@end
