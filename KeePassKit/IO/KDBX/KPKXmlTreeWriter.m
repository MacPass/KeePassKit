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

#import <KissXML/KissXML.h>

#import "KPKXmlTreeWriter.h"
#import "KPKTree.h"
#import "KPKTree_Private.h"

#import "KPKAttribute.h"
#import "KPKAutotype.h"
#import "KPKBinary.h"
#import "KPKBinary_Private.h"
#import "KPKData.h"
#import "KPKDeletedNode.h"
#import "KPKEntry.h"
#import "KPKEntry_Private.h"
#import "KPKFormat.h"
#import "KPKGroup.h"
#import "KPKGroup_Private.h"
#import "KPKIcon.h"
#import "KPKKdbxFormat.h"
#import "KPKMetaData.h"
#import "KPKMetaData_Private.h"
#import "KPKNode_Private.h"
#import "KPKRandomStream.h"
#import "KPKTimeInfo.h"
#import "KPKWindowAssociation.h"
#import "KPKXmlUtilities.h"

#import "NSData+KPKGzip.h"
#import "NSUIColor+KPKAdditions.h"
#import "NSUUID+KPKAdditions.h"
#import "NSString+KPKXmlUtilities.h"


@interface KPKXmlTreeWriter ()

@property (strong, readwrite) KPKTree *tree;
@property (readonly, copy) NSData *headerHash;
@property (readonly, strong) KPKRandomStream *randomStream;
@property BOOL useRelativeDate;
@property (nonatomic, readonly, copy) NSArray<KPKData *> *binaryData;
@property KPKFileVersion fileVersion;

@property (nonatomic, readonly) BOOL encrypted;

@end

@implementation KPKXmlTreeWriter

@synthesize binaryData = _binaryData;

- (instancetype)initWithTree:(KPKTree *)tree delegate:(id<KPKXmlTreeWriterDelegate>)delegate {
  self = [super init];
  if(self) {
    _delegate = delegate;
    _tree = tree;
    _useRelativeDate = YES;
    _fileVersion = KPKFileVersionMax(KPKMakeFileVersion(KPKDatabaseFormatKdbx, kKPKKdbxFileVersion3), tree.minimumVersion);
  }
  return self;
}

- (instancetype)initWithTree:(KPKTree *)tree {
  self = [self initWithTree:tree delegate:nil];
  return self;
}

#pragma Delegation

- (NSData *)headerHash {
  return [[self.delegate headerHashForWriter:self] copy];
}

- (KPKRandomStream *)randomStream {
  return [self.delegate randomStreamForWriter:self];
}

- (NSArray<KPKData *> *)binaryData {
  if(_binaryData) {
    return _binaryData;
  }
  if(self.delegate) {
    _binaryData = [[self.delegate binaryDataForWriter:self] copy];
  }
  else {
    NSArray *allEntries = [self.tree.allEntries arrayByAddingObjectsFromArray:self.tree.allHistoryEntries];
    NSMutableSet *tempBinaries = [[NSMutableSet alloc] init];
    for(KPKEntry *entry in allEntries) {
      for(KPKBinary *binary in entry.mutableBinaries) {
        [tempBinaries addObject:binary.internalData];
      }
    }
    _binaryData = tempBinaries.allObjects;
  }
  return _binaryData;
}

#pragma mark -
#pragma mark Serialisation

