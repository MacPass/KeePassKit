//
//  KPKTree+XML.m
//  MacPass
//
//  Created by Michael Starke on 16.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTree+XML.h"
#import "DDXMLDocument.h"

#define KPKAddElement(element, name, value) [element addChild:[DDXMLNode elementWithName:name stringValue:value]]
#define KPKStringFromLong(integer) [NSString stringWithFormat:@"%ld", integer]
#define KPKFormattedDate(formatter, date) [formatter stringFromDate:date]
#define KPKStringFromBool(bool) (bool ? @"True" : @"False" )

@implementation KPKTree (XML)

- (DDXMLDocument *)xmlDocument {
  
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
  dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
  
  DDXMLElement *element;
  
  DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:@"<KeePassFile></KeePassFile>" options:0 error:nil];
  
  element = [DDXMLNode elementWithName:@"Meta"];
  KPKAddElement(element, @"Generator", self.generator);
  KPKAddElement(element, @"DatabaseName", self.databaseName);
  KPKAddElement(element, @"DatabaseNameChanged", KPKFormattedDate(dateFormatter, self.databaseNameChanged));
  KPKAddElement(element, @"DatabaseDescription", self.databaseDescription);
  KPKAddElement(element, @"DatabaseDescriptionChanged", KPKFormattedDate(dateFormatter, self.databaseDescriptionChanged));
  KPKAddElement(element, @"DefaultUserName", self.defaultUserName);
  KPKAddElement(element, @"MaintenanceHistoryDays", KPKStringFromLong(self.maintenanceHistoryDays));
  KPKAddElement(element, @"Color", self.color);
  KPKAddElement(element, @"MasterKeyChanged", KPKFormattedDate(dateFormatter, self.masterKeyChanged));
  KPKAddElement(element, @"MasterKeyChangeRec", KPKStringFromLong(self.masterKeyChangeRec));
  KPKAddElement(element, @"MasterKeyChangeForce", KPKStringFromLong(self.masterKeyChangeForce));
  
  DDXMLElement *memoryProtectionElement = [DDXMLElement elementWithName:@"MemoryProtection"];
  KPKAddElement(memoryProtectionElement, @"ProtectTitle", KPKStringFromBool(self.protectTitle));
  KPKAddElement(memoryProtectionElement, @"ProtectUserName", KPKStringFromBool(self.protectUserName));
  KPKAddElement(memoryProtectionElement, @"ProtectPassword", KPKStringFromBool(self.protectPassword));
  KPKAddElement(memoryProtectionElement, @"ProtectURL", KPKStringFromBool(self.protectUrl));
  KPKAddElement(memoryProtectionElement, @"ProtectNotes", KPKStringFromBool(self.protectNotes));
  
  [element addChild:memoryProtectionElement];
  /*
  if ([self.customIcons count] > 0) {
    DDXMLElement *customIconsElements = [DDXMLElement elementWithName:@"CustomIcons"];
    for (CustomIcon *customIcon in self.customIcons) {
      [customIconsElements addChild:[self persistCustomIcon:customIcon]];
    }
    [element addChild:customIconsElements];
  }
  */
  
  KPKAddElement(element, @"RecycleBinEnabled", KPKStringFromBool(self.recycleBinEnabled));
  KPKAddElement(element, @"RecycleBinUUID", @"");
  /*
  
  [element addChild:[DDXMLNode elementWithName:@"RecycleBinEnabled"
                                   stringValue:self.recycleBinEnabled ? @"True" : @"False"]];
  [element addChild:[DDXMLNode elementWithName:@"RecycleBinUUID"
                                   stringValue:[self persistUuid:self.recycleBinUuid]]];
  [element addChild:[DDXMLNode elementWithName:@"RecycleBinChanged"
                                   stringValue:[dateFormatter stringFromDate:self.recycleBinChanged]]];
  [element addChild:[DDXMLNode elementWithName:@"EntryTemplatesGroup"
                                   stringValue:[self persistUuid:self.entryTemplatesGroup]]];
  [element addChild:[DDXMLNode elementWithName:@"EntryTemplatesGroupChanged"
                                   stringValue:[dateFormatter stringFromDate:self.entryTemplatesGroupChanged]]];
  [element addChild:[DDXMLNode elementWithName:@"HistoryMaxItems"
                                   stringValue:[NSString stringWithFormat:@"%ld", self.historyMaxItems]]];
  [element addChild:[DDXMLNode elementWithName:@"HistoryMaxSize"
                                   stringValue:[NSString stringWithFormat:@"%ld", self.historyMaxSize]]];
  [element addChild:[DDXMLNode elementWithName:@"LastSelectedGroup"
                                   stringValue:[self persistUuid:self.lastSelectedGroup]]];
  [element addChild:[DDXMLNode elementWithName:@"LastTopVisibleGroup"
                                   stringValue:[self persistUuid:self.lastTopVisibleGroup]]];
  
  DDXMLElement *binaryElements = [DDXMLElement elementWithName:@"Binaries"];
  for (Binary *binary in self.binaries) {
    [binaryElements addChild:[self persistBinary:binary]];
  }
  [element addChild:binaryElements];
  
  DDXMLElement *customDataElements = [DDXMLElement elementWithName:@"CustomData"];
  for (CustomItem *customItem in self.customData) {
    [customDataElements addChild:[self persistCustomItem:customItem]];
  }
  [element addChild:customDataElements];
  
  [document.rootElement addChild:element];
  
  element = [DDXMLNode elementWithName:@"Root"];
  [element addChild:[self persistGroup:(Kdb4Group *)self.root]];
  [document.rootElement addChild:element];
  */
  return document;
  
}

@end
