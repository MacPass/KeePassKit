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
#import "NSMutableData+Base64.h"

#import "KPKXmlHeaderWriter.h"
#import "KPKFormat.h"
#import "KPKGroup.h"
#import "KPKEntry.h"
#import "KPKMetaData.h"
#import "KPKTimeInfo.h"
#import "KPKDeletedNode.h"
#import "KPKAttribute.h"
#import "KPKBinary.h"
#import "KPKIcon.h"

#import "NSColor+KeePassKit.h"

#import "RandomStream.h"
#import "Salsa20RandomStream.h"
#import "Arc4RandomStream.h"

#define KPKAddElement(element, name, value) [element addChild:[DDXMLNode elementWithName:name stringValue:value]]
#define KPKAddAttribute(element, name, value) [element addAttributeWithName:name stringValue:value];
#define KPKStringFromLong(integer) [NSString stringWithFormat:@"%ld", integer]
#define KPKFormattedDate(date) [_dateFormatter stringFromDate:date]
#define KPKStringFromBool(bool) (bool ? @"True" : @"False" )

@interface KPKXmlTreeWriter () {
  NSDateFormatter *_dateFormatter;
  NSMutableArray *_binaries;
  NSMutableDictionary *_entryToBinaryMap;
  KPKXmlHeaderWriter *_headerWriter;
  RandomStream *_randomStream;
}

@property (strong, readwrite) KPKTree *tree;

@end

@implementation KPKXmlTreeWriter

- (id)initWithTree:(KPKTree *)tree headerWriter:(id<KPKHeaderWriting>)headerWriter {
  self = [super init];
  if(self) {
    _tree = tree;
    if(_headerWriter) {
      NSAssert([_headerWriter isKindOfClass:[KPKXmlHeaderWriter class]], @"Header writer needs to be KPKXmlHeaderWriter");
      _headerWriter = headerWriter;
    }
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    _dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
  }
  return self;
}