- (DDXMLDocument *)xmlDocument {
  NSString *xmlRootString = [NSString stringWithFormat:@"<%@></%@>", kKPKXmlKeePassFile, kKPKXmlKeePassFile];
  DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:xmlRootString options:0 error:nil];
  
  KPKMetaData *metaData = self.tree.metaData;
  /* Update the Metadata since MacPass did generate the File */
  metaData.generator = @"MacPass";
  DDXMLElement *metaElement = [DDXMLNode elementWithName:kKPKXmlMeta];
  KPKAddXmlElement(metaElement, kKPKXmlGenerator, metaData.generator);
  
  if(self.headerHash.length > 0) {
    KPKAddXmlElement(metaElement, kKPKXmlHeaderHash, [self.headerHash base64EncodedStringWithOptions:0]);
  }

  if(!self.randomStream || kKPKKdbxFileVersion4 > self.fileVersion.version) {
    self.useRelativeDate = NO;
    /*
     self.dateFormatter = [[NSDateFormatter alloc] init];
     self.dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
     self.dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
     */
  }
  
  KPKAddXmlElement(metaElement, kKPKXmlDatabaseName, metaData.databaseName.kpk_xmlCompatibleString);
  KPKAddXmlElement(metaElement, kKPKXmlDatabaseNameChanged, KPKStringFromDate(metaData.databaseNameChanged, self.useRelativeDate));
  KPKAddXmlElement(metaElement, kKPKXmlDatabaseDescription, metaData.databaseDescription.kpk_xmlCompatibleString);
  KPKAddXmlElement(metaElement, kKPKXmlDatabaseDescriptionChanged, KPKStringFromDate(metaData.databaseDescriptionChanged, self.useRelativeDate));
  KPKAddXmlElement(metaElement, kKPKXmlDefaultUserName, metaData.defaultUserName.kpk_xmlCompatibleString);
  KPKAddXmlElement(metaElement, kKPKXmlDefaultUserNameChanged, KPKStringFromDate(metaData.defaultUserNameChanged, self.useRelativeDate));
  KPKAddXmlElement(metaElement, kKPKXmlMaintenanceHistoryDays, KPKStringFromLong(metaData.maintenanceHistoryDays));
  KPKAddXmlElement(metaElement, kKPKXmlColor, metaData.color.kpk_hexString);
  /* Settings changed only in KDBX4 */
  if(kKPKKdbxFileVersion4 <= self.fileVersion.version) {
    KPKAddXmlElement(metaElement, kKPKXmlSettingsChanged, KPKStringFromDate(metaData.settingsChanged, self.useRelativeDate));
  }
  KPKAddXmlElement(metaElement, kKPKXmlMasterKeyChanged, KPKStringFromDate(metaData.masterKeyChanged, self.useRelativeDate));
  KPKAddXmlElement(metaElement, kKPKXmlMasterKeyChangeRecommendationInterval, KPKStringFromLong(metaData.masterKeyChangeRecommendationInterval));
  KPKAddXmlElement(metaElement, kKPKXmlMasterKeyChangeForceInterval, KPKStringFromLong(metaData.masterKeyChangeEnforcementInterval));
  if(metaData.enforceMasterKeyChangeOnce) {
    KPKAddXmlElement(metaElement, kKPKXmlMasterKeyChangeForceOnce, KPKStringFromBool(metaData.enforceMasterKeyChangeOnce));
  }
  
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
  KPKAddXmlElement(metaElement, kKPKXmlRecycleBinUUID, metaData.trashUuid.kpk_encodedString);
  KPKAddXmlElement(metaElement, kKPKXmlRecycleBinChanged, KPKStringFromDate(metaData.trashChanged, self.useRelativeDate));
  KPKAddXmlElement(metaElement, kKPKXmlEntryTemplatesGroup, metaData.entryTemplatesGroupUuid.kpk_encodedString);
  KPKAddXmlElement(metaElement, kKPKXmlEntryTemplatesGroupChanged, KPKStringFromDate(metaData.entryTemplatesGroupChanged, self.useRelativeDate));
  KPKAddXmlElement(metaElement, kKPKXmlHistoryMaxItems, KPKStringFromLong(metaData.historyMaxItems));
  KPKAddXmlElement(metaElement, kKPKXmlHistoryMaxSize, KPKStringFromLong(metaData.historyMaxSize));
  KPKAddXmlElement(metaElement, kKPKXmlLastSelectedGroup, metaData.lastSelectedGroup.kpk_encodedString);
  KPKAddXmlElement(metaElement, kKPKXmlLastTopVisibleGroup, metaData.lastTopVisibleGroup.kpk_encodedString);
  
  /* only add binaries if we actuall should, ask the delegate! */
  if(!self.randomStream || kKPKKdbxFileVersion4 > self.fileVersion.version) {
    if(self.binaryData) {
      [metaElement addChild:[self _xmlBinaries]];
    }
  }
  
  DDXMLElement *customDataElement = [self _xmlMetaCustomData:metaData.mutableCustomData];
  NSAssert(customDataElement, @"Unexspected nil value!");
  [metaElement addChild:customDataElement];
  /* Add meta Element to XML root */
  [[document rootElement] addChild:metaElement];
  
  DDXMLElement *rootElement = [DDXMLNode elementWithName:kKPKXmlRoot];
  
  /* Before storing, we need to setup the random stream */
  
  /* Create XML nodes for all Groups and Entries */
  [rootElement addChild:[self _xmlGroup:self.tree.root]];
  
  /* Add Deleted Objects */
  [rootElement addChild:[self _xmlDeletedObjects]];
  [[document rootElement] addChild:rootElement];
  
  /*
   Encode all Data that is marked protetected
   */
  if(self.randomStream) {
    [self _encodeProtected:[document rootElement]];
  }
  
  return document;
}

