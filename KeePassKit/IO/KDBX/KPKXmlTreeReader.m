//  KPXmlTreeReader.m
//
//  KeePassKit
//
//  Created by Michael Starke on 20.07.13.
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

#import "KPKXmlTreeReader.h"

#import "KPKArc4RandomStream.h"
#import "KPKAttribute.h"
#import "KPKAutotype.h"
#import "KPKBinary.h"
#import "KPKBinary_Private.h"
#import "KPKChaCha20RandomStream.h"
#import "KPKData.h"
#import "KPKDeletedNode.h"
#import "KPKEntry.h"
#import "KPKEntry_Private.h"
#import "KPKErrors.h"
#import "KPKFormat.h"
#import "KPKGroup.h"
#import "KPKIcon.h"
#import "KPKMetaData.h"
#import "KPKMetaData_Private.h"
#import "KPKNode.h"
#import "KPKNode_Private.h"
#import "KPKRandomStream.h"
#import "KPKSalsa20RandomStream.h"
#import "KPKTimeInfo.h"
#import "KPKTree.h"
#import "KPKTree_Private.h"
#import "KPKWindowAssociation.h"
#import "KPKKdbxFormat.h"
#import "KPKXmlUtilities.h"

#import "NSData+CommonCrypto.h"
#import "NSData+KPKGzip.h"
#import "NSUUID+KPKAdditions.h"
#import "NSUIColor+KPKAdditions.h"

@interface KPKXmlTreeReader ()

@property (strong) DDXMLDocument *document;
@property (nonatomic, strong) KPKRandomStream *randomStream;
//@property (strong) NSDateFormatter *dateFormatter;
@property (assign) BOOL useRelativeDates;
@property (strong) NSMutableDictionary<NSNumber *, KPKData *> *binaryDataMap;
@property (strong) NSMutableDictionary *iconMap;

@property (copy) NSData *headerHash;

@end

@implementation KPKXmlTreeReader

- (instancetype)initWithData:(NSData *)data {
  self = [self initWithData:data delegate:nil];
  return self;
}

- (instancetype)initWithData:(NSData *)data delegate:(id<KPKXmlTreeReaderDelegate>)delegate {
  self = [super init];
  if(self) {
    _delegate = delegate;
    _document = [[DDXMLDocument alloc] initWithData:data options:0 error:nil];
    _useRelativeDates = YES;
  }
  return self;
}

- (KPKRandomStream *)randomStream {
  return [self.delegate randomStreamForReader:self];
}

- (KPKTree *)tree:(NSError *__autoreleasing *)error {
  
  if(!self.randomStream || (kKPKKdbxFileVersion4 > [self.delegate fileVersionForReader:self])) {
    self.useRelativeDates = NO;
    /*
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
    self.dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
   */
  }
  
  if(!self.document) {
    KPKCreateError(error, KPKErrorNoData);
    return nil;
  }
  
  DDXMLElement *rootElement = [self.document rootElement];
  if(![rootElement.name isEqualToString:kKPKXmlKeePassFile]) {
    KPKCreateError(error, KPKErrorKdbxKeePassFileElementMissing);
    return nil;
  }
  
  if(self.randomStream) {
    [self _decodeProtected:rootElement];
  }
  
  KPKTree *tree = [[KPKTree alloc] init];
  
  tree.metaData.updateTiming = NO;
  
  /* Set the information we got from the header */
  
  /* Parse the rest of the metadata from the file */
  DDXMLElement *metaElement = [rootElement elementForName:kKPKXmlMeta];
  if(!metaElement) {
    KPKCreateError(error, KPKErrorKdbxMetaElementMissing);
    return nil;
  }
  if(![metaElement.parent isEqual:rootElement]) {
    NSLog(@"Warning: Meta Element is not a direct child of KeePassFile element!");
  }
  NSString *headerHash = KPKXmlString(metaElement, kKPKXmlHeaderHash);
  if(headerHash) {
    self.headerHash = [[NSData alloc] initWithBase64EncodedString:headerHash options:NSDataBase64DecodingIgnoreUnknownCharacters];
  }
  
  [self _parseMeta:metaElement metaData:tree.metaData];
  
  DDXMLElement *root = [rootElement elementForName:kKPKXmlRoot];
  if(!root) {
    KPKCreateError(error, KPKErrorKdbxRootElementMissing);
    return nil;
  }
  if(![root.parent isEqual:rootElement]) {
    NSLog(@"Warning: Root element is not direct child of KeePassFile element");
  }
  
  DDXMLElement *rootGroup = [root elementForName:kKPKXmlGroup];
  if(!rootGroup) {
    KPKCreateError(error, KPKErrorKdbxGroupElementMissing);
    return nil;
  }
  
  tree.root = [self _parseGroup:rootGroup];
  [self _parseDeletedObjects:root tree:tree];
  
  tree.metaData.updateTiming = YES;
  
  return tree;
}

