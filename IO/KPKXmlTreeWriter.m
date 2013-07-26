//
//  KPKXmlTreeWriter.m
//  KeePassKit
//
//  Created by Michael Starke on 16.07.13.
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

#import "KPKXmlTreeWriter.h"
#import "KPKTree.h"

#import "DDXMLDocument.h"
#import "DDXMLElementAdditions.h"
#import "NSUUID+KeePassKit.h"

#import "KPKFormat.h"
#import "KPKGroup.h"
#import "KPKEntry.h"
#import "KPKMetaData.h"
#import "KPKTimeInfo.h"
#import "KPKDeletedNode.h"
#import "KPKBinary.h"
#import "KPKIcon.h"

#define KPKAddElement(element, name, value) [element addChild:[DDXMLNode elementWithName:name stringValue:value]]
#define KPKAddAttribute(element, name, value) [element addAttributeWithName:name stringValue:value];
#define KPKStringFromLong(integer) [NSString stringWithFormat:@"%ld", integer]
#define KPKFormattedDate(date) [_dateFormatter stringFromDate:date]
#define KPKStringFromBool(bool) (bool ? @"True" : @"False" )

@interface KPKXmlTreeWriter () {
  NSDateFormatter *_dateFormatter;
  NSMutableArray *_binaries;
  NSMutableDictionary *_entryToBinaryMap;
}

@property (strong, readwrite) KPKTree *tree;

@end

@implementation KPKXmlTreeWriter

- (id)initWithTree:(KPKTree *)tree {
  self = [super init];
  if(self) {
    _tree = tree;
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    _dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
  }
  return self;
}

- (DDXMLDocument *)xmlDocument {
  
  DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:@"<KeePassFile></KeePassFile>" options:0 error:nil];
  
  DDXMLElement *element = [DDXMLNode elementWithName:@"Meta"];
  KPKAddElement(element, @"Generator", self.tree.metadata.generator);
  KPKAddElement(element, @"DatabaseName", self.tree.metadata.databaseName);
  KPKAddElement(element, @"DatabaseNameChanged", KPKFormattedDate(self.tree.metadata.databaseNameChanged));
  KPKAddElement(element, @"DatabaseDescription", self.tree.metadata.databaseDescription);
  KPKAddElement(element, @"DatabaseDescriptionChanged", KPKFormattedDate(self.tree.metadata.databaseDescriptionChanged));
  KPKAddElement(element, @"DefaultUserName", self.tree.metadata.defaultUserName);
  KPKAddElement(element, @"MaintenanceHistoryDays", KPKStringFromLong(self.tree.metadata.maintenanceHistoryDays));
  KPKAddElement(element, @"Color", self.tree.metadata.color);
  KPKAddElement(element, @"MasterKeyChanged", KPKFormattedDate(self.tree.metadata.masterKeyChanged));
  KPKAddElement(element, @"MasterKeyChangeRec", KPKStringFromLong(self.tree.metadata.masterKeyChangeIsRequired));
  KPKAddElement(element, @"MasterKeyChangeForce", KPKStringFromLong(self.tree.metadata.masterKeyChangeIsForced));
  
  DDXMLElement *memoryProtectionElement = [DDXMLElement elementWithName:@"MemoryProtection"];
  KPKAddElement(memoryProtectionElement, @"ProtectTitle", KPKStringFromBool(self.tree.metadata.protectTitle));
  KPKAddElement(memoryProtectionElement, @"ProtectUserName", KPKStringFromBool(self.tree.metadata.protectUserName));
  KPKAddElement(memoryProtectionElement, @"ProtectPassword", KPKStringFromBool(self.tree.metadata.protectPassword));
  KPKAddElement(memoryProtectionElement, @"ProtectURL", KPKStringFromBool(self.tree.metadata.protectUrl));
  KPKAddElement(memoryProtectionElement, @"ProtectNotes", KPKStringFromBool(self.tree.metadata.protectNotes));
  
  [element addChild:memoryProtectionElement];
  
  if ([self.tree.metadata.customIcons count] > 0) {
    [element addChild:[self _xmlIcons]];
  }
  
  KPKAddElement(element, @"RecycleBinEnabled", KPKStringFromBool(self.tree.metadata.recycleBinEnabled));
  KPKAddElement(element, @"RecycleBinUUID", [self.tree.metadata.recycleBinUuid encodedString]);
  KPKAddElement(element, @"RecycleBinChanged", KPKFormattedDate(self.tree.metadata.recycleBinChanged));
  KPKAddElement(element, @"EntryTemplatesGroup", [self.tree.metadata.entryTemplatesGroup encodedString]);
  KPKAddElement(element, @"EntryTemplatesGroupChanged", KPKFormattedDate(self.tree.metadata.entryTemplatesGroupChanged));
  KPKAddElement(element, @"HistoryMaxItems", KPKStringFromLong(self.tree.metadata.historyMaxItems));
  KPKAddElement(element, @"HistoryMaxSize", KPKStringFromLong(self.tree.metadata.historyMaxItems));
  KPKAddElement(element, @"LastSelectedGroup", [self.tree.metadata.lastSelectedGroup encodedString]);
  KPKAddElement(element, @"LastTopVisibleGroup", [self.tree.metadata.lastTopVisibleGroup encodedString]);
  
  [element addChild:[self _xmlBinaries]];
  
  /*
   DDXMLElement *customDataElements = [DDXMLElement elementWithName:@"CustomData"];
   for (CustomItem *customItem in self.tree.customData) {
   [customDataElements addChild:[self persistCustomItem:customItem]];
   }
   [element addChild:customDataElements];
   
   [document.rootElement addChild:element];
   
   element = [DDXMLNode elementWithName:@"Root"];
   [element addChild:[self persistGroup:(Kdb4Group *)self.tree.root]];
   [document.rootElement addChild:element];
   */
  
  if([self.tree.deletedObjects count] > 0) {
    [element addChild:[self _xmlDeletedObjects]];
  }
  
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
  KPKAddElement(groupElement, @"IconId", KPKStringFromLong(group.icon));
  
  DDXMLElement *timesElement = [self _xmlTimeinfo:group.timeInfo];
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

