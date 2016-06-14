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
#import "KPKTree+Private.h"

#import "DDXMLDocument.h"
#import "DDXMLElementAdditions.h"
#import "NSUUID+KeePassKit.h"
#import "NSMutableData+Base64.h"

#import "KPKXmlHeaderWriter.h"
#import "KPKXmlFormat.h"
#import "KPKNode+Private.h"
#import "KPKGroup.h"
#import "KPKEntry.h"
#import "KPKFormat.h"
#import "KPKMetaData.h"
#import "KPKMetaData+Private.h"
#import "KPKTimeInfo.h"
#import "KPKDeletedNode.h"
#import "KPKAttribute.h"
#import "KPKBinary.h"
#import "KPKIcon.h"
#import "KPKAutotype.h"
#import "KPKWindowAssociation.h"

#import "NSColor+KeePassKit.h"
#import "NSString+XMLUtilities.h"

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

- (instancetype)initWithTree:(KPKTree *)tree {
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
  NSString *xmlRootString = [NSString stringWithFormat:@"<%@></%@>", kKPKXmlKeePassFile, kKPKXmlKeePassFile];
  DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:xmlRootString options:0 error:nil];
  
  KPKMetaData *metaData = self.tree.metaData;
  /* Update the Metadata since MacPass did generate the File */
  metaData.generator = @"MacPass";
  DDXMLElement *metaElement = [DDXMLNode elementWithName:kKPKXmlMeta];
  KPKAddXmlElement(metaElement, kKPKXmlGenerator, metaData.generator);
  
  if(_headerWriter.headerHash) {
    NSString *headerHash = [[NSString alloc] initWithData:[NSMutableData mutableDataWithBase64EncodedData:_headerWriter.headerHash] encoding:NSUTF8StringEncoding];
    KPKAddXmlElement(metaElement, kKPKXmlHeaderHash, headerHash);
  }
  
  
  KPKAddXmlElement(metaElement, kKPKXmlDatabaseName, metaData.databaseName.XMLCompatibleString);
  KPKAddXmlElement(metaElement, kKPKXmlDatabaseNameChanged, KPKStringFromDate(_dateFormatter, metaData.databaseNameChanged));
  KPKAddXmlElement(metaElement, kKPKXmlDatabaseDescription, metaData.databaseDescription.XMLCompatibleString);
  KPKAddXmlElement(metaElement, kKPKXmlDatabaseDescriptionChanged, KPKStringFromDate(_dateFormatter, metaData.databaseDescriptionChanged));
  KPKAddXmlElement(metaElement, kKPKXmlDefaultUserName, metaData.defaultUserName.XMLCompatibleString);
  KPKAddXmlElement(metaElement, kKPKXmlDefaultUserNameChanged, KPKStringFromDate(_dateFormatter, metaData.defaultUserNameChanged));
  KPKAddXmlElement(metaElement, kKPKXmlMaintenanceHistoryDays, KPKStringFromLong(metaData.maintenanceHistoryDays));
  KPKAddXmlElement(metaElement, kKPKXmlColor, [metaData.color hexString]);
  KPKAddXmlElement(metaElement, kKPKXmlMasterKeyChanged, KPKStringFromDate(_dateFormatter, metaData.masterKeyChanged));
  KPKAddXmlElement(metaElement, kKPKXmlMasterKeyChangeRecommendationInterval, KPKStringFromLong(metaData.masterKeyChangeRecommendationInterval));
  KPKAddXmlElement(metaElement, kKPKXmlMasterKeyChangeForceInterval, KPKStringFromLong(metaData.masterKeyChangeEnforcementInterval));
  
  DDXMLElement *memoryProtectionElement = [DDXMLElement elementWithName:kKPKXmlMemoryProtection];
  KPKAddXmlElement(memoryProtectionElement, kKPKXmlProtectTitle, KPKStringFromBool(metaData.protectTitle));
  KPKAddXmlElement(memoryProtectionElement, kKPKXmlProtectUserName, KPKStringFromBool(metaData.protectUserName));
  KPKAddXmlElement(memoryProtectionElement, kKPKXmlProtectPassword, KPKStringFromBool(metaData.protectPassword));
  KPKAddXmlElement(memoryProtectionElement, kKPKXmlProtectURL, KPKStringFromBool(metaData.protectUrl));
  KPKAddXmlElement(memoryProtectionElement, kKPKXmlProtectNotes, KPKStringFromBool(metaData.protectNotes));
  
  [metaElement addChild:memoryProtectionElement];
  
  if ((metaData.mutableCustomIcons).count > 0) {
    [metaElement addChild:[self _xmlIcons]];
  }
  
  KPKAddXmlElement(metaElement, kKPKXmlRecycleBinEnabled, KPKStringFromBool(metaData.useTrash));
  KPKAddXmlElement(metaElement, kKPKXmlRecycleBinUUID, [metaData.trashUuid encodedString]);
  KPKAddXmlElement(metaElement, kKPKXmlRecycleBinChanged, KPKStringFromDate(_dateFormatter, metaData.trashChanged));
  KPKAddXmlElement(metaElement, kKPKXmlEntryTemplatesGroup, [metaData.entryTemplatesGroup encodedString]);
  KPKAddXmlElement(metaElement, kKPKXmlEntryTemplatesGroupChanged, KPKStringFromDate(_dateFormatter, metaData.entryTemplatesGroupChanged));
  KPKAddXmlElement(metaElement, kKPKXmlHistoryMaxItems, KPKStringFromLong(metaData.historyMaxItems));
  KPKAddXmlElement(metaElement, kKPKXmlHistoryMaxSize, KPKStringFromLong(metaData.historyMaxSize));
  KPKAddXmlElement(metaElement, kKPKXmlLastSelectedGroup, [metaData.lastSelectedGroup encodedString]);
  KPKAddXmlElement(metaElement, kKPKXmlLastTopVisibleGroup, [metaData.lastTopVisibleGroup encodedString]);
  
  /* Custom Data is stored as KPKBinaries in the meta object */
  [metaElement addChild:[self _xmlBinaries]];
  DDXMLElement *customDataElement = [DDXMLElement elementWithName:@"CustomData"];
  for (KPKBinary *binary in metaData.mutableCustomData) {
    [customDataElement addChild:[self _xmlCustomData:binary]];
  }
  [metaElement addChild:customDataElement];
  /* Add meta Element to XML root */
  [[document rootElement] addChild:metaElement];
  
  DDXMLElement *rootElement = [DDXMLNode elementWithName:kKPKXmlRoot];
  
  /* Before storing, we need to setup the random stream */
  if(useRandomStream) {
    if(![self _setupRandomStream]) {
      return nil;
    }
  }
  
  /* Create XML nodes for all Groups and Entries */
  [rootElement addChild:[self _xmlGroup:self.tree.root]];
  
  /* Add Deleted Objects */
  [rootElement addChild:[self _xmlDeletedObjects]];
  [[document rootElement] addChild:rootElement];
  
  /*
   Encode all Data that is marked protetected
   */
  if(_randomStream) {
    [self _encodeProtected:[document rootElement]];
  }
  
  return document;
}