- (void)_decodeProtected:(DDXMLElement *)element {
  if(!self.randomStream) {
    return; // not configured to decorde
  }
  DDXMLNode *protectedAttribute = [element attributeForName:kKPKXmlProtected];
  if([[protectedAttribute stringValue] isEqualToString:kKPKXmlTrue]) {
    NSString *valueString = [element stringValue];
    NSMutableData *decodedData = [[NSMutableData alloc] initWithBase64EncodedString:valueString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    /*
     XOR the random stream against the data
     */
    [self.randomStream xor:decodedData];
    NSString *unprotected = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
    [element setStringValue:unprotected];
  }
  
  for (DDXMLNode *node in [element children]) {
    if ([node kind] == DDXMLElementKind) {
      [self _decodeProtected:(DDXMLElement*)node];
    }
  }
}

- (void)_parseMeta:(DDXMLElement *)metaElement metaData:(KPKMetaData *)data {
  
  data.generator = KPKXmlString(metaElement, kKPKXmlGenerator);
  data.databaseName = KPKXmlString(metaElement, kKPKXmlDatabaseName);
  data.databaseNameChanged = KPKXmlDate(metaElement, kKPKXmlDatabaseNameChanged, self.useRelativeDates);
  data.databaseDescription = KPKXmlString(metaElement, kKPKXmlDatabaseDescription);
  data.databaseDescriptionChanged = KPKXmlDate(metaElement, kKPKXmlDatabaseDescriptionChanged, self.useRelativeDates);
  data.defaultUserName = KPKXmlString(metaElement, kKPKXmlDefaultUserName);
  data.defaultUserNameChanged = KPKXmlDate(metaElement, kKPKXmlDefaultUserNameChanged, self.useRelativeDates);
  data.maintenanceHistoryDays = KPKXmlInteger(metaElement, kKPKXmlMaintenanceHistoryDays);
  /*
   Color is coded in Hex #001122
   */
  data.color = [NSUIColor kpk_colorWithHexString:KPKXmlString(metaElement, kKPKXmlColor)];
  data.masterKeyChanged = KPKXmlDate(metaElement, kKPKXmlMasterKeyChanged, self.useRelativeDates);
  data.masterKeyChangeRecommendationInterval = KPKXmlInteger(metaElement, kKPKXmlMasterKeyChangeRecommendationInterval);
  data.masterKeyChangeEnforcementInterval = KPKXmlInteger(metaElement, kKPKXmlMasterKeyChangeForceInterval);
  data.enforceMasterKeyChangeOnce = KPKXmlBool(metaElement, kKPKXmlMasterKeyChangeForceOnce);
  
  DDXMLElement *memoryProtectionElement = [metaElement elementForName:kKPKXmlMemoryProtection];
  
  data.protectTitle = KPKXmlBool(memoryProtectionElement, kKPKXmlProtectTitle);
  data.protectUserName = KPKXmlBool(memoryProtectionElement, kKPKXmlProtectUserName);
  data.protectPassword = KPKXmlBool(memoryProtectionElement, kKPKXmlProtectPassword);
  data.protectUrl = KPKXmlBool(memoryProtectionElement, kKPKXmlProtectURL);
  data.protectNotes = KPKXmlBool(memoryProtectionElement, kKPKXmlProtectNotes);
  
  data.useTrash = KPKXmlBool(metaElement, kKPKXmlRecycleBinEnabled);
  data.trashChanged = KPKXmlDate(metaElement, kKPKXmlRecycleBinChanged, self.useRelativeDates);
  data.entryTemplatesGroupChanged = KPKXmlDate(metaElement, kKPKXmlEntryTemplatesGroupChanged, self.useRelativeDates);
  data.historyMaxItems = KPKXmlInteger(metaElement, kKPKXmlHistoryMaxItems);
  data.historyMaxSize = KPKXmlInteger(metaElement, kKPKXmlHistoryMaxSize);
  
  /* Settings changed might not be supported */
  if([metaElement elementsForName:kKPKXmlSettingsChanged]) {
    data.settingsChanged = KPKXmlDate(metaElement, kKPKXmlSettingsChanged, self.useRelativeDates);
  }
  
  /* pares uuids only if string is valid */
  NSString *uuidString = KPKXmlString(metaElement, kKPKXmlRecycleBinUUID);
  if(uuidString) {
    data.trashUuid = [NSUUID kpk_uuidWithEncodedString:uuidString];
  }
  uuidString = KPKXmlString(metaElement, kKPKXmlEntryTemplatesGroup);
  if(uuidString) {
    data.entryTemplatesGroupUuid = [NSUUID kpk_uuidWithEncodedString:uuidString];
  }
  uuidString = KPKXmlString(metaElement, kKPKXmlLastSelectedGroup);
  if(uuidString) {
    data.lastSelectedGroup = [NSUUID kpk_uuidWithEncodedString:uuidString];
  }
  uuidString = KPKXmlString(metaElement, kKPKXmlLastTopVisibleGroup);
  if(uuidString) {
    data.lastTopVisibleGroup = [NSUUID kpk_uuidWithEncodedString:uuidString];
  }
  
  [self _parseCustomIcons:metaElement meta:data];
  [self _parseBinaries:metaElement meta:data];
  [self _parseCustomData:metaElement intoDictionary:data.mutableCustomData];
}

- (KPKGroup *)_parseGroup:(DDXMLElement *)groupElement {
  /* TODO: Add error handling when UUID reading fails! */
  NSUUID *uuid = [NSUUID kpk_uuidWithEncodedString:KPKXmlString(groupElement, kKPKXmlUUID)];
  KPKGroup *group = [[KPKGroup alloc] initWithUUID:uuid];
  
  group.updateTiming = NO;
  
  /* Group title is "Name" key in XML */
  group.title = KPKXmlString(groupElement, kKPKXmlName);
  group.notes = KPKXmlString(groupElement, kKPKXmlNotes);
  group.iconId = KPKXmlInteger(groupElement, kKPKXmlIconId);
  
  DDXMLElement *customIconUuidElement = [groupElement elementForName:kKPKXmlCustomIconUUID];
  if (customIconUuidElement != nil) {
    group.iconUUID = [NSUUID kpk_uuidWithEncodedString:[customIconUuidElement stringValue]];
  }
  
  DDXMLElement *timesElement = [groupElement elementForName:kKPKXmlTimes];
  [self _parseTimes:group.timeInfo element:timesElement];
  
  group.isExpanded =  KPKXmlBool(groupElement, kKPKXmlIsExpanded);
  
  group.defaultAutoTypeSequence = KPKXmlNonEmptyString(groupElement, kKPKXmlDefaultAutoTypeSequence);
  
  group.isAutoTypeEnabled = parseInheritBool(groupElement, kKPKXmlEnableAutoType);
  group.isSearchEnabled = parseInheritBool(groupElement, kKPKXmlEnableSearching);
  NSString *uuidString = KPKXmlString(groupElement, kKPKXmlLastTopVisibleEntry);
  if(uuidString) {
    group.lastTopVisibleEntry = [NSUUID kpk_uuidWithEncodedString:uuidString];
  }
  
  [self _parseCustomData:groupElement intoDictionary:group.mutableCustomData];
  
  for (DDXMLElement *element in [groupElement elementsForName:kKPKXmlEntry]) {
    KPKEntry *entry = [self _parseEntry:element ignoreHistory:NO];
    [entry addToGroup:group];
  }
  
  for (DDXMLElement *element in [groupElement elementsForName:kKPKXmlGroup]) {
    KPKGroup *subGroup = [self _parseGroup:element];
    [subGroup addToGroup:group];
  }
  
  group.updateTiming = YES;
  return group;
}

- (KPKEntry *)_parseEntry:(DDXMLElement *)entryElement ignoreHistory:(BOOL)ignoreHistory {
  NSUUID *uuid = [NSUUID kpk_uuidWithEncodedString:KPKXmlString(entryElement, kKPKXmlUUID)];
  KPKEntry *entry = [[KPKEntry alloc] initWithUUID:uuid];
  
  entry.updateTiming = NO;

  entry.iconId = KPKXmlInteger(entryElement, kKPKXmlIconId);
  
  DDXMLElement *customIconUuidElement = [entryElement elementForName:kKPKXmlCustomIconUUID];
  if (customIconUuidElement != nil) {
    entry.iconUUID = [NSUUID kpk_uuidWithEncodedString:[customIconUuidElement stringValue]];
  }
  
  entry.foregroundColor =  [NSUIColor kpk_colorWithHexString:KPKXmlString(entryElement, kKPKXmlForegroundColor)];
  entry.backgroundColor = [NSUIColor kpk_colorWithHexString:KPKXmlString(entryElement, kKPKXmlBackgroundColor)];
  entry.overrideURL = KPKXmlString(entryElement, kKPKXmlOverrideURL );
  NSString *tags = KPKXmlString(entryElement, kKPKXmlTags);
  if(tags.length > 0) {
    entry.tags = [tags componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",;"]];
  }
  
  DDXMLElement *timesElement = [entryElement elementForName:kKPKXmlTimes];
  [self _parseTimes:entry.timeInfo element:timesElement];
  
  for (DDXMLElement *element in [entryElement elementsForName:kKPKXmlString]) {
    DDXMLElement *valueElement = [element elementForName:kKPKXmlValue];
    BOOL isProtected = KPKXmlBoolAttribute(valueElement, kKPKXmlProtected) || KPKXmlBoolAttribute(valueElement, kKPKXmlProtectInMemory);
    KPKAttribute *attribute = [[KPKAttribute alloc] initWithKey:KPKXmlString(element, kKPKXmlKey)
                                                          value:[valueElement stringValue]
                                                    isProtected:isProtected];
    
    if(attribute.isDefault) {
      [entry _setValue:attribute.value forAttributeWithKey:attribute.key];
      [entry _setProtect:attribute.protect valueForkey:attribute.key];
    }
    else {
      [entry addCustomAttribute:attribute];
    }
  }
  [self _parseEntryBinaries:entryElement entry:entry];
  [self _parseEntryAutotype:entryElement entry:entry];
  
  if(!ignoreHistory) {
    [self _parseHistory:entryElement entry:entry];
  }
  
  [self _parseCustomData:entryElement intoDictionary:entry.mutableCustomData];
  
  entry.updateTiming = YES;
  return entry;
}

