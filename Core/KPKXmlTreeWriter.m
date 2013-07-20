//
//  KPKXmlTreeWriter.m
//  MacPass
//
//  Created by Michael Starke on 16.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKXmlTreeWriter.h"
#import "KPKTree.h"

#import "DDXMLDocument.h"
#import "DDXMLElementAdditions.h"
#import "NSUUID+KeePassKit.h"

#import "KPKFormat.h"
#import "KPKGroup.h"
#import "KPKEntry.h"
#import "KPKAttachment.h"

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
  KPKAddElement(element, @"Generator", self.tree.generator);
  KPKAddElement(element, @"DatabaseName", self.tree.databaseName);
  KPKAddElement(element, @"DatabaseNameChanged", KPKFormattedDate(self.tree.databaseNameChanged));
  KPKAddElement(element, @"DatabaseDescription", self.tree.databaseDescription);
  KPKAddElement(element, @"DatabaseDescriptionChanged", KPKFormattedDate(self.tree.databaseDescriptionChanged));
  KPKAddElement(element, @"DefaultUserName", self.tree.defaultUserName);
  KPKAddElement(element, @"MaintenanceHistoryDays", KPKStringFromLong(self.tree.maintenanceHistoryDays));
  KPKAddElement(element, @"Color", self.tree.color);
  KPKAddElement(element, @"MasterKeyChanged", KPKFormattedDate(self.tree.masterKeyChanged));
  KPKAddElement(element, @"MasterKeyChangeRec", KPKStringFromLong(self.tree.masterKeyChangeIsRequired));
  KPKAddElement(element, @"MasterKeyChangeForce", KPKStringFromLong(self.tree.masterKeyChangeIsForced));
  
  DDXMLElement *memoryProtectionElement = [DDXMLElement elementWithName:@"MemoryProtection"];
  KPKAddElement(memoryProtectionElement, @"ProtectTitle", KPKStringFromBool(self.tree.protectTitle));
  KPKAddElement(memoryProtectionElement, @"ProtectUserName", KPKStringFromBool(self.tree.protectUserName));
  KPKAddElement(memoryProtectionElement, @"ProtectPassword", KPKStringFromBool(self.tree.protectPassword));
  KPKAddElement(memoryProtectionElement, @"ProtectURL", KPKStringFromBool(self.tree.protectUrl));
  KPKAddElement(memoryProtectionElement, @"ProtectNotes", KPKStringFromBool(self.tree.protectNotes));
  
  [element addChild:memoryProtectionElement];
  /*
   if ([self.tree.customIcons count] > 0) {
   DDXMLElement *customIconsElements = [DDXMLElement elementWithName:@"CustomIcons"];
   for (CustomIcon *customIcon in self.tree.customIcons) {
   [customIconsElements addChild:[self persistCustomIcon:customIcon]];
   }
   [element addChild:customIconsElements];
   }
   */
  
  KPKAddElement(element, @"RecycleBinEnabled", KPKStringFromBool(self.tree.recycleBinEnabled));
  KPKAddElement(element, @"RecycleBinUUID", [self.tree.recycleBinUuid encodedString]);
  KPKAddElement(element, @"RecycleBinChanged", KPKFormattedDate(self.tree.recycleBinChanged));
  KPKAddElement(element, @"EntryTemplatesGroup", [self.tree.entryTemplatesGroup encodedString]);
  KPKAddElement(element, @"EntryTemplatesGroupChanged", KPKFormattedDate(self.tree.entryTemplatesGroupChanged));
  KPKAddElement(element, @"HistoryMaxItems", KPKStringFromLong(self.tree.historyMaxItems));
  KPKAddElement(element, @"HistoryMaxSize", KPKStringFromLong(self.tree.historyMaxItems));
  KPKAddElement(element, @"LastSelectedGroup", [self.tree.lastSelectedGroup encodedString]);
  KPKAddElement(element, @"LastTopVisibleGroup", [self.tree.lastTopVisibleGroup encodedString]);
  
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
  
  DDXMLElement *timesElement = [DDXMLNode elementWithName:@"Times"];
  KPKAddElement(timesElement, @"LastModificationTime", KPKFormattedDate(group.lastModificationTime));
  KPKAddElement(timesElement, @"dateFormatter", KPKFormattedDate(group.creationTime));
  KPKAddElement(timesElement, @"LastAccessTime", KPKFormattedDate(group.lastAccessTime));
  KPKAddElement(timesElement, @"ExpiryTime", KPKFormattedDate(group.expiryTime));
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

- (DDXMLElement *)_xmlBinaries {
  
  [self _prepateAttachments];
  DDXMLElement *binaryElements = [DDXMLElement elementWithName:@"Binaries"];
  
  BOOL compress = (self.tree.compressionAlgorithm == KPKCompressionGzip);
  for(KPKAttachment *attachment in _binaries) {
    DDXMLElement *binaryElement = [DDXMLElement elementWithName:@"Binary"];
    KPKAddAttribute(binaryElement, @"ID", KPKStringFromLong([_binaries indexOfObject:attachment]));
    KPKAddAttribute(binaryElement, @"Compressed", KPKStringFromBool(compress));
    binaryElement.stringValue = [attachment encodedStringUsingCompression:compress];
    [binaryElements addChild:binaryElement];
  }
  return binaryElements;
}

- (void)_prepateAttachments {
  NSArray *entries = self.tree.allEntries;
  _entryToBinaryMap = [[NSMutableDictionary alloc] initWithCapacity:[entries count] / 4];
  _binaries = [[NSMutableArray alloc] initWithCapacity:[_entryToBinaryMap count]];
  for(KPKEntry *entry in entries) {
    [_binaries addObjectsFromArray:entry.attachmets];
    _entryToBinaryMap[ entry.uuid ] = entry.attachmets;
  }
}

@end