- (DDXMLElement *)_xmlGroup:(KPKGroup *)group {
  DDXMLElement *groupElement = [DDXMLNode elementWithName:kKPKXmlGroup];
  
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
  dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
  
  // Add the standard properties
  KPKAddXmlElement(groupElement, kKPKXmlUUID, [group.uuid encodedString]);
  KPKAddXmlElement(groupElement, kKPKXmlName, group.title.XMLCompatibleString);
  KPKAddXmlElement(groupElement, kKPKXmlNotes, group.notes.XMLCompatibleString);
  KPKAddXmlElement(groupElement, kKPKXmlIconId, KPKStringFromLong(group.iconId));
  
  DDXMLElement *timesElement = [self _xmlTimeinfo:group.timeInfo];
  [groupElement addChild:timesElement];
  
  KPKAddXmlElement(groupElement, kKPKXmlIsExpanded, KPKStringFromBool(group.isExpanded));
  NSString *keystrokes = (group.hasDefaultAutotypeSequence ? nil : group.defaultAutoTypeSequence.XMLCompatibleString);
  KPKAddXmlElement(groupElement, kKPKXmlDefaultAutoTypeSequence, keystrokes);
  KPKAddXmlElement(groupElement, kKPKXmlEnableAutoType, stringFromInhertiBool(group.isAutoTypeEnabled));
  KPKAddXmlElement(groupElement, kKPKXmlEnableSearching, stringFromInhertiBool(group.isSearchEnabled));
  KPKAddXmlElement(groupElement, kKPKXmlLastTopVisibleEntry, [group.lastTopVisibleEntry encodedString]);
  
  for(KPKEntry *entry in group.entries) {
    [groupElement addChild:[self _xmlEntry:entry skipHistory:NO]];
  }
  
  for (KPKGroup *subGroup in group.groups) {
    [groupElement addChild:[self _xmlGroup:subGroup]];
  }
  
  return groupElement;
}