- (void)_parseTimes:(KPKTimeInfo *)timeInfo element:(DDXMLElement *)nodeElement {
  timeInfo.modificationDate = KPKXmlDate(nodeElement, kKPKXmlLastModificationDate, self.useRelativeDates);
  timeInfo.creationDate = KPKXmlDate(nodeElement, kKPKXmlCreationDate, self.useRelativeDates);
  timeInfo.accessDate = KPKXmlDate(nodeElement, kKPKXmlLastAccessDate, self.useRelativeDates);
  timeInfo.expirationDate = KPKXmlDate(nodeElement, kKPKXmlExpirationDate, self.useRelativeDates);
  timeInfo.expires = KPKXmlBool(nodeElement, kKPKXmlExpires);
  timeInfo.usageCount = KPKXmlInteger(nodeElement, kKPKXmlUsageCount);
  timeInfo.locationChanged = KPKXmlDate(nodeElement, kKPKXmlLocationChanged, self.useRelativeDates);
}

- (void)_parseCustomIcons:(DDXMLElement *)root meta:(KPKMetaData *)metaData {
  /*
   <CustomIcons>
   <Icon>
   <UUID></UUID>
   <Data></Data>
   </Icon>
   </CustomIcons>
   */
  self.iconMap = [[NSMutableDictionary alloc] init];
  DDXMLElement *customIconsElement = [root elementForName:kKPKXmlCustomIcons];
  for (DDXMLElement *iconElement in [customIconsElement elementsForName:kKPKXmlIcon]) {
    NSUUID *uuid = [NSUUID kpk_uuidWithEncodedString:KPKXmlString(iconElement, kKPKXmlUUID)];
    KPKIcon *icon = [[KPKIcon alloc] initWithUUID:uuid encodedString:KPKXmlString(iconElement, kKPKXmlData)];
    [metaData addCustomIcon:icon];
    self.iconMap[ icon.uuid ] = icon;
  }
}

