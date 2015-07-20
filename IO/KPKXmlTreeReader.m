//
//  KPXmlTreeReader.m
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

#import "KPKXmlTreeReader.h"
#import "DDXMLDocument.h"
#import "KPKXmlHeaderReader.h"

#import "KPKTree.h"
#import "KPKMetaData.h"
#import "KPKTimeInfo.h"
#import "KPKGroup.h"
#import "KPKNode.h"
#import "KPKDeletedNode.h"
#import "KPKEntry.h"
#import "KPKBinary.h"
#import "KPKAttribute.h"
#import "KPKAutotype.h"
#import "KPKWindowAssociation.h"

#import "KPKFormat.h"
#import "KPKXmlFormat.h"
#import "KPKXmlElements.h"
#import "KPKErrors.h"
#import "KPKIcon.h"

#import "KPKRandomStream.h"
#import "KPKArc4RandomStream.h"
#import "KPKSalsa20RandomStream.h"
#import "KPKXmlUtilities.h"

#import "DDXML.h"
#import "DDXMLElementAdditions.h"

#import "NSMutableData+Base64.h"
#import "NSData+CommonCrypto.h"
#import "NSUUID+KeePassKit.h"
#import "NSColor+KeePassKit.h"

@interface KPKXmlTreeReader () {
@private
  DDXMLDocument *_document;
  KPKXmlHeaderReader *_headerReader;
  KPKRandomStream *_randomStream;
  NSDateFormatter *_dateFormatter;
  NSMutableDictionary *_binaryMap;
  NSMutableDictionary *_iconMap;
}
@end

@implementation KPKXmlTreeReader

- (id)initWithData:(NSData *)data headerReader:(id<KPKHeaderReading>)headerReader {
  self = [super init];
  if(self) {
    _document = [[DDXMLDocument alloc] initWithData:data options:0 error:nil];
    if(headerReader) {
      NSAssert([headerReader isKindOfClass:[KPKXmlHeaderReader class]], @"Headerreader needs to be XML header reader");
      _headerReader = (KPKXmlHeaderReader *)headerReader;
      if(![self _setupRandomStream]) {
        _document = nil;
        _headerReader = nil;
        self = nil;
        return nil;
      }
    }
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
  }
  return self;
}

- (KPKTree *)tree:(NSError *__autoreleasing *)error {
  if(!_document) {
    KPKCreateError(error, KPKErrorNoData, @"ERROR_NO_DATA", "");
    return nil;
  }
  
  DDXMLElement *rootElement = [_document rootElement];
  if(![[rootElement name] isEqualToString:kKPKXmlKeePassFile]) {
    KPKCreateError(error, KPKErrorXMLKeePassFileElementMissing, @"ERROR_KEEPASSFILE_ELEMENT_MISSING", "");
    return nil;
  }
  
  if(_headerReader) {
    [self _decodeProtected:rootElement];
  }
  
  KPKTree *tree = [[KPKTree alloc] init];
  
  tree.metaData.updateTiming = NO;
  
  /* Set the information we got from the header */
  tree.metaData.rounds = _headerReader.rounds;
  tree.metaData.compressionAlgorithm = _headerReader.compressionAlgorithm;
  
  /* Parse the rest of the metadata from the file */
  DDXMLElement *metaElement = [rootElement elementForName:kKPKXmlMeta];
  if(!metaElement) {
    KPKCreateError(error, KPKErrorXMLMetaElementMissing, @"ERROR_META_ELEMENT_MISSING", "");
    return nil;
  }
  NSString *headerHash = KPKXmlString(metaElement, kKPKXmlHeaderHash);
  if(headerHash) {
    NSData *expectedHash = [NSMutableData dataFromBase64EncodedString:headerHash encoding:NSUTF8StringEncoding];
    if(![_headerReader verifyHeader:expectedHash]) {
      KPKCreateError(error, KPKErrorXMLHeaderHashVerificationFailed, @"ERROR_HEADER_HASH_VERIFICATION_FAILED", "");
    }
  }
  
  [self _parseMeta:metaElement metaData:tree.metaData];
  
  DDXMLElement *root = [rootElement elementForName:kKPKXmlRoot];
  if(!root) {
    KPKCreateError(error, KPKErrorXMLRootElementMissing, @"ERROR_ROOT_ELEMENT_MISSING", "");
    return nil;
  }
  
  DDXMLElement *rootGroup = [root elementForName:kKPKXmlGroup];
  if(!rootGroup) {
    KPKCreateError(error, KPKErrorXMLGroupElementMissing, @"ERROR_GROUP_ELEMENT_MISSING", "");
    return nil;
  }
  
  tree.root = [self _parseGroup:rootGroup forTree:tree];
  [self _parseDeletedObjects:root tree:tree];
  
  tree.metaData.updateTiming = YES;
  
  return tree;
}

