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
#import "KPKTree_Private.h"

#import "DDXMLDocument.h"
#import "DDXMLElementAdditions.h"
#import "NSUUID+KPKAdditions.h"

#import "KPKKdbxFormat.h"
#import "KPKNode_Private.h"
#import "KPKGroup.h"
#import "KPKEntry.h"
#import "KPKFormat.h"
#import "KPKMetaData.h"
#import "KPKMetaData_Private.h"
#import "KPKTimeInfo.h"
#import "KPKDeletedNode.h"
#import "KPKAttribute.h"
#import "KPKBinary.h"
#import "KPKIcon.h"
#import "KPKAutotype.h"
#import "KPKWindowAssociation.h"

#import "NSColor+KPKAdditions.h"
#import "NSString+KPKXmlUtilities.h"

#import "KPKRandomStream.h"

#import "KPKXmlUtilities.h"

@interface KPKXmlTreeWriter ()

@property (strong, readwrite) KPKTree *tree;
@property (readonly, copy) NSData *headerHash;
@property (readonly, strong) KPKRandomStream *randomStream;
@property (strong) NSDateFormatter *dateFormatter;
@property (readonly, copy) NSArray *binaries;

@property (nonatomic, readonly) BOOL encrypted;

@end

@implementation KPKXmlTreeWriter