- (void)_parseBinaries:(DDXMLElement *)root meta:(KPKMetaData *)meta {
  /*
   <Binaries>
   <Binary ID="1" Compressid="True">
   -Base64EncodedData-
   <Binary>
   </Binaries>
   */
  DDXMLElement *binariesElement = [root elementForName:kKPKXmlBinaries];
  NSUInteger binaryCount = [binariesElement elementsForName:kKPKXmlBinary].count;
  self.binaryDataMap = [[NSMutableDictionary alloc] initWithCapacity:MAX(1,binaryCount)];
  for (DDXMLElement *element in [binariesElement elementsForName:kKPKXmlBinary]) {
    DDXMLNode *idAttribute = [element attributeForName:kKPKXmlBinaryId];
    BOOL compressed = KPKXmlBoolAttribute(element, kKPKXmlCompressed);
    NSData *data = [[NSData alloc] initWithBase64EncodedString:[element stringValue] options:NSDataBase64DecodingIgnoreUnknownCharacters];
    // FIXME: Respect protect in memory settings!
    if(data) {
      NSUInteger index = [idAttribute stringValue].integerValue;
      if(compressed) {
        self.binaryDataMap[@(index)] = [[KPKData alloc] initWithUnprotectedData:data.kpk_gzipInflated];
      }
      else {
        self.binaryDataMap[@(index)] = [[KPKData alloc] initWithUnprotectedData:data];
      }
    }
  }
}