- (DDXMLDocument *)xmlDocument {
  
  if(_headerWriter && ![self _setupRandomStream]) {
    return nil;
  }
  
  DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:@"<KeePassFile></KeePassFile>" options:0 error:nil];
  
  DDXMLElement *metaElement = [DDXMLNode elementWithName:@"Meta"];
  KPKAddElement(metaElement, @"Generator", self.tree.metaData.generator);
  KPKAddElement(metaElement, @"DatabaseName", self.tree.metaData.databaseName);
  KPKAddElement(metaElement, @"DatabaseNameChanged", KPKFormattedDate(self.tree.metaData.databaseNameChanged));
  KPKAddElement(metaElement, @"DatabaseDescription", self.tree.metaData.databaseDescription);
  KPKAddElement(metaElement, @"DatabaseDescriptionChanged", KPKFormattedDate(self.tree.metaData.databaseDescriptionChanged));
  KPKAddElement(metaElement, @"DefaultUserName", self.tree.metaData.defaultUserName);
  KPKAddElement(metaElement, @"MaintenanceHistoryDays", KPKStringFromLong(self.tree.metaData.maintenanceHistoryDays));
  KPKAddElement(metaElement, @"Color", [self.tree.metaData.color hexString]);
  KPKAddElement(metaElement, @"MasterKeyChanged", KPKFormattedDate(self.tree.metaData.masterKeyChanged));
  KPKAddElement(metaElement, @"MasterKeyChangeRec", KPKStringFromLong(self.tree.metaData.masterKeyChangeIsRequired));
  KPKAddElement(metaElement, @"MasterKeyChangeForce", KPKStringFromLong(self.tree.metaData.masterKeyChangeIsForced));
  
  DDXMLElement *memoryProtectionElement = [DDXMLElement elementWithName:@"MemoryProtection"];
  KPKAddElement(memoryProtectionElement, @"ProtectTitle", KPKStringFromBool(self.tree.metaData.protectTitle));
  KPKAddElement(memoryProtectionElement, @"ProtectUserName", KPKStringFromBool(self.tree.metaData.protectUserName));
  KPKAddElement(memoryProtectionElement, @"ProtectPassword", KPKStringFromBool(self.tree.metaData.protectPassword));
  KPKAddElement(memoryProtectionElement, @"ProtectURL", KPKStringFromBool(self.tree.metaData.protectUrl));
  KPKAddElement(memoryProtectionElement, @"ProtectNotes", KPKStringFromBool(self.tree.metaData.protectNotes));
  
  [metaElement addChild:memoryProtectionElement];
  
  if ([self.tree.metaData.customIcons count] > 0) {
    [metaElement addChild:[self _xmlIcons]];
  }
  
  KPKAddElement(metaElement, @"RecycleBinEnabled", KPKStringFromBool(self.tree.metaData.recycleBinEnabled));
  KPKAddElement(metaElement, @"RecycleBinUUID", [self.tree.metaData.recycleBinUuid encodedString]);
  KPKAddElement(metaElement, @"RecycleBinChanged", KPKFormattedDate(self.tree.metaData.recycleBinChanged));
  KPKAddElement(metaElement, @"EntryTemplatesGroup", [self.tree.metaData.entryTemplatesGroup encodedString]);
  KPKAddElement(metaElement, @"EntryTemplatesGroupChanged", KPKFormattedDate(self.tree.metaData.entryTemplatesGroupChanged));
  KPKAddElement(metaElement, @"HistoryMaxItems", KPKStringFromLong(self.tree.metaData.historyMaxItems));
  KPKAddElement(metaElement, @"HistoryMaxSize", KPKStringFromLong(self.tree.metaData.historyMaxItems));
  KPKAddElement(metaElement, @"LastSelectedGroup", [self.tree.metaData.lastSelectedGroup encodedString]);
  KPKAddElement(metaElement, @"LastTopVisibleGroup", [self.tree.metaData.lastTopVisibleGroup encodedString]);
  
  [metaElement addChild:[self _xmlBinaries]];
  
  /*
   DDXMLElement *customDataElements = [DDXMLElement elementWithName:@"CustomData"];
   for (CustomItem *customItem in self.tree.customData) {
   [customDataElements addChild:[self persistCustomItem:customItem]];
   }
   [element addChild:customDataElements];
   
   [document.rootElement addChild:element];
   */
  DDXMLElement *rootElement = [DDXMLNode elementWithName:@"Root"];
  
  /* Create XML nodes for all Groups and Entries */
  [rootElement addChild:[self _xmlGroup:self.tree.root]];
  
  /* Add Deleted Objects */
  if([self.tree.deletedObjects count] > 0) {
    [rootElement addChild:[self _xmlDeletedObjects]];
  }
  [[document rootElement] addChild:rootElement];
  
  /*
   Encode all Data that is marked protetected
   */
  [self _encodeProtected:[document rootElement]];
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
  
  KPKAddElement(groupElement, @"IsExpanded", KPKStringFromBool(group.isExpanded));
  KPKAddElement(groupElement, @"DefaultAutoTypeSequence", group.defaultAutoTypeSequence);
  KPKAddElement(groupElement, @"EnableAutoType", KPKStringFromLong(group.isAutoTypeEnabled));
  KPKAddElement(groupElement, @"EnableSearching", KPKStringFromLong(group.isSearchEnabled));
  KPKAddElement(groupElement, @"LastTopVisibleEntry", [group.lastTopVisibleEntry encodedString]);
  
  for(KPKEntry *entry in group.entries) {
    [groupElement addChild:[self _xmlEntry:entry skipHistory:YES]];
  }
  
  for (KPKGroup *subGroup in group.groups) {
    [groupElement addChild:[self _xmlGroup:subGroup]];
  }
  
  return groupElement;
}

