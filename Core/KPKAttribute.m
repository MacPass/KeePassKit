//
//  KPKAttribute.m
//  MacPass
//
//  Created by Michael Starke on 15.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKAttribute.h"
#import "KPKEntry.h"
#import "KPKFormat.h"
#import "KPKGroup.h"

#import "NSString+CommandString.h"

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
 
 Placeholder
 
 {TITLE}	Title
 {USERNAME}	User name
 {URL}	URL
 {PASSWORD}	Password
 {NOTES}	Notes
 {S:Name} CustomString Name
 
 {URL:RMVSCM}	Entry URL without scheme name.
 {URL:SCM}	Scheme name of the entry URL.
 {URL:HOST}	Host component of the entry URL.
 {URL:PORT}	Port number of the entry URL.
 {URL:PATH}	Path component of the entry URL.
 {URL:QUERY}	Query information of the entry URL.
 
 */

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
    if([self.entry hasAttributeWithKey:[*ioValue stringValue]]) {
      *ioValue = [self.entry proposedKeyForAttributeKey:@"Untitled"];
    }
  }
  return YES;
}

- (BOOL)isDefault {
  return [[KPKFormat sharedFormat] isDefautlKey:self.key];
}

- (BOOL)isReference {
  return [self.value isRefernce];
}

- (BOOL)isPlaceholder {
  return NO;
}

- (NSString *)referencedValue {
  KPKGroup *rootGroup = [self.entry rootGroup];
  // Determin what type to look for
  return nil;
}

- (NSString *)placeholderValue {
  return nil;
}

@end