- (void)_parseEntryBinaries:(DDXMLElement *)entryElement entry:(KPKEntry *)entry {
  /*
   <Binary>
   <Key></Key>
   <Value Ref="1"></Value>
   </Binary>
   */
  
  for (DDXMLElement *binaryElement in [entryElement elementsForName:kKPKXmlBinary]) {
    DDXMLElement *valueElement = [binaryElement elementForName:kKPKXmlValue];
    DDXMLNode *refAttribute = [valueElement attributeForName:kKPKXmlIconReference];
    NSUInteger index = [refAttribute stringValue].integerValue;
    
    KPKData *binaryData = self.binaryDataMap[@(index)];
    /* we might have no binary map since we did not parse any binaries in the XML so ask the delegate for one */
    if(!binaryData) {
      binaryData = [[self.delegate reader:self binaryDataForReference:index] copy];
    }
    NSAssert(binaryData, @"Unable to dereference binary!");
    if(!binaryData) {
      continue;
    }
    KPKBinary *binary = [[KPKBinary alloc] init];
    binary.name = KPKXmlString(binaryElement, kKPKXmlKey);
    binary.internalData = binaryData;
    [entry addBinary:binary];
  }
}

- (void)_parseCustomData:(DDXMLElement *)root intoDictionary:(NSMutableDictionary<NSString *, NSString *> *)dict{
  DDXMLElement *customDataElement = [root elementForName:kKPKXmlCustomData];
  for(DDXMLElement *dataElement in [customDataElement elementsForName:kKPKXmlCustomDataItem]) {
    /*
     <CustomData>
     <Item>
     <Key></Key> - plain string
     <Value></Value> - plain string
     </Item>
     </CustomData>
     */
    NSString *key = KPKXmlString(dataElement, kKPKXmlKey);
    NSString *value = KPKXmlString(dataElement, kKPKXmlValue);
    if((key.length > 0) && value) {
      dict[key] = value;
    }
  }
}