- (DDXMLElement *)_xmlGroup:(KPKGroup *)group {
  DDXMLElement *groupElement = [DDXMLNode elementWithName:kKPKXmlGroup];
  
  // Add the standard properties
  KPKAddXmlElement(groupElement, kKPKXmlUUID, group.uuid.kpk_encodedString);
  KPKAddXmlElement(groupElement, kKPKXmlName, group.title.kpk_xmlCompatibleString);
  KPKAddXmlElement(groupElement, kKPKXmlNotes, group.notes.kpk_xmlCompatibleString);
  KPKAddXmlElement(groupElement, kKPKXmlIconId, KPKStringFromLong(group.iconId));
  if(group.iconUUID) {
    KPKAddXmlElement(groupElement, kKPKXmlCustomIconUUID, group.iconUUID.kpk_encodedString);
  }
  DDXMLElement *timesElement = [self _xmlTimeinfo:group.timeInfo];
  [groupElement addChild:timesElement];
  
  KPKAddXmlElement(groupElement, kKPKXmlIsExpanded, KPKStringFromBool(group.isExpanded));
  NSString *keystrokes = (group.hasDefaultAutotypeSequence ? nil : group.defaultAutoTypeSequence.kpk_xmlCompatibleString);
  KPKAddXmlElement(groupElement, kKPKXmlDefaultAutoTypeSequence, keystrokes);
  KPKAddXmlElement(groupElement, kKPKXmlEnableAutoType, stringFromInheritBool(group.isAutoTypeEnabled));
  KPKAddXmlElement(groupElement, kKPKXmlEnableSearching, stringFromInheritBool(group.isSearchEnabled));
  KPKAddXmlElement(groupElement, kKPKXmlLastTopVisibleEntry, group.lastTopVisibleEntry.kpk_encodedString);
  
  if(group.tags.count > 0) {
    NSAssert(self.fileVersion.version >= kKPKKdbxFileVersion4_1, @"Internal inconsitency with minimum required version");
    KPKAddXmlElement(groupElement, kKPKXmlTags, [group.tags componentsJoinedByString:@";"].kpk_xmlCompatibleString);
  }
  
  KPKAddXmlElement(groupElement, kKPKXmlPreviousParentGroup, group.previousParent.kpk_encodedString);
  
  DDXMLElement *customDataElement = [self _xmlCustomData:group.mutableCustomData];
  if(customDataElement) {
    [groupElement addChild:customDataElement];
  }
  
  for(KPKEntry *entry in group.mutableEntries) {
    [groupElement addChild:[self _xmlEntry:entry skipHistory:NO]];
  }
  
  for (KPKGroup *subGroup in group.mutableGroups) {
    [groupElement addChild:[self _xmlGroup:subGroup]];
  }
  
  return groupElement;
}

