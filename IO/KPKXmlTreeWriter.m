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
#import "KPKXmlHeaderWriter.h"
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

#import "KPKRandomStream.h"
#import "KPKSalsa20RandomStream.h"
#import "KPKArc4RandomStream.h"

#import "KPKXmlUtilities.h"

@interface KPKXmlTreeWriter () {
  NSDateFormatter *_dateFormatter;
  NSMutableArray *_binaries;
  KPKRandomStream *_randomStream;
}
@property (strong, readwrite) KPKXmlHeaderWriter *headerWriter;
@property (strong, readwrite) KPKTree *tree;

@end

@implementation KPKXmlTreeWriter

- (id)initWithTree:(KPKTree *)tree {
  self = [super init];
  if(self) {
    _tree = tree;
    _headerWriter = [[KPKXmlHeaderWriter alloc] initWithTree:_tree];
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    _dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
  }
  return self;
}

- (DDXMLDocument *)protectedXmlDocument {
  return [self _xmlDocumentUsingRandomStream:YES];
}

- (DDXMLDocument *)xmlDocument {
  return  [self _xmlDocumentUsingRandomStream:NO];
}

- (DDXMLDocument *)_xmlDocumentUsingRandomStream:(BOOL)useRandomStream {
  
  DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:@"<KeePassFile></KeePassFile>" options:0 error:nil];
  
  KPKMetaData *metaData = self.tree.metaData;
  /* Update the Metadata since MacPass did generate the File */
  metaData.generator = @"MacPass";
  DDXMLElement *metaElement = [DDXMLNode elementWithName:@"Meta"];
  KPKAddXmlElement(metaElement, @"Generator", metaData.generator);
  if(_headerWriter.headerHash) {
    NSString *headerHash = [[NSString alloc] initWithData:[NSMutableData mutableDataWithBase64EncodedData:_headerWriter.headerHash] encoding:NSUTF8StringEncoding];
    KPKAddXmlElement(metaElement, @"HeaderHash", headerHash);
  }
  
  KPKAddXmlElement(metaElement, @"DatabaseName", metaData.databaseName);
  KPKAddXmlElement(metaElement, @"DatabaseNameChanged", KPKStringFromDate(_dateFormatter, metaData.databaseNameChanged));
  KPKAddXmlElement(metaElement, @"DatabaseDescription", metaData.databaseDescription);
  KPKAddXmlElement(metaElement, @"DatabaseDescriptionChanged", KPKStringFromDate(_dateFormatter, metaData.databaseDescriptionChanged));
  KPKAddXmlElement(metaElement, @"DefaultUserName", metaData.defaultUserName);
  KPKAddXmlElement(metaElement, @"DefaultUserNameChanged", KPKStringFromDate(_dateFormatter, metaData.defaultUserNameChanged));
  KPKAddXmlElement(metaElement, @"MaintenanceHistoryDays", KPKStringFromLong(metaData.maintenanceHistoryDays));
  KPKAddXmlElement(metaElement, @"Color", [metaData.color hexString]);
  KPKAddXmlElement(metaElement, @"MasterKeyChanged", KPKStringFromDate(_dateFormatter, metaData.masterKeyChanged));
  KPKAddXmlElement(metaElement, @"MasterKeyChangeRec", KPKStringFromLong(metaData.masterKeyChangeIsRequired));
  KPKAddXmlElement(metaElement, @"MasterKeyChangeForce", KPKStringFromLong(metaData.masterKeyChangeIsForced));
  
  DDXMLElement *memoryProtectionElement = [DDXMLElement elementWithName:@"MemoryProtection"];
  KPKAddXmlElement(memoryProtectionElement, @"ProtectTitle", KPKStringFromBool(metaData.protectTitle));
  KPKAddXmlElement(memoryProtectionElement, @"ProtectUserName", KPKStringFromBool(metaData.protectUserName));
  KPKAddXmlElement(memoryProtectionElement, @"ProtectPassword", KPKStringFromBool(metaData.protectPassword));
  KPKAddXmlElement(memoryProtectionElement, @"ProtectURL", KPKStringFromBool(metaData.protectUrl));
  KPKAddXmlElement(memoryProtectionElement, @"ProtectNotes", KPKStringFromBool(metaData.protectNotes));
  
  [metaElement addChild:memoryProtectionElement];
  
  if ([metaData.customIcons count] > 0) {
    [metaElement addChild:[self _xmlIcons]];
  }
  
  KPKAddXmlElement(metaElement, @"RecycleBinEnabled", KPKStringFromBool(metaData.recycleBinEnabled));
  KPKAddXmlElement(metaElement, @"RecycleBinUUID", [metaData.recycleBinUuid encodedString]);
  KPKAddXmlElement(metaElement, @"RecycleBinChanged", KPKStringFromDate(_dateFormatter, metaData.recycleBinChanged));
  KPKAddXmlElement(metaElement, @"EntryTemplatesGroup", [metaData.entryTemplatesGroup encodedString]);
  KPKAddXmlElement(metaElement, @"EntryTemplatesGroupChanged", KPKStringFromDate(_dateFormatter, metaData.entryTemplatesGroupChanged));
  KPKAddXmlElement(metaElement, @"HistoryMaxItems", KPKStringFromLong(metaData.historyMaxItems));
  KPKAddXmlElement(metaElement, @"HistoryMaxSize", KPKStringFromLong(metaData.historyMaxSize));
  KPKAddXmlElement(metaElement, @"LastSelectedGroup", [metaData.lastSelectedGroup encodedString]);
  KPKAddXmlElement(metaElement, @"LastTopVisibleGroup", [metaData.lastTopVisibleGroup encodedString]);
  
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
  if(useRandomStream) {
    if(![self _setupRandomStream]) {
      return nil;
    }
    [self _encodeProtected:[document rootElement]];
  }
  return document;
}