- (void)_parseEntryAutotype:(DDXMLElement *)entryElement entry:(KPKEntry *)entry {
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
  
  DDXMLElement *autotypeElement = [entryElement elementForName:kKPKXmlAutotype];
  if(!autotypeElement) {
    return;
  }
  KPKAutotype *autotype = [[KPKAutotype alloc] init];
  autotype.enabled = KPKXmlBool(autotypeElement, kKPKXmlEnabled);
  autotype.defaultKeystrokeSequence = KPKXmlNonEmptyString(autotypeElement, kKPKXmlDefaultSequence);
  NSInteger obfuscate = KPKXmlInteger(autotypeElement, kKPKXmlDataTransferObfuscation);
  autotype.obfuscateDataTransfer = obfuscate > 0;
  
  for(DDXMLElement *associationElement in [autotypeElement elementsForName:kKPKXmlAssociation]) {
    KPKWindowAssociation *association = [[KPKWindowAssociation alloc] initWithWindowTitle:KPKXmlString(associationElement, kKPKXmlWindow)
                                                                   keystrokeSequence:KPKXmlNonEmptyString(associationElement, kKPKXmlKeystrokeSequence)];
    [autotype addAssociation:association];
  }
  entry.autotype = autotype;
}

- (void)_parseHistory:(DDXMLElement *)entryElement entry:(KPKEntry *)entry {
  
  DDXMLElement *historyElement = [entryElement elementForName:kKPKXmlHistory];
  if (historyElement != nil) {
    for (DDXMLElement *entryElement in [historyElement elementsForName:kKPKXmlEntry]) {
      KPKEntry *historyEntry = [self _parseEntry:entryElement ignoreHistory:YES];
      [entry _addHistoryEntry:historyEntry];
    }
  }
}

- (void)_parseDeletedObjects:(DDXMLElement *)root tree:(KPKTree *)tree {
  /*
   <DeletedObjects>
   <DeletedObject>
   <UUID>-Base64EncodedUUID/UUID>
   <DeletionTime>YYY-MM-DDTHH:MM:SSZ</DeletionTime>
   </DeletedObject>
   </DeletedObjects>
   */
  DDXMLElement *deletedObjects = [root elementForName:kKPKXmlDeletedObjects];
  for(DDXMLElement *deletedObject in [deletedObjects elementsForName:kKPKXmlDeletedObject]) {
    NSUUID *uuid = [[NSUUID alloc] initWithEncodedUUIDString:KPKXmlString(deletedObject, kKPKXmlUUID)];
    NSDate *date = KPKXmlDate(deletedObject, kKPKXmlDeletionTime, self.useRelativeDates);
    KPKDeletedNode *deletedNode = [[KPKDeletedNode alloc] initWithUUID:uuid date:date];
    tree.mutableDeletedObjects[ deletedNode.uuid ] = deletedNode;
  }
}
@end
