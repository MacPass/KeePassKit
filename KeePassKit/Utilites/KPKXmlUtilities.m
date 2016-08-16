//
//  KPKXmlUtilities.c
//  KeePassKit
//
//  Created by Michael Starke on 20.08.13.
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

#import "KPKXmlUtilities.h"
#import <Foundation/Foundation.h>
#import "DDXMLElementAdditions.h"

#pragma mark Writing Helper

void KPKAddXmlElement(DDXMLElement *element, NSString *name, NSString *value) {
  [element addChild:[DDXMLNode elementWithName:name stringValue:value]];
}

void KPKAddXmlElementIfNotNil(DDXMLElement *element, NSString *name, NSString *value) {
  if(nil != value) {
    KPKAddXmlElement(element, name, value);
  }
}

void KPKAddXmlElementIfNotEmtpy(DDXMLElement *element, NSString *name, NSString *value) {
  if(value.length > 0) {
    KPKAddXmlElement(element, name, value);
  }
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
  return (attribute && NSOrderedSame == [[attribute stringValue] caseInsensitiveCompare:@"True"]);
}

BOOL KPKXmlFalse(DDXMLNode *attribute) {
  return (attribute && NSOrderedSame == [[attribute stringValue] caseInsensitiveCompare:@"False"]);
}

NSString *KPKXmlString(DDXMLElement *element, NSString *name) {
  return [[element elementForName:name] stringValue];
}

NSString *KPKXmlNonEmptyString(DDXMLElement *element, NSString *name) {
  NSString *string = KPKXmlString(element, name);
  return string.length > 0 ? string : nil;
}

NSInteger KPKXmlInteger(DDXMLElement *element, NSString *name) {
  return [[element elementForName:name] stringValue].integerValue;
}

BOOL KPKXmlBool(DDXMLElement *element, NSString *name) {
  return [[element elementForName:name] stringValue].boolValue;
}

BOOL KPKXmlBoolAttribute(DDXMLElement *element, NSString *attribute) {
  DDXMLNode *node = [element attributeForName:attribute];
  if(KPKXmlTrue(node)) {
    return YES;
  }
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
  
  if(KPKXmlTrue(element)) {
    return KPKInheritYES;
  }
  if(KPKXmlFalse(element)) {
    return KPKInheritNO;
  }
  return KPKInherit;
}