- (DDXMLElement *)_xmlBinaries {
  
  [self _prepateAttachments];
  DDXMLElement *binaryElements = [DDXMLElement elementWithName:@"Binaries"];
  
  BOOL compress = (self.tree.metadata.compressionAlgorithm == KPKCompressionGzip);
  for(KPKBinary *attachment in _binaries) {
    DDXMLElement *binaryElement = [DDXMLElement elementWithName:@"Binary"];
    KPKAddAttribute(binaryElement, @"ID", KPKStringFromLong([_binaries indexOfObject:attachment]));
    KPKAddAttribute(binaryElement, @"Compressed", KPKStringFromBool(compress));
    binaryElement.stringValue = [attachment encodedStringUsingCompression:compress];
    [binaryElements addChild:binaryElement];
  }
  return binaryElements;
}

- (DDXMLElement *)_xmlIcons {
  DDXMLElement *customIconsElements = [DDXMLElement elementWithName:@"CustomIcons"];
  for (KPKIcon *icon in self.tree.metadata.customIcons) {
    DDXMLElement *iconElement = [DDXMLNode elementWithName:@"Icon"];
    KPKAddElement(iconElement, @"UUID", [icon.uuid encodedString]);
    KPKAddElement(iconElement, @"Data", [icon encodedString]);
    [customIconsElements addChild:iconElement];
  }
  return customIconsElements;
}

- (DDXMLElement *)_xmlDeletedObjects {
  DDXMLElement *deletedObjectsElement = [DDXMLElement elementWithName:@"DeletedObjects"];
  for(KPKDeletedNode *node in self.tree.deletedObjects) {
    DDXMLElement *deletedElement = [DDXMLNode elementWithName:@"DeletedObject"];
    KPKAddElement(deletedElement, @"UUID",[node.uuid encodedString]);
    KPKAddElement(deletedElement, @"DeletionTime", KPKFormattedDate(node.deletionDate));
    [deletedObjectsElement addChild:deletedElement];
  }
  return deletedObjectsElement;
}

- (DDXMLElement *)_xmlTimeinfo:(KPKTimeInfo *)timeInfo {
  DDXMLElement *timesElement = [DDXMLNode elementWithName:@"Times"];
  KPKAddElement(timesElement, @"LastModificationTime", KPKFormattedDate(timeInfo.lastModificationTime));
  KPKAddElement(timesElement, @"dateFormatter", KPKFormattedDate(timeInfo.creationTime));
  KPKAddElement(timesElement, @"LastAccessTime", KPKFormattedDate(timeInfo.lastAccessTime));
  KPKAddElement(timesElement, @"ExpiryTime", KPKFormattedDate(timeInfo.expiryTime));
  KPKAddElement(timesElement, @"Expires", KPKStringFromBool(timeInfo.expires));
  KPKAddElement(timesElement, @"UsageCount", KPKStringFromLong(timeInfo.usageCount));
  KPKAddElement(timesElement, @"LocationChanged", KPKFormattedDate(timeInfo.locationChanged));
  return timesElement;
}

- (void)_prepateAttachments {
  NSArray *entries = self.tree.allEntries;
  _entryToBinaryMap = [[NSMutableDictionary alloc] initWithCapacity:[entries count] / 4];
  _binaries = [[NSMutableArray alloc] initWithCapacity:[_entryToBinaryMap count]];
  for(KPKEntry *entry in entries) {
    [_binaries addObjectsFromArray:entry.binaries];
    _entryToBinaryMap[ entry.uuid ] = entry.binaries;
  }
}

@end