- (DDXMLElement *)_xmlGroup:(KPKGroup *)group {
  DDXMLElement *groupElement = [DDXMLNode elementWithName:@"Group"];
  
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
  dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
  
  // Add the standard properties
  KPKAddXmlElement(groupElement, @"UUID", [group.uuid encodedString]);
  KPKAddXmlElement(groupElement, @"Name", group.name);
  KPKAddXmlElement(groupElement, @"Notes", group.notes);
  KPKAddXmlElement(groupElement, @"IconID", KPKStringFromLong(group.iconId));
  
  DDXMLElement *timesElement = [self _xmlTimeinfo:group.timeInfo];
  [groupElement addChild:timesElement];
  
  KPKAddXmlElement(groupElement, @"IsExpanded", KPKStringFromBool(group.isExpanded));
  KPKAddXmlElement(groupElement, @"DefaultAutoTypeSequence", group.defaultAutoTypeSequence);
  KPKAddXmlElement(groupElement, @"EnableAutoType", stringFromInhertiBool(group.isAutoTypeEnabled));
  KPKAddXmlElement(groupElement, @"EnableSearching", stringFromInhertiBool(group.isSearchEnabled));
  KPKAddXmlElement(groupElement, @"LastTopVisibleEntry", [group.lastTopVisibleEntry encodedString]);
  
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
  KPKAddXmlElement(entryElement, @"UUID", [entry.uuid encodedString]);
  KPKAddXmlElement(entryElement, @"IconID", KPKStringFromLong(entry.iconId));
  if(entry.customIcon) {
    KPKAddXmlElement(entryElement, @"CustomIconUUID", [entry.customIcon.uuid encodedString]);
  }
  KPKAddXmlElement(entryElement, @"ForegroundColor", [entry.foregroundColor hexString]);
  KPKAddXmlElement(entryElement, @"BackgroundColor", [entry.backgroundColor hexString]);
  KPKAddXmlElement(entryElement, @"OverrideURL", entry.overrideURL);
  KPKAddXmlElement(entryElement, @"Tags", entry.tags);
  
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
  KPKAddXmlElement(autotypeElement, @"Enabled", KPKStringFromBool(autotype.isEnabled));
  NSString *obfuscate = autotype.obfuscateDataTransfer ? @"1" : @"0";
  KPKAddXmlElement(autotypeElement, @"DataTransferObfuscation", obfuscate);
  KPKAddXmlElement(autotypeElement, @"DefaultSequence", autotype.defaultSequence);
  
  if([autotype.associations count] > 0) {
    DDXMLElement *associationsElement = [DDXMLElement elementWithName:@"Association"];
    for(KPKWindowAssociation *association in autotype.associations) {
      KPKAddXmlElement(associationsElement, @"Window", association.windowTitle);
      KPKAddXmlElement(associationsElement, @"KeystrokeSequence", association.keystrokeSequence);
    }
    [autotypeElement addChild:associationsElement];
  }
  
  return autotypeElement;
}

- (DDXMLElement *)_xmlAttribute:(KPKAttribute *)attribute {
  DDXMLElement *attributeElement = [DDXMLElement elementWithName:@"String"];
  if(attribute.isProtected) {
    NSString *attributeName = _randomStream != nil ? @"Protected" : @"ProtectInMemory";
    KPKAddXmlAttribute(attributeElement, attributeName, @"True");
  }
  
  KPKAddXmlElement(attributeElement, @"Key", attribute.key);
  KPKAddXmlElement(attributeElement, @"Value", attribute.value);
  return attributeElement;
}