- (void)_decodeProtected:(DDXMLElement *)element {
  DDXMLNode *protectedAttribute = [element attributeForName:kKPKXmlProtected];
  if([[protectedAttribute stringValue] isEqualToString:kKPKXmlTrue]) {
    NSString *valueString = [element stringValue];
    NSData *valueData = [valueString dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *decodedData = [NSMutableData mutableDataWithBase64DecodedData:valueData];
    /*
     XOR the random stream against the data
     */
    [_randomStream xor:decodedData];
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
  data.databaseNameChanged = KPKXmlDate(_dateFormatter, metaElement, kKPKXmlDatabaseNameChanged);
  data.databaseDescription = KPKXmlString(metaElement, kKPKXmlDatabaseDescription);
  data.databaseDescriptionChanged = KPKXmlDate(_dateFormatter, metaElement, kKPKXmlDatabaseDescriptionChanged);
  data.defaultUserName = KPKXmlString(metaElement, kKPKXmlDefaultUserName);
  data.defaultUserNameChanged = KPKXmlDate(_dateFormatter, metaElement, kKPKXmlDefaultUserNameChanged);
  data.maintenanceHistoryDays = KPKXmlInteger(metaElement, kKPKXmlMaintenanceHistoryDays);
  /*
   Color is coded in Hex #001122
   */
  data.color = [NSColor colorWithHexString:KPKXmlString(metaElement, kKPKXmlColor)];
  data.masterKeyChanged = KPKXmlDate(_dateFormatter, metaElement, kKPKXmlMasterKeyChanged);
  data.masterKeyChangeRecommendationInterval = KPKXmlInteger(metaElement, kKPKXmlMasterKeyChangeRecommendationInterval);
  data.masterKeyChangeEnforcementInterval = KPKXmlInteger(metaElement, kKPKXmlMasterKeyChangeForceInterval);
  
  DDXMLElement *memoryProtectionElement = [metaElement elementForName:kKPKXmlMemoryProtection];
  
  data.protectTitle = KPKXmlBool(memoryProtectionElement, kKPKXmlProtectTitle);
  data.protectUserName = KPKXmlBool(memoryProtectionElement, kKPKXmlProtectUserName);
  data.protectPassword = KPKXmlBool(memoryProtectionElement, kKPKXmlProtectPassword);
  data.protectUrl = KPKXmlBool(memoryProtectionElement, kKPKXmlProtectURL);
  data.protectNotes = KPKXmlBool(memoryProtectionElement, kKPKXmlProtectNotes);
  
  data.useTrash = KPKXmlBool(metaElement, kKPKXmlRecycleBinEnabled);
  data.trashUuid = [NSUUID uuidWithEncodedString:KPKXmlString(metaElement, kKPKXmlRecycleBinUUID)];
  data.trashChanged = KPKXmlDate(_dateFormatter, metaElement, kKPKXmlRecycleBinChanged);
  data.entryTemplatesGroup = [NSUUID uuidWithEncodedString:KPKXmlString(metaElement, kKPKXmlEntryTemplatesGroup)];
  data.entryTemplatesGroupChanged = KPKXmlDate(_dateFormatter, metaElement, kKPKXmlEntryTemplatesGroupChanged);
  data.historyMaxItems = KPKXmlInteger(metaElement, kKPKXmlHistoryMaxItems);
  data.historyMaxSize = KPKXmlInteger(metaElement, kKPKXmlHistoryMaxSize);
  data.lastSelectedGroup = [NSUUID uuidWithEncodedString:KPKXmlString(metaElement, kKPKXmlLastSelectedGroup)];
  data.lastTopVisibleGroup = [NSUUID uuidWithEncodedString:KPKXmlString(metaElement, kKPKXmlLastTopVisibleGroup)];
  
  [self _parseCustomIcons:metaElement meta:data];
  [self _parseBinaries:metaElement meta:data];
  [self _parseCustomData:metaElement meta:data];
}

- (KPKGroup *)_parseGroup:(DDXMLElement *)groupElement forTree:(KPKTree *)tree{
  KPKGroup *group = [[KPKGroup alloc] init];
  
  group.updateTiming = NO;
  group.tree = tree;
  
  group.uuid = [NSUUID uuidWithEncodedString:KPKXmlString(groupElement, kKPKXmlUUID)];
  if (group.uuid == nil) {
    group.uuid = [NSUUID UUID];
  }
  
  group.name = KPKXmlString(groupElement, @"Name");
  group.notes = KPKXmlString(groupElement, @"Notes");
  group.iconId = KPKXmlInteger(groupElement, @"IconID");
  
  DDXMLElement *customIconUuidElement = [groupElement elementForName:@"CustomIconUUID"];
  if (customIconUuidElement != nil) {
    group.iconUUID = [NSUUID uuidWithEncodedString:[customIconUuidElement stringValue]];
  }
  
  DDXMLElement *timesElement = [groupElement elementForName:@"Times"];
  [self _parseTimes:group.timeInfo element:timesElement];
  
  group.isExpanded =  KPKXmlBool(groupElement, kKPKXmlIsExpanded);
  
  group.defaultAutoTypeSequence = KPKXmlNonEmptyString(groupElement, kKPKXmlDefaultAutoTypeSequence);
  
  group.isAutoTypeEnabled = parseInheritBool(groupElement, kKPKXmlEnableAutoType);
  group.isSearchEnabled = parseInheritBool(groupElement, kKPKXmlEnableSearching);
  group.lastTopVisibleEntry = [NSUUID uuidWithEncodedString:KPKXmlString(groupElement, kKPKXmlLastTopVisibleEntry)];
  
  for (DDXMLElement *element in [groupElement elementsForName:@"Entry"]) {
    KPKEntry *entry = [self _parseEntry:element forTree:tree ignoreHistory:NO];
    [group addEntry:entry];
  }
  
  for (DDXMLElement *element in [groupElement elementsForName:@"Group"]) {
    KPKGroup *subGroup = [self _parseGroup:element forTree:tree];
    [group addGroup:subGroup];
  }
  
  group.updateTiming = YES;
  return group;
}

- (KPKEntry *)_parseEntry:(DDXMLElement *)entryElement forTree:(KPKTree *)tree ignoreHistory:(BOOL)ignoreHistory {
  KPKEntry *entry = [[KPKEntry alloc] init];
  
  entry.updateTiming = NO;
  entry.tree = tree;
  
  entry.uuid = [NSUUID uuidWithEncodedString:KPKXmlString(entryElement, kKPKXmlUUID)];
  if (entry.uuid == nil) {
    entry.uuid = [NSUUID UUID];
  }
  
  entry.iconId = KPKXmlInteger(entryElement, kKPKXmlIconId);
  
  DDXMLElement *customIconUuidElement = [entryElement elementForName:@"CustomIconUUID"];
  if (customIconUuidElement != nil) {
    entry.iconUUID = [NSUUID uuidWithEncodedString:[customIconUuidElement stringValue]];
  }
  
  entry.foregroundColor =  [NSColor colorWithHexString:KPKXmlString(entryElement, @"ForegroundColor")];
  entry.backgroundColor = [NSColor colorWithHexString:KPKXmlString(entryElement, @"BackgroundColor")];
  entry.overrideURL = KPKXmlString(entryElement, @"OverrideURL");
  entry.tags = KPKXmlString(entryElement, @"Tags");
  
  DDXMLElement *timesElement = [entryElement elementForName:@"Times"];
  [self _parseTimes:entry.timeInfo element:timesElement];
  
  for (DDXMLElement *element in [entryElement elementsForName:@"String"]) {
    DDXMLElement *valueElement = [element elementForName:kKPKXmlValue];
    BOOL isProtected = KPKXmlBoolAttribute(valueElement, kKPKXmlProtected) || KPKXmlBoolAttribute(valueElement, kKPKXMLProtectInMemory);
    KPKAttribute *attribute = [[KPKAttribute alloc] initWithKey:KPKXmlString(element, kKPKXmlKey)
                                                          value:[valueElement stringValue]
                                                    isProtected:isProtected];
    
    if([attribute.key isEqualToString:kKPKTitleKey]) {
      entry.title = attribute.value;
      entry.protectTitle = attribute.isProtected;
    }
    else if([attribute.key isEqualToString:kKPKUsernameKey]) {
      entry.username = attribute.value;
      entry.protectUsername = attribute.isProtected;
    }
    else if([attribute.key isEqualToString:kKPKPasswordKey]) {
      entry.password = attribute.value;
      entry.protectPassword = attribute.isProtected;
    }
    else if([attribute.key isEqualToString:kKPKURLKey]) {
      entry.url = attribute.value;
      entry.protectUrl = attribute.isProtected;
    }
    else if([attribute.key isEqualToString:kKPKNotesKey]) {
      entry.notes = attribute.value;
      entry.protectNotes = attribute.isProtected;
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
  
  
  entry.updateTiming = YES;
  return entry;
}

- (void)_parseTimes:(KPKTimeInfo *)timeInfo element:(DDXMLElement *)nodeElement {
  timeInfo.modificationDate = KPKXmlDate(_dateFormatter, nodeElement, kKPKXmlLastModificationDate);
  timeInfo.creationDate = KPKXmlDate(_dateFormatter, nodeElement, kKPKXmlCreationDate);
  timeInfo.accessDate = KPKXmlDate(_dateFormatter, nodeElement, kKPKXmlLastAccessDate);
  timeInfo.expirationDate = KPKXmlDate(_dateFormatter, nodeElement, kKPKXmlExpirationDate);
  timeInfo.expires = KPKXmlBool(nodeElement, kKPKXmlExpires);
  timeInfo.usageCount = KPKXmlInteger(nodeElement, kKPKXmlUsageCount);
  timeInfo.locationChanged = KPKXmlDate(_dateFormatter, nodeElement, kKPKXmlLocationChanged);
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
  _iconMap = [[NSMutableDictionary alloc] init];
  DDXMLElement *customIconsElement = [root elementForName:@"CustomIcons"];
  for (DDXMLElement *iconElement in [customIconsElement elementsForName:@"Icon"]) {
    NSUUID *uuid = [NSUUID uuidWithEncodedString:KPKXmlString(iconElement, kKPKXmlUUID)];
    KPKIcon *icon = [[KPKIcon alloc] initWithUUID:uuid encodedString:KPKXmlString(iconElement, @"Data")];
    [metaData addCustomIcon:icon];
    _iconMap[ icon.uuid ] = icon;
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
  NSUInteger binaryCount = [[binariesElement elementsForName:@"Binary"] count];
  _binaryMap = [[NSMutableDictionary alloc] initWithCapacity:MAX(1,binaryCount)];
  for (DDXMLElement *element in [binariesElement elementsForName:@"Binary"]) {
    DDXMLNode *idAttribute = [element attributeForName:@"ID"];
    
    KPKBinary *binary = [[KPKBinary alloc] initWithName:@"UNNAMED" value:[element stringValue] compressed:KPKXmlBoolAttribute(element, @"Compressed")];
    NSUInteger index = [[idAttribute stringValue] integerValue];
    _binaryMap[ @(index) ] = binary;
  }
}

- (void)_parseEntryBinaries:(DDXMLElement *)entryElement entry:(KPKEntry *)entry {
  /*
   <Binary>
   <Key></Key>
   <Value Ref="1"></Value>
   </Binary>
   */
  
  for (DDXMLElement *binaryElement in [entryElement elementsForName:@"Binary"]) {
    DDXMLElement *valueElement = [binaryElement elementForName:kKPKXmlValue];
    DDXMLNode *refAttribute = [valueElement attributeForName:@"Ref"];
    NSUInteger index = [[refAttribute stringValue] integerValue];
    
    KPKBinary *binary = _binaryMap[ @(index) ];
    binary.name = KPKXmlString(binaryElement, kKPKXmlKey);
    [entry addBinary:binary];
  }
}

- (void)_parseCustomData:(DDXMLElement *)root meta:(KPKMetaData *)metaData {
  DDXMLElement *customDataElement = [root elementForName:@"CustomData"];
  for(DDXMLElement *dataElement in [customDataElement elementsForName:@"Item"]) {
    /*
     <CustomData>
     <Item>
     <Key></Key>
     <Value>-Base64EncodedValue-</Value>
     </Item>
     </CustomData>
     */
    KPKBinary *customData = [[KPKBinary alloc] initWithName:KPKXmlString(dataElement, kKPKXmlKey) value:KPKXmlString(dataElement, kKPKXmlValue) compressed:NO];
    [metaData.customData addObject:customData];
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
  
  DDXMLElement *autotypeElement = [entryElement elementForName:@"AutoType"];
  if(!autotypeElement) {
    return;
  }
  KPKAutotype *autotype = [[KPKAutotype alloc] init];
  autotype.isEnabled = KPKXmlBool(autotypeElement, @"Enabled");
  autotype.defaultKeystrokeSequence = KPKXmlNonEmptyString(autotypeElement, @"DefaultSequence");
  NSInteger obfuscate = KPKXmlInteger(autotypeElement, @"DataTransferObfuscation");
  autotype.obfuscateDataTransfer = obfuscate > 0;
  autotype.entry = entry;
  
  for(DDXMLElement *associationElement in [autotypeElement elementsForName:@"Association"]) {
    KPKWindowAssociation *association = [[KPKWindowAssociation alloc] initWithWindow:KPKXmlString(associationElement, @"Window")
                                                                   keystrokeSequence:KPKXmlNonEmptyString(associationElement, @"KeystrokeSequence")];
    [autotype addAssociation:association];
  }
  entry.autotype = autotype;
}

- (void)_parseHistory:(DDXMLElement *)entryElement entry:(KPKEntry *)entry {
  
  DDXMLElement *historyElement = [entryElement elementForName:@"History"];
  if (historyElement != nil) {
    for (DDXMLElement *entryElement in [historyElement elementsForName:@"Entry"]) {
      KPKEntry *historyEntry = [self _parseEntry:entryElement forTree:entry.tree ignoreHistory:YES];
      [entry addHistoryEntry:historyEntry];
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
  DDXMLElement *deletedObjects = [root elementForName:@"DeletedObjects"];
  for(DDXMLElement *deletedObject in [deletedObjects elementsForName:@"DeletedObject"]) {
    NSUUID *uuid = [[NSUUID alloc] initWithEncodedUUIDString:KPKXmlString(deletedObject, kKPKXmlUUID)];
    NSDate *date = KPKXmlDate(_dateFormatter, deletedObject, @"DeletionTime");
    KPKDeletedNode *deletedNode = [[KPKDeletedNode alloc] initWithUUID:uuid date:date];
    tree.deletedObjects[ deletedNode.uuid ] = deletedNode;
  }
}

- (BOOL)_setupRandomStream {
  switch(_headerReader.randomStreamID ) {
    case KPKRandomStreamSalsa20:
      _randomStream = [[KPKSalsa20RandomStream alloc] init:_headerReader.protectedStreamKey];
      return YES;
      
    case KPKRandomStreamArc4:
      _randomStream = [[KPKArc4RandomStream alloc] init:_headerReader.protectedStreamKey];
      return YES;
      
    default:
      return NO;
  }
}
@end
