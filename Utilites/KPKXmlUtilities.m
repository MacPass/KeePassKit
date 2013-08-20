//
//  KPKXmlUtilities.c
//  MacPass
//
//  Created by Michael Starke on 20.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKXmlUtilities.h"
#import <Foundation/Foundation.h>
#import "DDXMLElementAdditions.h"

#pragma mark Writing Helper

void KPKAddXmlElement(DDXMLElement *element, NSString *name, NSString *value) {
  [element addChild:[DDXMLNode elementWithName:name stringValue:value]];
}

void KPKAddXmlAttribute(DDXMLElement *element, NSString *name, NSString *value) {
  [element addAttributeWithName:name stringValue:value];
}

NSString * KPKStringFromLong(NSInteger integer) {
  return [NSString stringWithFormat:@"%ld", integer];
}

NSString *KPKStringFromDate(NSDateFormatter *dateFormatter, NSDate *date){
  return [dateFormatter stringFromDate:date];
}

NSString *KPKStringFromBool(BOOL value) {
  return (value ? @"True" : @"False" );
}

NSString *stringFromInhertiBool(KPKInheritBool value) {
  switch(value) {
    case KPKInherit:
      return @"null";
      
    case KPKInheritYES:
      return @"True";
      
    case KPKInheritNO:
      return @"False";
  }
}

#pragma mark Reading Helper

BOOL KPKXmlTrue(DDXMLNode *attribute) {
  return (NSOrderedSame == [[attribute stringValue] caseInsensitiveCompare:@"True"]);
}

BOOL KPKXmlFalse(DDXMLNode *attribute) {
  return (NSOrderedSame == [[attribute stringValue] caseInsensitiveCompare:@"False"]);
}

NSString *KPKXmlString(DDXMLElement *element, NSString *name) {
  return [[element elementForName:name] stringValue];
}

NSInteger KPKXmlInteger(DDXMLElement *element, NSString *name) {
  return [[[element elementForName:name] stringValue] integerValue];
}

BOOL KPKXmlBool(DDXMLElement *element, NSString *name) {
  return [[[element elementForName:name] stringValue] boolValue];
}

BOOL KPKXmlBoolAttribute(DDXMLElement *element, NSString *attribute) {
  DDXMLNode *node = [element attributeForName:attribute];
  if(KPKXmlTrue(node)) return YES;
  return NO;
}

NSDate *KPKXmlDate(NSDateFormatter *dateFormatter, DDXMLElement *element, NSString *name) {
  return [dateFormatter dateFromString:[[element elementForName:name] stringValue]];
}

KPKInheritBool parseInheritBool(DDXMLElement *element, NSString *name) {
  NSString *stringValue = [[element elementForName:name] stringValue];
  if (NSOrderedSame == [stringValue caseInsensitiveCompare:@"null"]) {
    return KPKInherit;
  }
  
  if (KPKXmlTrue(element)) return KPKInheritYES;
  if (KPKXmlFalse(element)) return KPKInherit;
  return KPKInherit;
}