- (DDXMLElement *)_xmlBinaries {
  
  [self _prepateBinaries];
  DDXMLElement *binaryElements = [DDXMLElement elementWithName:@"Binaries"];
  
  BOOL compress = (self.tree.metaData.compressionAlgorithm == KPKCompressionGzip);
  for(KPKBinary *binary in _binaries) {
    DDXMLElement *binaryElement = [DDXMLElement elementWithName:@"Binary"];
    KPKAddXmlAttribute(binaryElement, @"ID", KPKStringFromLong([_binaries indexOfObject:binary]));
    KPKAddXmlAttribute(binaryElement, @"Compressed", KPKStringFromBool(compress));
    binaryElement.stringValue = [binary encodedStringUsingCompression:compress];
    [binaryElements addChild:binaryElement];
  }
  return binaryElements;
}

- (DDXMLElement *)_xmlBinary:(KPKBinary *)binary {
  DDXMLElement *binaryElement = [DDXMLElement elementWithName:@"Binary"];
  KPKAddXmlElement(binaryElement, @"Key", binary.name);
  DDXMLElement *valueElement = [DDXMLElement elementWithName:@"Value"];
  [binaryElement addChild:valueElement];
  NSUInteger reference = [_binaries indexOfObject:binary];
  NSAssert(reference != NSNotFound, @"Binary has to be in binaries array");
  KPKAddXmlAttribute(valueElement, @"Ref", KPKStringFromLong(reference));
  return binaryElement;
}

- (DDXMLElement *)_xmlIcons {
  DDXMLElement *customIconsElements = [DDXMLElement elementWithName:@"CustomIcons"];
  for (KPKIcon *icon in self.tree.metaData.customIcons) {
    DDXMLElement *iconElement = [DDXMLNode elementWithName:@"Icon"];
    KPKAddXmlElement(iconElement, @"UUID", [icon.uuid encodedString]);
    KPKAddXmlElement(iconElement, @"Data", [icon encodedString]);
    [customIconsElements addChild:iconElement];
  }
  return customIconsElements;
}

- (DDXMLElement *)_xmlCustomData:(KPKBinary *)customData {
  DDXMLElement *itemElement = [DDXMLElement elementWithName:@"Item"];
  KPKAddXmlElement(itemElement, @"Key", customData.name);
  KPKAddXmlElement(itemElement, @"Value", [customData encodedStringUsingCompression:NO]);
  return itemElement;
}

- (DDXMLElement *)_xmlDeletedObjects {
  DDXMLElement *deletedObjectsElement = [DDXMLElement elementWithName:@"DeletedObjects"];
  for(NSUUID *uuid in self.tree.deletedObjects) {
    KPKDeletedNode *node = self.tree.deletedObjects[ uuid ];
    DDXMLElement *deletedElement = [DDXMLNode elementWithName:@"DeletedObject"];
    KPKAddXmlElement(deletedElement, @"UUID",[node.uuid encodedString]);
    KPKAddXmlElement(deletedElement, @"DeletionTime", KPKStringFromDate(_dateFormatter, node.deletionDate));
    [deletedObjectsElement addChild:deletedElement];
  }
  return deletedObjectsElement;
}

- (DDXMLElement *)_xmlTimeinfo:(KPKTimeInfo *)timeInfo {
  DDXMLElement *timesElement = [DDXMLNode elementWithName:@"Times"];
  KPKAddXmlElement(timesElement, @"LastModificationTime", KPKStringFromDate(_dateFormatter, timeInfo.lastModificationTime));
  KPKAddXmlElement(timesElement, @"dateFormatter", KPKStringFromDate(_dateFormatter, timeInfo.creationTime));
  KPKAddXmlElement(timesElement, @"LastAccessTime", KPKStringFromDate(_dateFormatter, timeInfo.lastAccessTime));
  KPKAddXmlElement(timesElement, @"ExpiryTime", KPKStringFromDate(_dateFormatter, timeInfo.expiryTime));
  KPKAddXmlElement(timesElement, @"Expires", KPKStringFromBool(timeInfo.expires));
  KPKAddXmlElement(timesElement, @"UsageCount", KPKStringFromLong(timeInfo.usageCount));
  KPKAddXmlElement(timesElement, @"LocationChanged", KPKStringFromDate(_dateFormatter, timeInfo.locationChanged));
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
  if(_headerWriter == nil) {
    return NO;
  }
  switch(_headerWriter.randomStreamID ) {
    case KPKRandomStreamSalsa20:
      _randomStream = [[KPKSalsa20RandomStream alloc] init:_headerWriter.protectedStreamKey];
      return YES;
      
    case KPKRandomStreamArc4:
      _randomStream = [[KPKArc4RandomStream alloc] init:_headerWriter.protectedStreamKey];
      return YES;
      
    default:
      return NO;
  }
}


@end