- (DDXMLElement *)_xmlEntry:(KPKEntry *)entry skipHistory:(BOOL)skipHistory {
  DDXMLElement *entryElement = [DDXMLNode elementWithName:@"Entry"];
  
  // Add the standard properties
  KPKAddElement(entryElement, @"UUID", [entry.uuid encodedString]);
  KPKAddElement(entryElement, @"IconID", KPKStringFromLong(entry.icon));
  if(entry.iconUUID) {
    KPKAddElement(entryElement, @"CustomIconUUID", [entry.iconUUID encodedString]);
  }
  KPKAddElement(entryElement, @"ForegroundColor", [entry.foregroundColor hexString]);
  KPKAddElement(entryElement, @"BackgroundColor", [entry.backgroundColor hexString]);
  KPKAddElement(entryElement, @"OverrideURL", entry.overrideURL);
  KPKAddElement(entryElement, @"Tags", entry.tags);
  
  DDXMLElement *timesElement = [self _xmlTimeinfo:entry.timeInfo];
  [entryElement addChild:timesElement];
  
  for(KPKAttribute *defaultAttribute in [entry defaultAttributes]) {
    [entryElement addChild:[self _xmlAttribute:defaultAttribute]];
  }
  
  for(KPKAttribute *attribute in entry.customAttributes) {
    [entryElement addChild:[self _xmlAttribute:attribute]];
  }
  /*
   
   FIXME: Add BinaryReferences
   FIXME: Add History
   FIXME: Add Autotype
   
   // Add the binary references
   for (BinaryRef *binaryRef in entry.binaries) {
   [root addChild:[self persistBinaryRef:binaryRef]];
   }
   
   // Add the auto-type
   [root addChild:[self persistAutoType:entry.autoType]];
   
   // Add the history entries
   if (includeHistory) {
   DDXMLElement *historyElement = [DDXMLElement elementWithName:@"History"];
   for (Kdb4Entry *oldEntry in entry.history) {
   [historyElement addChild:[self persistEntry:oldEntry includeHistory:NO]];
   }
   [root addChild:historyElement];
   }
   */
  return entryElement;
}

- (DDXMLElement *)_xmlAttribute:(KPKAttribute *)attribute {
  DDXMLElement *attributeElement = [DDXMLElement elementWithName:@"StringField"];
  KPKAddAttribute(attributeElement, @"Proteced", KPKStringFromBool(attribute.isProtected));
  KPKAddElement(attributeElement, @"Key", attribute.key);
  KPKAddElement(attributeElement, @"Value", attribute.value);
  return attributeElement;
}

- (DDXMLElement *)_xmlBinaries {
  
  [self _prepateAttachments];
  DDXMLElement *binaryElements = [DDXMLElement elementWithName:@"Binaries"];
  
  BOOL compress = (self.tree.metaData.compressionAlgorithm == KPKCompressionGzip);
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
  for (KPKIcon *icon in self.tree.metaData.customIcons) {
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

- (void)_encodeProtected:(DDXMLElement *)root {
  DDXMLNode *protectedAttribute = [root attributeForName:@"Protected"];
  if([[protectedAttribute stringValue] isEqual:@"True"]) {
    NSString *str = [root stringValue];
    NSMutableData *data = [[str dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    
    // Protect the password
    [_randomStream xor:data];
    
    // Base64 encode the string
    [data encodeBase64];
    NSString *protected = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [root setStringValue:protected];
  }
  
  for(DDXMLNode *node in [root children]) {
    if([node kind] == DDXMLElementKind) {
      [self _encodeProtected:(DDXMLElement*)node];
    }
  }
}

- (BOOL)_setupRandomStream {
  switch(_headerWriter.randomStreamID ) {
    case KPKRandomStreamSalsa20:
      _randomStream = [[Salsa20RandomStream alloc] init:_headerWriter.protectedStreamKey];
      return YES;
      
    case KPKRandomStreamArc4:
      _randomStream = [[Arc4RandomStream alloc] init:_headerWriter.protectedStreamKey];
      return YES;
      
    default:
      return NO;
  }
}


@end
