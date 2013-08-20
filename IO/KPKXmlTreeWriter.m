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
#import "KPKXmlFormat.h"
#import "KPKGroup.h"
#import "KPKEntry.h"
#import "KPKMetaData.h"
#import "KPKTimeInfo.h"
#import "KPKDeletedNode.h"
#import "KPKAttribute.h"
#import "KPKBinary.h"
#import "KPKIcon.h"
#import "KPKAutotype.h"
#import "KPKWindowAssociation.h"

#import "NSColor+KeePassKit.h"

#import "RandomStream.h"
#import "Salsa20RandomStream.h"
#import "Arc4RandomStream.h"

#define KPKAddElement(element, name, value) [element addChild:[DDXMLNode elementWithName:name stringValue:value]]
#define KPKAddAttribute(element, name, value) [element addAttributeWithName:name stringValue:value];
#define KPKStringFromLong(integer) [NSString stringWithFormat:@"%ld", integer]
#define KPKFormattedDate(date) [_dateFormatter stringFromDate:date]
#define KPKStringFromBool(bool) (bool ? @"True" : @"False" )

static NSString *stringFromInhertiBool(KPKInheritBool value) {
  switch(value) {
    case KPKInherit:
      return @"null";
      
    case KPKInheritYES:
      return @"True";
      
    case KPKInheritNO:
      return @"False";
  }
}