- (DDXMLElement *)_xmlEntry:(KPKEntry *)entry skipHistory:(BOOL)skipHistory {
  DDXMLElement *entryElement = [DDXMLNode elementWithName:@"Entry"];
  
  // Add the standard properties
  KPKAddXmlElement(entryElement, kKPKXmlUUID, [entry.uuid encodedString]);
  KPKAddXmlElement(entryElement, kKPKXmlIconId, KPKStringFromLong(entry.iconId));
  if(entry.iconUUID) {
    KPKAddXmlElement(entryElement, @"CustomIconUUID", [entry.iconUUID encodedString]);
  }
  KPKAddXmlElement(entryElement, @"ForegroundColor", [entry.foregroundColor hexString]);
  KPKAddXmlElement(entryElement, @"BackgroundColor", [entry.backgroundColor hexString]);
  KPKAddXmlElement(entryElement, @"OverrideURL", entry.overrideURL.XMLCompatibleString);
  KPKAddXmlElement(entryElement, @"Tags", [entry.tags componentsJoinedByString:@";"].XMLCompatibleString);
  
  DDXMLElement *timesElement = [self _xmlTimeinfo:entry.timeInfo];
  [entryElement addChild:timesElement];
  
  for(KPKAttribute *attribute in entry.attributes) {
    [entryElement addChild:[self _xmlAttribute:attribute]];
  }
  for(KPKBinary *binary in entry.binaries) {
    [entryElement addChild:[self _xmlBinary:binary]];
  }
  
  [entryElement addChild:[self _xmlAutotype:entry.autotype]];
  
  // Add the history entries
  if(!skipHistory) {
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
  NSString *keystrokes = autotype.hasDefaultKeystrokeSequence ? nil : autotype.defaultKeystrokeSequence.XMLCompatibleString;
  KPKAddXmlElementIfNotNil(autotypeElement, @"DefaultSequence", keystrokes);
  
  if((autotype.associations).count > 0) {
    for(KPKWindowAssociation *association in autotype.associations) {
      DDXMLElement *associationsElement = [DDXMLElement elementWithName:@"Association"];
      KPKAddXmlElement(associationsElement, @"Window", association.windowTitle.XMLCompatibleString);
      NSString *keyStrokes = (association.hasDefaultKeystrokeSequence ? @"" : association.keystrokeSequence.XMLCompatibleString);
      KPKAddXmlElement(associationsElement, @"KeystrokeSequence", keyStrokes);
      [autotypeElement addChild:associationsElement];
    }
  }
  
  return autotypeElement;
}

- (DDXMLElement *)_xmlAttribute:(KPKAttribute *)attribute {
  DDXMLElement *attributeElement = [DDXMLElement elementWithName:@"String"];
  KPKAddXmlElement(attributeElement, kKPKXmlKey, attribute.key);
  
  KPKMetaData *metaData = attribute.entry.tree.metaData;
  NSAssert(metaData, @"Metadata needs to be present for attributes");
  BOOL isProtected = attribute.isProtected;
  if([attribute.key isEqualToString:kKPKNotesKey]) {
    isProtected |= metaData.protectNotes;
  }
  else if([attribute.key isEqualToString:kKPKPasswordKey] ) {
    isProtected |= metaData.protectPassword;
  }
  else if([attribute.key isEqualToString:kKPKTitleKey] ) {
    isProtected |= metaData.protectTitle;
  }
  else if([attribute.key isEqualToString:kKPKURLKey] ) {
    isProtected |= metaData.protectUrl;
  }
  else if([attribute.key isEqualToString:kKPKUsernameKey] ) {
    isProtected |= metaData.protectUserName;
  }
  /*
   If we write direct output without later proteting the stream,
   e.g. direct output to XML we need to strip any invalid characters
   to prevent XML malformation
   */
  BOOL usesRandomStream = (_randomStream != nil);
  NSString *attributeValue = (usesRandomStream && isProtected) ? attribute.value : attribute.value.XMLCompatibleString;
  DDXMLElement *valueElement = [DDXMLElement elementWithName:kKPKXmlValue stringValue:attributeValue];
  if(isProtected) {
    NSString *attributeName = usesRandomStream ? kKPKXmlProtected : kKPKXMLProtectInMemory;
    KPKAddXmlAttribute(valueElement, attributeName, kKPKXmlTrue);
  }
  [attributeElement addChild:valueElement];
  
  return attributeElement;
}

- (DDXMLElement *)_xmlBinaries {
  
  [self _prepareBinaries];
  DDXMLElement *binaryElements = [DDXMLElement elementWithName:kKPKXmlBinaries];
  
  BOOL compress = (self.tree.metaData.compressionAlgorithm == KPKCompressionGzip);
  for(KPKBinary *binary in _binaries) {
    DDXMLElement *binaryElement = [DDXMLElement elementWithName:kKPKXmlBinary];
    KPKAddXmlAttribute(binaryElement, kKPKXmlBinaryId, KPKStringFromLong([_binaries indexOfObject:binary]));
    KPKAddXmlAttribute(binaryElement, kKPKXmlCompressed, KPKStringFromBool(compress));
    binaryElement.stringValue = [binary encodedStringUsingCompression:compress];
    [binaryElements addChild:binaryElement];
  }
  return binaryElements;
}

- (DDXMLElement *)_xmlBinary:(KPKBinary *)binary {
  DDXMLElement *binaryElement = [DDXMLElement elementWithName:kKPKXmlBinary];
  KPKAddXmlElement(binaryElement, kKPKXmlKey, binary.name.XMLCompatibleString);
  DDXMLElement *valueElement = [DDXMLElement elementWithName:kKPKXmlValue];
  [binaryElement addChild:valueElement];
  NSUInteger reference = [_binaries indexOfObject:binary];
  NSAssert(reference != NSNotFound, @"Binary has to be in binaries array");
  KPKAddXmlAttribute(valueElement, @"Ref", KPKStringFromLong(reference));
  return binaryElement;
}

- (DDXMLElement *)_xmlIcons {
  DDXMLElement *customIconsElements = [DDXMLElement elementWithName:kKPKXmlCustomIcons];
  for (KPKIcon *icon in self.tree.metaData.mutableCustomIcons) {
    DDXMLElement *iconElement = [DDXMLNode elementWithName:kKPKXmlIcon];
    KPKAddXmlElement(iconElement, kKPKXmlUUID, [icon.uuid encodedString]);
    KPKAddXmlElement(iconElement, kKPKXmlData, icon.encodedString);
    [customIconsElements addChild:iconElement];
  }
  return customIconsElements;
}

- (DDXMLElement *)_xmlCustomData:(KPKBinary *)customData {
  DDXMLElement *itemElement = [DDXMLElement elementWithName:@"Item"];
  KPKAddXmlElement(itemElement, kKPKXmlKey, customData.name.XMLCompatibleString);
  KPKAddXmlElement(itemElement, kKPKXmlValue, [customData encodedStringUsingCompression:NO]);
  return itemElement;
}

- (DDXMLElement *)_xmlDeletedObjects {
  DDXMLElement *deletedObjectsElement = [DDXMLElement elementWithName:kKPKXmlDeletedObjects];
  for(NSUUID *uuid in self.tree.mutableDeletedObjects) {
    KPKDeletedNode *node = self.tree.mutableDeletedObjects[ uuid ];
    DDXMLElement *deletedElement = [DDXMLNode elementWithName:kKPKXmlDeletedObject];
    KPKAddXmlElement(deletedElement, kKPKXmlUUID,[node.uuid encodedString]);
    KPKAddXmlElement(deletedElement, kKPKXmlDeletionTime, KPKStringFromDate(_dateFormatter, node.deletionDate));
    [deletedObjectsElement addChild:deletedElement];
  }
  return deletedObjectsElement;
}

- (DDXMLElement *)_xmlTimeinfo:(KPKTimeInfo *)timeInfo {
  DDXMLElement *timesElement = [DDXMLNode elementWithName:kKPKXmlTimes];
  KPKAddXmlElementIfNotNil(timesElement, kKPKXmlLastModificationDate, KPKStringFromDate(_dateFormatter, timeInfo.modificationDate));
  KPKAddXmlElementIfNotNil(timesElement, kKPKXmlCreationDate, KPKStringFromDate(_dateFormatter, timeInfo.creationDate));
  KPKAddXmlElementIfNotNil(timesElement, kKPKXmlLastAccessDate, KPKStringFromDate(_dateFormatter, timeInfo.accessDate));
  KPKAddXmlElementIfNotNil(timesElement, kKPKXmlExpirationDate, KPKStringFromDate(_dateFormatter, timeInfo.expirationDate));
  KPKAddXmlElement(timesElement, kKPKXmlExpires, KPKStringFromBool(timeInfo.expires));
  KPKAddXmlElement(timesElement, kKPKXmlUsageCount, KPKStringFromLong(timeInfo.usageCount));
  KPKAddXmlElementIfNotNil(timesElement, kKPKXmlLocationChanged, KPKStringFromDate(_dateFormatter, timeInfo.locationChanged));
  return timesElement;
}

- (void)_prepareBinaries {
  NSArray *entries = self.tree.allEntries;
  NSArray *allEntries = [entries arrayByAddingObjectsFromArray:self.tree.allHistoryEntries];
  _binaries = [[NSMutableArray alloc] init];
  for(KPKEntry *entry in allEntries) {
    for(KPKBinary *binary in entry.binaries) {
      if(![_binaries containsObject:binary]) {
        [_binaries addObject:binary];
      }
    }
  }
}

- (void)_encodeProtected:(DDXMLElement *)root {
  DDXMLNode *protectedAttribute = [root attributeForName:kKPKXmlProtected];
  if([[protectedAttribute stringValue] isEqualToString:kKPKXmlTrue]) {
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