- (DDXMLElement *)_xmlEntry:(KPKEntry *)entry skipHistory:(BOOL)skipHistory {
  DDXMLElement *entryElement = [DDXMLNode elementWithName:kKPKXmlEntry];
  
  // Add the standard properties
  KPKAddXmlElement(entryElement, kKPKXmlUUID, entry.uuid.kpk_encodedString);
  KPKAddXmlElement(entryElement, kKPKXmlIconId, KPKStringFromLong(entry.iconId));
  if(entry.iconUUID) {
    KPKAddXmlElement(entryElement, kKPKXmlCustomIconUUID, entry.iconUUID.kpk_encodedString);
  }
  KPKAddXmlElement(entryElement, kKPKXmlForegroundColor, entry.foregroundColor.kpk_hexString);
  KPKAddXmlElement(entryElement, kKPKXmlBackgroundColor, entry.backgroundColor.kpk_hexString);
  KPKAddXmlElement(entryElement, kKPKXmlOverrideURL, entry.overrideURL.kpk_xmlCompatibleString);
  KPKAddXmlElement(entryElement, kKPKXmlTags, [entry.tags componentsJoinedByString:@";"].kpk_xmlCompatibleString);
  
  if(!entry.checkPasswordQuality) {
    KPKAddXmlElement(entryElement, kKPKXmlQualityCheck, kKPKXmlFalse);
  }
  
  DDXMLElement *timesElement = [self _xmlTimeinfo:entry.timeInfo];
  [entryElement addChild:timesElement];
  
  DDXMLElement *customDataElement = [self _xmlCustomData:entry.mutableCustomData];
  if(customDataElement) {
    [entryElement addChild:customDataElement];
  }
  
  for(KPKAttribute *attribute in entry.mutableAttributes) {
    [entryElement addChild:[self _xmlAttribute:attribute metaData:entry.tree.metaData]];
  }
  for(KPKBinary *binary in entry.mutableBinaries) {
    [entryElement addChild:[self _xmlBinary:binary]];
  }
  
  [entryElement addChild:[self _xmlAutotype:entry.autotype]];
  
  // Add the history entries
  if(!skipHistory) {
    DDXMLElement *historyElement = [DDXMLElement elementWithName:kKPKXmlHistory];
    for (KPKEntry *historyEntry in entry.mutableHistory) {
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
  DDXMLElement *autotypeElement = [DDXMLElement elementWithName:kKPKXmlAutotype];
  KPKAddXmlElement(autotypeElement, kKPKXmlEnabled, KPKStringFromBool(autotype.enabled));
  NSString *obfuscate = autotype.obfuscateDataTransfer ? @"1" : @"0";
  KPKAddXmlElement(autotypeElement, kKPKXmlDataTransferObfuscation, obfuscate);
  NSString *keystrokes = autotype.hasDefaultKeystrokeSequence ? nil : autotype.defaultKeystrokeSequence.kpk_xmlCompatibleString;
  KPKAddXmlElementIfNotNil(autotypeElement, kKPKXmlDefaultSequence, keystrokes);
  
  if((autotype.associations).count > 0) {
    for(KPKWindowAssociation *association in autotype.associations) {
      DDXMLElement *associationsElement = [DDXMLElement elementWithName:kKPKXmlAssociation];
      KPKAddXmlElement(associationsElement, kKPKXmlWindow, association.windowTitle.kpk_xmlCompatibleString);
      NSString *keyStrokes = (association.hasDefaultKeystrokeSequence ? @"" : association.keystrokeSequence.kpk_xmlCompatibleString);
      KPKAddXmlElement(associationsElement, kKPKXmlKeystrokeSequence, keyStrokes);
      [autotypeElement addChild:associationsElement];
    }
  }
  
  return autotypeElement;
}

- (DDXMLElement *)_xmlAttribute:(KPKAttribute *)attribute metaData:(KPKMetaData *)metaData{
  DDXMLElement *attributeElement = [DDXMLElement elementWithName:kKPKXmlString];
  KPKAddXmlElement(attributeElement, kKPKXmlKey, attribute.key);
  
  NSAssert(metaData, @"Metadata needs to be present for attributes");
  
  BOOL isProtected = (attribute.protect || [metaData protectAttributeWithKey:attribute.key]);
  
  /*
   If we write direct output without later proteting the stream,
   e.g. direct output to XML we need to strip any invalid characters
   to prevent XML malformation
   */
  BOOL usesRandomStream = (self.randomStream != nil);
  NSString *attributeValue = (usesRandomStream && isProtected) ? attribute.value : attribute.value.kpk_xmlCompatibleString;
  DDXMLElement *valueElement = [DDXMLElement elementWithName:kKPKXmlValue stringValue:attributeValue];
  if(isProtected) {
    NSString *attributeName = usesRandomStream ? kKPKXmlProtected : kKPKXmlProtectInMemory;
    KPKAddXmlAttribute(valueElement, attributeName, kKPKXmlTrue);
  }
  [attributeElement addChild:valueElement];
  
  return attributeElement;
}

- (DDXMLElement *)_xmlBinaries {
  DDXMLElement *binaryElements = [DDXMLElement elementWithName:kKPKXmlBinaries];
  
  BOOL compress = (self.tree.metaData.compressionAlgorithm == KPKCompressionGzip);
  for(KPKData *data in self.binaryData) {
    DDXMLElement *binaryElement = [DDXMLElement elementWithName:kKPKXmlBinary];
    KPKAddXmlAttribute(binaryElement, kKPKXmlBinaryId, KPKStringFromLong([self.binaryData indexOfObject:data]));
    KPKAddXmlAttribute(binaryElement, kKPKXmlCompressed, KPKStringFromBool(compress));
    if(compress) {
      binaryElement.stringValue = [data.data.kpk_gzipDeflated base64EncodedStringWithOptions:0];
    }
    else {
      binaryElement.stringValue = [data.data base64EncodedStringWithOptions:0];
    }
    [binaryElements addChild:binaryElement];
  }
  return binaryElements;
}

- (DDXMLElement *)_xmlBinary:(KPKBinary *)binary {
  NSAssert(self.binaryData, @"Internal inconsicenty. Serialization for binary requested but no binaries supplied!");
  DDXMLElement *binaryElement = [DDXMLElement elementWithName:kKPKXmlBinary];
  KPKAddXmlElement(binaryElement, kKPKXmlKey, binary.name.kpk_xmlCompatibleString);
  DDXMLElement *valueElement = [DDXMLElement elementWithName:kKPKXmlValue];
  [binaryElement addChild:valueElement];
  NSUInteger reference = [self.binaryData indexOfObject:binary.internalData];
  KPKAddXmlAttribute(valueElement, kKPKXmlIconReference, KPKStringFromLong(reference));
  return binaryElement;
}

- (DDXMLElement *)_xmlIcons {
  DDXMLElement *customIconsElements = [DDXMLElement elementWithName:kKPKXmlCustomIcons];
  for (KPKIcon *icon in self.tree.metaData.mutableCustomIcons) {
    DDXMLElement *iconElement = [DDXMLNode elementWithName:kKPKXmlIcon];
    KPKAddXmlElement(iconElement, kKPKXmlUUID, icon.uuid.kpk_encodedString);
    KPKAddXmlElement(iconElement, kKPKXmlData, icon.encodedString);
    
    if(icon.name.length > 0) {
      NSAssert( self.fileVersion.version >= kKPKKdbxFileVersion4_1, @"Icon names require KDBX 4.1");
      KPKAddXmlElement(iconElement, kKPKXmlName, icon.name.kpk_xmlCompatibleString);
    }
    if(icon.modificationDate != nil) {
      NSAssert( self.fileVersion.version >= kKPKKdbxFileVersion4_1, @"Icon modificiation dates require KDBX 4.1");
      KPKAddXmlElement(iconElement, kKPKXmlLastModificationDate, KPKStringFromDate(icon.modificationDate, YES));
    }
    [customIconsElements addChild:iconElement];
  }
  return customIconsElements;
}

- (DDXMLElement *)_xmlCustomData:(NSDictionary<NSString *, NSString*> *)customData {
  DDXMLElement *customDataElement;
  if(customData.count > 0) {
    customDataElement = [DDXMLElement elementWithName:kKPKXmlCustomData];
    for(NSString *key in customData) {
      DDXMLElement *itemElement = [DDXMLElement elementWithName:kKPKXmlCustomDataItem];
      KPKAddXmlElement(itemElement, kKPKXmlKey, key.kpk_xmlCompatibleString);
      KPKAddXmlElement(itemElement, kKPKXmlValue, customData[key].kpk_xmlCompatibleString);
      [customDataElement addChild:itemElement];
    }
  }
  return customDataElement;
}

- (DDXMLElement *)_xmlMetaCustomData:(NSDictionary<NSString *, KPKModifiedString*> *)customData {
  DDXMLElement *customDataElement;
  
  customDataElement = [DDXMLElement elementWithName:kKPKXmlCustomData];
  for(NSString *key in customData) {
    DDXMLElement *itemElement = [DDXMLElement elementWithName:kKPKXmlCustomDataItem];
    KPKModifiedString *string = customData[key];
    KPKAddXmlElement(itemElement, kKPKXmlKey, key.kpk_xmlCompatibleString);
    KPKAddXmlElement(itemElement, kKPKXmlValue, string.value.kpk_xmlCompatibleString);
    if(string.modificationDate != nil) {
      NSAssert( self.fileVersion.version >= kKPKKdbxFileVersion4_1, @"Custom data modificiation dates require KDBX 4.1");
      KPKAddXmlElement(itemElement, kKPKXmlLastModificationDate, KPKStringFromDate(string.modificationDate, self.useRelativeDate));
    }
    [customDataElement addChild:itemElement];
  }
  return customDataElement;
}


- (DDXMLElement *)_xmlDeletedObjects {
  DDXMLElement *deletedObjectsElement = [DDXMLElement elementWithName:kKPKXmlDeletedObjects];
  for(NSUUID *uuid in self.tree.mutableDeletedObjects) {
    KPKDeletedNode *node = self.tree.mutableDeletedObjects[ uuid ];
    DDXMLElement *deletedElement = [DDXMLNode elementWithName:kKPKXmlDeletedObject];
    KPKAddXmlElement(deletedElement, kKPKXmlUUID, node.uuid.kpk_encodedString);
    KPKAddXmlElement(deletedElement, kKPKXmlDeletionTime, KPKStringFromDate(node.deletionDate, self.useRelativeDate));
    [deletedObjectsElement addChild:deletedElement];
  }
  return deletedObjectsElement;
}

- (DDXMLElement *)_xmlTimeinfo:(KPKTimeInfo *)timeInfo {
  DDXMLElement *timesElement = [DDXMLNode elementWithName:kKPKXmlTimes];
  KPKAddXmlElementIfNotNil(timesElement, kKPKXmlLastModificationDate, KPKStringFromDate(timeInfo.modificationDate, self.useRelativeDate));
  KPKAddXmlElementIfNotNil(timesElement, kKPKXmlCreationDate, KPKStringFromDate(timeInfo.creationDate, self.useRelativeDate));
  KPKAddXmlElementIfNotNil(timesElement, kKPKXmlLastAccessDate, KPKStringFromDate(timeInfo.accessDate, self.useRelativeDate));
  KPKAddXmlElementIfNotNil(timesElement, kKPKXmlExpirationDate, KPKStringFromDate(timeInfo.expirationDate, self.useRelativeDate));
  KPKAddXmlElement(timesElement, kKPKXmlExpires, KPKStringFromBool(timeInfo.expires));
  KPKAddXmlElement(timesElement, kKPKXmlUsageCount, KPKStringFromLong(timeInfo.usageCount));
  KPKAddXmlElementIfNotNil(timesElement, kKPKXmlLocationChanged, KPKStringFromDate(timeInfo.locationChanged, self.useRelativeDate));
  return timesElement;
}

- (void)_encodeProtected:(DDXMLElement *)root {
  DDXMLNode *protectedAttribute = [root attributeForName:kKPKXmlProtected];
  if([[protectedAttribute stringValue] isEqualToString:kKPKXmlTrue]) {
    NSString *str = [root stringValue];
    NSMutableData *data = [[str dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    
    // Protect the password
    [self.randomStream xor:data];
    
    // Base64 encode the string
    [root setStringValue:[data base64EncodedStringWithOptions:0]];
  }
  
  for(DDXMLNode *node in [root children]) {
    if([node kind] == DDXMLElementKind) {
      [self _encodeProtected:(DDXMLElement*)node];
    }
  }
}

@end