- (instancetype)initWithTree:(KPKTree *)tree delegate:(id<KPKXmlTreeWriterDelegate>)delegate {
  self = [super init];
  if(self) {
    _delegate = delegate;
    _tree = tree;
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

- (NSArray *)binaries {
  return [[self.delegate binariesForWriter:self] copy];
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
  
  if(self.headerHash) {
    KPKAddXmlElement(metaElement, kKPKXmlHeaderHash, [self.headerHash base64EncodedStringWithOptions:0]);
  }
  
  if(!self.randomStream || kKPKKdbxFileVersion4 > [self.delegate fileVersionForWriter:self]) {
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
    self.dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
  }
  
  KPKAddXmlElement(metaElement, kKPKXmlDatabaseName, metaData.databaseName.kpk_xmlCompatibleString);
  KPKAddXmlElement(metaElement, kKPKXmlDatabaseNameChanged, KPKStringFromDate(self.dateFormatter, metaData.databaseNameChanged));
  KPKAddXmlElement(metaElement, kKPKXmlDatabaseDescription, metaData.databaseDescription.kpk_xmlCompatibleString);
  KPKAddXmlElement(metaElement, kKPKXmlDatabaseDescriptionChanged, KPKStringFromDate(self.dateFormatter, metaData.databaseDescriptionChanged));
  KPKAddXmlElement(metaElement, kKPKXmlDefaultUserName, metaData.defaultUserName.kpk_xmlCompatibleString);
  KPKAddXmlElement(metaElement, kKPKXmlDefaultUserNameChanged, KPKStringFromDate(self.dateFormatter, metaData.defaultUserNameChanged));
  KPKAddXmlElement(metaElement, kKPKXmlMaintenanceHistoryDays, KPKStringFromLong(metaData.maintenanceHistoryDays));
  KPKAddXmlElement(metaElement, kKPKXmlColor, metaData.color.kpk_hexString);
  /* Settings changed only in KDBX4 */
  if(kKPKKdbxFileVersion4 <= [self.delegate fileVersionForWriter:self]) {
    KPKAddXmlElement(metaElement, kKPKXmlSettingsChanged, KPKStringFromDate(self.dateFormatter, metaData.settingsChanged));
  }
  KPKAddXmlElement(metaElement, kKPKXmlMasterKeyChanged, KPKStringFromDate(self.dateFormatter, metaData.masterKeyChanged));
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
  KPKAddXmlElement(metaElement, kKPKXmlRecycleBinUUID, metaData.trashUuid.kpk_encodedString);
  KPKAddXmlElement(metaElement, kKPKXmlRecycleBinChanged, KPKStringFromDate(self.dateFormatter, metaData.trashChanged));
  KPKAddXmlElement(metaElement, kKPKXmlEntryTemplatesGroup, metaData.entryTemplatesGroup.kpk_encodedString);
  KPKAddXmlElement(metaElement, kKPKXmlEntryTemplatesGroupChanged, KPKStringFromDate(self.dateFormatter, metaData.entryTemplatesGroupChanged));
  KPKAddXmlElement(metaElement, kKPKXmlHistoryMaxItems, KPKStringFromLong(metaData.historyMaxItems));
  KPKAddXmlElement(metaElement, kKPKXmlHistoryMaxSize, KPKStringFromLong(metaData.historyMaxSize));
  KPKAddXmlElement(metaElement, kKPKXmlLastSelectedGroup, metaData.lastSelectedGroup.kpk_encodedString);
  KPKAddXmlElement(metaElement, kKPKXmlLastTopVisibleGroup, metaData.lastTopVisibleGroup.kpk_encodedString);
  
  /* only add binaries if we actuall should, ask the delegate! */
  if(!self.randomStream || kKPKKdbxFileVersion4 > [self.delegate fileVersionForWriter:self]) {
    if(self.binaries) {
      [metaElement addChild:[self _xmlBinaries]];
    }
  }
  
  DDXMLElement *customDataElement = [self _xmlCustomData:metaData.mutableCustomData addEmptyElement:YES];
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
  
  DDXMLElement *timesElement = [self _xmlTimeinfo:group.timeInfo];
  [groupElement addChild:timesElement];
  
  KPKAddXmlElement(groupElement, kKPKXmlIsExpanded, KPKStringFromBool(group.isExpanded));
  NSString *keystrokes = (group.hasDefaultAutotypeSequence ? nil : group.defaultAutoTypeSequence.kpk_xmlCompatibleString);
  KPKAddXmlElement(groupElement, kKPKXmlDefaultAutoTypeSequence, keystrokes);
  KPKAddXmlElement(groupElement, kKPKXmlEnableAutoType, stringFromInheritBool(group.isAutoTypeEnabled));
  KPKAddXmlElement(groupElement, kKPKXmlEnableSearching, stringFromInheritBool(group.isSearchEnabled));
  KPKAddXmlElement(groupElement, kKPKXmlLastTopVisibleEntry, group.lastTopVisibleEntry.kpk_encodedString);
  
  DDXMLElement *customDataElement = [self _xmlCustomData:group.mutableCustomData addEmptyElement:NO];
  if(customDataElement) {
    [groupElement addChild:customDataElement];
  }
  
  for(KPKEntry *entry in group.entries) {
    [groupElement addChild:[self _xmlEntry:entry skipHistory:NO]];
  }
  
  for (KPKGroup *subGroup in group.groups) {
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
  KPKAddXmlElement(entryElement, @"ForegroundColor", entry.foregroundColor.kpk_hexString);
  KPKAddXmlElement(entryElement, @"BackgroundColor", entry.backgroundColor.kpk_hexString);
  KPKAddXmlElement(entryElement, @"OverrideURL", entry.overrideURL.kpk_xmlCompatibleString);
  KPKAddXmlElement(entryElement, @"Tags", [entry.tags componentsJoinedByString:@";"].kpk_xmlCompatibleString);
  
  DDXMLElement *timesElement = [self _xmlTimeinfo:entry.timeInfo];
  [entryElement addChild:timesElement];
  
  DDXMLElement *customDataElement = [self _xmlCustomData:entry.mutableCustomData addEmptyElement:NO];
  if(customDataElement) {
    [entryElement addChild:customDataElement];
  }
  
  for(KPKAttribute *attribute in entry.attributes) {
    [entryElement addChild:[self _xmlAttribute:attribute metaData:entry.tree.metaData]];
  }
  for(KPKBinary *binary in entry.binaries) {
    [entryElement addChild:[self _xmlBinary:binary]];
  }
  
  [entryElement addChild:[self _xmlAutotype:entry.autotype]];
  
  // Add the history entries
  if(!skipHistory) {
    DDXMLElement *historyElement = [DDXMLElement elementWithName:kKPKXmlHistory];
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
  DDXMLElement *attributeElement = [DDXMLElement elementWithName:@"String"];
  KPKAddXmlElement(attributeElement, kKPKXmlKey, attribute.key);
  
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
  for(KPKBinary *binary in self.binaries) {
    DDXMLElement *binaryElement = [DDXMLElement elementWithName:kKPKXmlBinary];
    KPKAddXmlAttribute(binaryElement, kKPKXmlBinaryId, KPKStringFromLong([self.binaries indexOfObject:binary]));
    KPKAddXmlAttribute(binaryElement, kKPKXmlCompressed, KPKStringFromBool(compress));
    binaryElement.stringValue = [binary encodedStringUsingCompression:compress];
    [binaryElements addChild:binaryElement];
  }
  return binaryElements;
}

- (DDXMLElement *)_xmlBinary:(KPKBinary *)binary {
  DDXMLElement *binaryElement = [DDXMLElement elementWithName:kKPKXmlBinary];
  KPKAddXmlElement(binaryElement, kKPKXmlKey, binary.name.kpk_xmlCompatibleString);
  DDXMLElement *valueElement = [DDXMLElement elementWithName:kKPKXmlValue];
  [binaryElement addChild:valueElement];
  NSUInteger reference = [self.delegate writer:self referenceForBinary:binary];
  NSAssert(reference != NSNotFound, @"Binary has to be in binaries array");
  KPKAddXmlAttribute(valueElement, kKPKXmlIconReference, KPKStringFromLong(reference));
  return binaryElement;
}

- (DDXMLElement *)_xmlIcons {
  DDXMLElement *customIconsElements = [DDXMLElement elementWithName:kKPKXmlCustomIcons];
  for (KPKIcon *icon in self.tree.metaData.mutableCustomIcons) {
    DDXMLElement *iconElement = [DDXMLNode elementWithName:kKPKXmlIcon];
    KPKAddXmlElement(iconElement, kKPKXmlUUID, icon.uuid.kpk_encodedString);
    KPKAddXmlElement(iconElement, kKPKXmlData, icon.encodedString);
    [customIconsElements addChild:iconElement];
  }
  return customIconsElements;
}

- (DDXMLElement *)_xmlCustomData:(NSDictionary<NSString *, NSString*> *)customData addEmptyElement:(BOOL)addEmpty{
  DDXMLElement *customDataElement;
  if(addEmpty || customData.count > 0) {
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

- (DDXMLElement *)_xmlDeletedObjects {
  DDXMLElement *deletedObjectsElement = [DDXMLElement elementWithName:kKPKXmlDeletedObjects];
  for(NSUUID *uuid in self.tree.mutableDeletedObjects) {
    KPKDeletedNode *node = self.tree.mutableDeletedObjects[ uuid ];
    DDXMLElement *deletedElement = [DDXMLNode elementWithName:kKPKXmlDeletedObject];
    KPKAddXmlElement(deletedElement, kKPKXmlUUID, node.uuid.kpk_encodedString);
    KPKAddXmlElement(deletedElement, kKPKXmlDeletionTime, KPKStringFromDate(self.dateFormatter, node.deletionDate));
    [deletedObjectsElement addChild:deletedElement];
  }
  return deletedObjectsElement;
}

- (DDXMLElement *)_xmlTimeinfo:(KPKTimeInfo *)timeInfo {
  DDXMLElement *timesElement = [DDXMLNode elementWithName:kKPKXmlTimes];
  KPKAddXmlElementIfNotNil(timesElement, kKPKXmlLastModificationDate, KPKStringFromDate(self.dateFormatter, timeInfo.modificationDate));
  KPKAddXmlElementIfNotNil(timesElement, kKPKXmlCreationDate, KPKStringFromDate(self.dateFormatter, timeInfo.creationDate));
  KPKAddXmlElementIfNotNil(timesElement, kKPKXmlLastAccessDate, KPKStringFromDate(self.dateFormatter, timeInfo.accessDate));
  KPKAddXmlElementIfNotNil(timesElement, kKPKXmlExpirationDate, KPKStringFromDate(self.dateFormatter, timeInfo.expirationDate));
  KPKAddXmlElement(timesElement, kKPKXmlExpires, KPKStringFromBool(timeInfo.expires));
  KPKAddXmlElement(timesElement, kKPKXmlUsageCount, KPKStringFromLong(timeInfo.usageCount));
  KPKAddXmlElementIfNotNil(timesElement, kKPKXmlLocationChanged, KPKStringFromDate(self.dateFormatter, timeInfo.locationChanged));
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
