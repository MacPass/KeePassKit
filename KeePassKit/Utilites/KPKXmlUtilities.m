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

#import "NSDate+KPKAdditions.h"

#import <Foundation/Foundation.h>
#import <KissXML/KissXML.h>

static NSDate *referenceDate(void) {
  static NSDate *referenceDate;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    components.calendar = calendar;
    components.year = 1;
    components.month = 1;
    components.day = 3; // Specs say 1 but there seems to be an issue with dotNet epoch date so we move up 2 days
    components.hour = 0;
    components.minute = 0;
    referenceDate = [components date];
  });
  return referenceDate;
}

#pragma mark Writing Helper

void KPKAddXmlElement(DDXMLElement *element, NSString *name, NSString *value) {
  [element addChild:[DDXMLNode elementWithName:name stringValue:value]];
}

void KPKAddXmlElementIfNotNil(DDXMLElement *element, NSString *name, NSString *value) {
  if(nil != value) {
    KPKAddXmlElement(element, name, value);
  }
}

void KPKAddXmlAttribute(DDXMLElement *element, NSString *name, NSString *value) {
  [element addAttributeWithName:name stringValue:value];
}

NSString * KPKStringFromLong(NSInteger integer) {
  return [NSString stringWithFormat:@"%ld", (long)integer];
}

NSString *KPKStringFromDate(NSDate *date, BOOL isRelativeDate) {
  if(isRelativeDate) {
    uint64_t interval = CFSwapInt64HostToLittle([date timeIntervalSinceDate:referenceDate()]);
    
    return [[NSData dataWithBytesNoCopy:&interval length:8 freeWhenDone:NO] base64EncodedStringWithOptions:0];
  }
  return date.kpk_UTCString;
}

NSString *KPKStringFromBool(BOOL value) {
  return (value ? @"True" : @"False" );
}

NSString *stringFromInheritBool(KPKInheritBool value) {
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

NSDate *KPKXmlDate(DDXMLElement *element, NSString *name, BOOL isRelativeDate) {
  NSString *value = [[element elementForName:name] stringValue];
  if(nil == value) {
    return nil;
  }
  if(isRelativeDate) {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if(data.length != 8) {
      NSLog(@"Invalid date format!");
      return nil;
    }
    uint64_t interval;
    [data getBytes:&interval length:8];
    interval = CFSwapInt64LittleToHost(interval);
    return [referenceDate() dateByAddingTimeInterval:interval];
  }
  return [NSDate kpk_dateFromUTCString:value];
}

KPKInheritBool parseInheritBool(DDXMLElement *element, NSString *name) {
  DDXMLNode *boolElement = [element elementForName:name];
  NSString *stringValue = [boolElement stringValue];
  if (NSOrderedSame == [stringValue caseInsensitiveCompare:@"null"]) {
    return KPKInherit;
  }
  
  if(KPKXmlTrue(boolElement)) {
    return KPKInheritYES;
  }
  if(KPKXmlFalse(boolElement)) {
    return KPKInheritNO;
  }
  return KPKInherit;
}


