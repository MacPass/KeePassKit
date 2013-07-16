//
//  KPKTree+XML.m
//  MacPass
//
//  Created by Michael Starke on 16.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTree+XML.h"
#import "DDXMLDocument.h"
#import "NSUUID+KeePassKit.h"

#import "KPKGroup.h"
#import "KPKEntry.h"

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
  KPKAddElement(element, @"RecycleBinUUID", [self.recycleBinUuid encodedString]);
  KPKAddElement(element, @"RecycleBinChanged", KPKFormattedDate(dateFormatter, self.recycleBinChanged));
  KPKAddElement(element, @"EntryTemplatesGroup", [self.entryTemplatesGroup encodedString]);
  KPKAddElement(element, @"EntryTemplatesGroupChanged", KPKFormattedDate(dateFormatter, self.entryTemplatesGroupChanged));
  KPKAddElement(element, @"HistoryMaxItems", KPKStringFromLong(self.historyMaxItems));
  KPKAddElement(element, @"HistoryMaxSize", KPKStringFromLong(self.historyMaxItems));
  KPKAddElement(element, @"LastSelectedGroup", [self.lastSelectedGroup encodedString]);
  KPKAddElement(element, @"LastTopVisibleGroup", [self.lastTopVisibleGroup encodedString]);
  
  
  /*
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

- (DDXMLElement *)_xmlGroup:(KPKGroup *)group {
  DDXMLElement *groupElement = [DDXMLNode elementWithName:@"Group"];
  
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
  dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
  
  // Add the standard properties
  KPKAddElement(groupElement, @"UUID", [group.uuid encodedString]);
  KPKAddElement(groupElement, @"Name", group.name);
  KPKAddElement(groupElement, @"Notes", group.notes);
  KPKAddElement(groupElement, @"IconId", KPKStringFromLong(group.image));
  
  DDXMLElement *timesElement = [DDXMLNode elementWithName:@"Times"];
  KPKAddElement(timesElement, @"LastModificationTime", KPKFormattedDate(dateFormatter, group.lastModificationTime));
  KPKAddElement(timesElement, @"dateFormatter", KPKFormattedDate(dateFormatter, group.creationTime));
  KPKAddElement(timesElement, @"LastAccessTime", KPKFormattedDate(dateFormatter, group.lastAccessTime));
  KPKAddElement(timesElement, @"ExpiryTime", KPKFormattedDate(dateFormatter, group.expiryTime));
  KPKAddElement(timesElement, @"Expires", KPKStringFromBool(group.expires));
  // FIXME: Add additional properties to group/node/entry
  //KPKAddElement(timesElement, @"UsageCount", group.usageCount)
  //KPKAddElement(timesElement, @"LocationChanged", value)
  [groupElement addChild:timesElement];
  
  /*
  [groupElement addChild:[DDXMLNode elementWithName:@"IsExpanded"
                                        stringValue:group.isExpanded ? @"True" : @"False"]];
  [groupElement addChild:[DDXMLNode elementWithName:@"DefaultAutoTypeSequence"
                                        stringValue:group.defaultAutoTypeSequence]];
  [groupElement addChild:[DDXMLNode elementWithName:@"EnableAutoType"
                                        stringValue:group.enableAutoType]];
  [groupElement addChild:[DDXMLNode elementWithName:@"EnableSearching"
                                        stringValue:group.enableSearching]];
  [groupElement addChild:[DDXMLNode elementWithName:@"LastTopVisibleEntry"
                                        stringValue:[self persistUuid:group.lastTopVisibleEntry]]];
  
  for (Kdb4Entry *entry in group.entries) {
    [groupElement addChild:[self persistEntry:entry includeHistory:YES]];
  }
  */
  for (KPKGroup *subGroup in group.groups) {
    [groupElement addChild:[self _xmlGroup:subGroup]];
  }
  
  return groupElement;
}

@end