@interface KPKXmlTreeWriter () {
  NSDateFormatter *_dateFormatter;
  NSMutableArray *_binaries;
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
    if(headerWriter) {
      NSAssert([headerWriter isKindOfClass:[KPKXmlHeaderWriter class]], @"Header writer needs to be KPKXmlHeaderWriter");
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
  
  KPKMetaData *metaData = self.tree.metaData;
  DDXMLElement *metaElement = [DDXMLNode elementWithName:@"Meta"];
  KPKAddElement(metaElement, @"Generator", metaData.generator);
  if(_headerWriter.headerHash) {
    NSString *headerHash = [[NSString alloc] initWithData:[NSMutableData mutableDataWithBase64EncodedData:_headerWriter.headerHash] encoding:NSUTF8StringEncoding];
    KPKAddElement(metaElement, @"HeaderHash", headerHash);
  }
  
  KPKAddElement(metaElement, @"DatabaseName", metaData.databaseName);
  KPKAddElement(metaElement, @"DatabaseNameChanged", KPKFormattedDate(metaData.databaseNameChanged));
  KPKAddElement(metaElement, @"DatabaseDescription", metaData.databaseDescription);
  KPKAddElement(metaElement, @"DatabaseDescriptionChanged", KPKFormattedDate(metaData.databaseDescriptionChanged));
  KPKAddElement(metaElement, @"DefaultUserName", metaData.defaultUserName);
  KPKAddElement(metaElement, @"DefaultUserNameChanged", KPKFormattedDate(metaData.defaultUserNameChanged));
  KPKAddElement(metaElement, @"MaintenanceHistoryDays", KPKStringFromLong(metaData.maintenanceHistoryDays));
  KPKAddElement(metaElement, @"Color", [metaData.color hexString]);
  KPKAddElement(metaElement, @"MasterKeyChanged", KPKFormattedDate(metaData.masterKeyChanged));
  KPKAddElement(metaElement, @"MasterKeyChangeRec", KPKStringFromLong(metaData.masterKeyChangeIsRequired));
  KPKAddElement(metaElement, @"MasterKeyChangeForce", KPKStringFromLong(metaData.masterKeyChangeIsForced));
  
  DDXMLElement *memoryProtectionElement = [DDXMLElement elementWithName:@"MemoryProtection"];
  KPKAddElement(memoryProtectionElement, @"ProtectTitle", KPKStringFromBool(metaData.protectTitle));
  KPKAddElement(memoryProtectionElement, @"ProtectUserName", KPKStringFromBool(metaData.protectUserName));
  KPKAddElement(memoryProtectionElement, @"ProtectPassword", KPKStringFromBool(metaData.protectPassword));
  KPKAddElement(memoryProtectionElement, @"ProtectURL", KPKStringFromBool(metaData.protectUrl));
  KPKAddElement(memoryProtectionElement, @"ProtectNotes", KPKStringFromBool(metaData.protectNotes));
  
  [metaElement addChild:memoryProtectionElement];
  
  if ([metaData.customIcons count] > 0) {
    [metaElement addChild:[self _xmlIcons]];
  }
  
  KPKAddElement(metaElement, @"RecycleBinEnabled", KPKStringFromBool(metaData.recycleBinEnabled));
  KPKAddElement(metaElement, @"RecycleBinUUID", [metaData.recycleBinUuid encodedString]);
  KPKAddElement(metaElement, @"RecycleBinChanged", KPKFormattedDate(metaData.recycleBinChanged));
  KPKAddElement(metaElement, @"EntryTemplatesGroup", [metaData.entryTemplatesGroup encodedString]);
  KPKAddElement(metaElement, @"EntryTemplatesGroupChanged", KPKFormattedDate(metaData.entryTemplatesGroupChanged));
  KPKAddElement(metaElement, @"HistoryMaxItems", KPKStringFromLong(metaData.historyMaxItems));
  KPKAddElement(metaElement, @"HistoryMaxSize", KPKStringFromLong(metaData.historyMaxItems));
  KPKAddElement(metaElement, @"LastSelectedGroup", [metaData.lastSelectedGroup encodedString]);
  KPKAddElement(metaElement, @"LastTopVisibleGroup", [metaData.lastTopVisibleGroup encodedString]);
  
  /* Custom Data is stored as KPKBinaries in the meta object */
  [metaElement addChild:[self _xmlBinaries]];
  DDXMLElement *customDataElement = [DDXMLElement elementWithName:@"CustomData"];
  for (KPKBinary *binary in metaData.customData) {
    [customDataElement addChild:[self _xmlCustomData:binary]];
  }
  [metaElement addChild:customDataElement];
  /* Add meta Element to XML root */
  [[document rootElement] addChild:metaElement];
  
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
  KPKAddElement(groupElement, @"EnableAutoType", stringFromInhertiBool(group.isAutoTypeEnabled));
  KPKAddElement(groupElement, @"EnableSearching", stringFromInhertiBool(group.isSearchEnabled));
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
  if(entry.customIcon) {
    KPKAddElement(entryElement, @"CustomIconUUID", [entry.customIcon.uuid encodedString]);
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
  for(KPKBinary *binary in entry.binaries) {
    [entryElement addChild:[self _xmlBinary:binary]];
  }
  
  [entryElement addChild:[self _xmlAutotype:entry.autotype]];
  
  // Add the history entries
  if(!skipHistory && [entry.history count] > 0) {
    DDXMLElement *historyElement = [DDXMLElement elementWithName:@"History"];
    for (KPKEntry *historyEntry in entry.history) {
      [historyElement addChild:[self _xmlEntry:historyEntry skipHistory:YES]];
    }
    [entryElement addChild:historyElement];
  }
  
  return entryElement;
}

- (DDXMLElement *)_xmlAutotype:(KPKAutotype *)autotype {
  /*
   <AutoType>
   <Enabled>True</Enabled>
   <DataTransferObfuscation>0</DataTransferObfuscation>
   <DefaultSequence>{TAB}{Username}{TAB}{Password}</DefaultSequence>
   <Association>
   <Window>WindowTitle</Window>
   <KeystrokeSequence></KeystrokeSequence>
   </Association>
   <Association>
   <Window>WindowWithCustomSequence</Window>
   <KeystrokeSequence>{TAB}{Username}{TAB}{Password}{TAB}{Password}</KeystrokeSequence>
   </Association>
   </AutoType>
   */
  DDXMLElement *autotypeElement = [DDXMLElement elementWithName:@"AutoType"];
  KPKAddElement(autotypeElement, @"Enabled", KPKStringFromBool(autotype.isEnabled));
  NSString *obfuscate = autotype.obfuscateDataTransfer ? @"0" : @"1";
  KPKAddElement(autotypeElement, @"DataTransferObfuscation", obfuscate);
  KPKAddElement(autotypeElement, @"DefaultSequence", autotype.defaultSequence);
  
  if([autotype.associations count] > 0) {
    DDXMLElement *associationsElement = [DDXMLElement elementWithName:@"Association"];
    for(KPKWindowAssociation *association in autotype.associations) {
      KPKAddElement(associationsElement, @"Window", association.windowTitle);
      KPKAddElement(associationsElement, @"KeystrokeSequence", association.keystrokeSequence);
    }
    [autotypeElement addChild:associationsElement];
  }
  
  return autotypeElement;
}

- (DDXMLElement *)_xmlAttribute:(KPKAttribute *)attribute {
  DDXMLElement *attributeElement = [DDXMLElement elementWithName:@"String"];
  if(attribute.isProtected) {
    NSString *attributeName = _randomStream != nil ? @"Protected" : @"ProtectInMemory";
    KPKAddAttribute(attributeElement, attributeName, @"True");
  }
  
  KPKAddElement(attributeElement, @"Key", attribute.key);
  KPKAddElement(attributeElement, @"Value", attribute.value);
  return attributeElement;
}

- (DDXMLElement *)_xmlBinaries {
  
  [self _prepateBinaries];
  DDXMLElement *binaryElements = [DDXMLElement elementWithName:@"Binaries"];
  
  BOOL compress = (self.tree.metaData.compressionAlgorithm == KPKCompressionGzip);
  for(KPKBinary *binary in _binaries) {
    DDXMLElement *binaryElement = [DDXMLElement elementWithName:@"Binary"];
    KPKAddAttribute(binaryElement, @"ID", KPKStringFromLong([_binaries indexOfObject:binary]));
    KPKAddAttribute(binaryElement, @"Compressed", KPKStringFromBool(compress));
    binaryElement.stringValue = [binary encodedStringUsingCompression:compress];
    [binaryElements addChild:binaryElement];
  }
  return binaryElements;
}

- (DDXMLElement *)_xmlBinary:(KPKBinary *)binary {
  DDXMLElement *binaryElement = [DDXMLElement elementWithName:@"Binary"];
  KPKAddElement(binaryElement, @"Key", binary.name);
  DDXMLElement *valueElement = [DDXMLElement elementWithName:@"Value"];
  [binaryElement addChild:valueElement];
  NSUInteger reference = [_binaries indexOfObject:binary];
  NSAssert(reference != NSNotFound, @"Binary has to be in binaries array");
  KPKAddAttribute(valueElement, @"Ref", KPKStringFromLong(reference));
  return binaryElement;
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

- (DDXMLElement *)_xmlCustomData:(KPKBinary *)customData {
  DDXMLElement *itemElement = [DDXMLElement elementWithName:@"Item"];
  KPKAddElement(itemElement, @"Key", customData.name);
  KPKAddElement(itemElement, @"Value", [customData encodedStringUsingCompression:NO]);
  return itemElement;
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

- (void)_prepateBinaries {
  NSArray *entries = self.tree.allEntries;
  _binaries = [[NSMutableArray alloc] initWithCapacity:[entries count] / 4];
  for(KPKEntry *entry in entries) {
    for(KPKBinary *binary in entry.binaries) {
      if(![_binaries containsObject:binary]) {
        [_binaries addObject:binary];
      }
    }
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
