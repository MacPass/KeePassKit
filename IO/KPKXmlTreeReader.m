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
#import "KPKErrors.h"

#import "KPKRandomStream.h"
#import "KPKArc4RandomStream.h"
#import "KPKSalsa20RandomStream.h"

#import "NSMutableData+Base64.h"
#import "KPKIcon.h"

#import "DDXML.h"
#import "DDXMLElementAdditions.h"

#import "NSUUID+KeePassKit.h"
#import "NSColor+KeePassKit.h"
#import "KPKXmlUtilities.h"

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
    _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    _dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
    
  }
  return self;
}

- (KPKTree *)tree:(NSError *__autoreleasing *)error {
  if(!_document) {
    KPKCreateError(error, KPKErrorNoData, @"ERROR_NO_DATA", "");
    return nil;
  }
  
  DDXMLElement *rootElement = [_document rootElement];
  if(![[rootElement name] isEqualToString:@"KeePassFile"]) {
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
  DDXMLElement *metaElement = [rootElement elementForName:@"Meta"];
  if(!metaElement) {
    KPKCreateError(error, KPKErrorXMLMetaElementMissing, @"ERROR_META_ELEMENT_MISSING", "");
    return nil;
  }
  NSString *headerHash = KPKXmlString(metaElement, @"HeaderHash");
  if(headerHash) {
    // test headerhash;
  }
  
  [self _parseMeta:metaElement metaData:tree.metaData];
  
  DDXMLElement *root = [rootElement elementForName:@"Root"];
  if(!root) {
    KPKCreateError(error, KPKErrorXMLRootElementMissing, @"ERROR_ROOT_ELEMENT_MISSING", "");
    return nil;
  }
  
  DDXMLElement *rootGroup = [root elementForName:@"Group"];
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
  DDXMLNode *protectedAttribute = [element attributeForName:@"Protected"];
  if([[protectedAttribute stringValue] isEqualToString:@"True"]) {
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
  
  data.generator = KPKXmlString(metaElement, @"Generator");
  data.databaseName = KPKXmlString(metaElement, @"DatabaseName");
  data.databaseNameChanged = KPKXmlDate(_dateFormatter, metaElement, @"DatabaseNameChanged");
  data.databaseDescription = KPKXmlString(metaElement, @"DatabaseDescription");
  data.databaseNameChanged = KPKXmlDate(_dateFormatter, metaElement, @"DatabaseDescriptionChanged");
  data.defaultUserName = KPKXmlString(metaElement, @"DefaultUserName");
  data.defaultUserNameChanged = KPKXmlDate(_dateFormatter, metaElement, @"DefaultUserNameChanged");
  data.maintenanceHistoryDays = KPKXmlInteger(metaElement, @"MaintenanceHistoryDays");
  /*
   Color is coded in Hex #001122
   */
  data.color = [NSColor colorWithHexString:KPKXmlString(metaElement, @"Color")];
  data.masterKeyChanged = KPKXmlDate(_dateFormatter, metaElement, @"MasterKeyChanged");
  data.masterKeyChangeIsRequired = KPKXmlInteger(metaElement, @"MasterKeyChangeRec");
  data.masterKeyChangeIsForced = KPKXmlInteger(metaElement, @"MasterKeyChangeForce");
  
  DDXMLElement *memoryProtectionElement = [metaElement elementForName:@"MemoryProtection"];
  
  data.protectTitle = KPKXmlBool(memoryProtectionElement, @"ProtectTitle");
  data.protectUserName = KPKXmlBool(memoryProtectionElement, @"ProtectUserName");
  data.protectUserName = KPKXmlBool(memoryProtectionElement, @"ProtectPassword");
  data.protectUserName = KPKXmlBool(memoryProtectionElement, @"ProtectURL");
  data.protectUserName = KPKXmlBool(memoryProtectionElement, @"ProtectNotes");
  
  data.recycleBinEnabled = KPKXmlBool(metaElement, @"RecycleBinEnabled");
  data.recycleBinUuid = [NSUUID uuidWithEncodedString:KPKXmlString(metaElement, @"RecycleBinUUID")];
  data.recycleBinChanged = KPKXmlDate(_dateFormatter, metaElement, @"RecycleBinChanged");
  data.entryTemplatesGroup = [NSUUID uuidWithEncodedString:KPKXmlString(metaElement, @"EntryTemplatesGroup")];
  data.entryTemplatesGroupChanged = KPKXmlDate(_dateFormatter, metaElement, @"EntryTemplatesGroupChanged");
  data.historyMaxItems = KPKXmlInteger(metaElement, @"HistoryMaxItems");
  data.historyMaxSize = KPKXmlInteger(metaElement, @"HistoryMaxSize");
  data.lastSelectedGroup = [NSUUID uuidWithEncodedString:KPKXmlString(metaElement, @"LastSelectedGroup")];
  data.lastTopVisibleGroup = [NSUUID uuidWithEncodedString:KPKXmlString(metaElement, @"LastTopVisibleGroup")];
  
  [self _parseCustomIcons:metaElement meta:data];
  [self _parseBinaries:metaElement meta:data];
  [self _parseCustomData:metaElement meta:data];
}

- (KPKGroup *)_parseGroup:(DDXMLElement *)groupElement forTree:(KPKTree *)tree{
  KPKGroup *group = [[KPKGroup alloc] init];

  group.updateTiming = NO;
  group.tree = tree;
  
  group.uuid = [NSUUID uuidWithEncodedString:KPKXmlString(groupElement, @"UUID")];
  if (group.uuid == nil) {
    group.uuid = [NSUUID UUID];
  }
  
  group.name = KPKXmlString(groupElement, @"Name");
  group.notes = KPKXmlString(groupElement, @"Notes");
  group.icon = KPKXmlInteger(groupElement, @"IconID");
  
  DDXMLElement *customIconUuidElement = [groupElement elementForName:@"CustomIconUUID"];
  if (customIconUuidElement != nil) {
    NSUUID *iconUUID = [NSUUID uuidWithEncodedString:[customIconUuidElement stringValue]];
    group.customIcon = _iconMap[ iconUUID ];
  }
  
  DDXMLElement *timesElement = [groupElement elementForName:@"Times"];
  [self _parseTimes:group.timeInfo element:timesElement];
  
  group.isExpanded =  KPKXmlBool(groupElement, @"IsExpanded");
  
  group.defaultAutoTypeSequence = KPKXmlString(groupElement, @"DefaultAutoTypeSequence");
  
  group.isAutoTypeEnabled = parseInheritBool(groupElement, @"EnableAutoType");
  group.isSearchEnabled = parseInheritBool(groupElement, @"EnableSearching");
  group.lastTopVisibleEntry = [NSUUID uuidWithEncodedString:KPKXmlString(groupElement, @"LastTopVisibleEntry")];
  
  for (DDXMLElement *element in [groupElement elementsForName:@"Entry"]) {
    KPKEntry *entry = [self _parseEntry:element forTree:tree ignoreHistory:NO];
    entry.parent = group;
    [group addEntry:entry atIndex:[group.entries count]];
  }
  
  for (DDXMLElement *element in [groupElement elementsForName:@"Group"]) {
    KPKGroup *subGroup = [self _parseGroup:element forTree:tree];
    subGroup.parent = group;
    [group addGroup:subGroup atIndex:[group.groups count]];
  }
  
  group.updateTiming = YES;
  return group;
}

- (KPKEntry *)_parseEntry:(DDXMLElement *)entryElement forTree:(KPKTree *)tree ignoreHistory:(BOOL)ignoreHistory {
  KPKEntry *entry = [[KPKEntry alloc] init];
  
  entry.updateTiming = NO;
  entry.tree = tree;
  
  entry.uuid = [NSUUID uuidWithEncodedString:KPKXmlString(entryElement, @"UUID")];
  if (entry.uuid == nil) {
    entry.uuid = [NSUUID UUID];
  }
  
  entry.icon = KPKXmlInteger(entryElement, @"IconID");
  
  DDXMLElement *customIconUuidElement = [entryElement elementForName:@"CustomIconUUID"];
  if (customIconUuidElement != nil) {
    NSUUID *iconUUID = [NSUUID uuidWithEncodedString:[customIconUuidElement stringValue]];
    entry.customIcon = _iconMap[iconUUID];
  }
  
  entry.foregroundColor =  [NSColor colorWithHexString:KPKXmlString(entryElement, @"ForegroundColor")];
  entry.backgroundColor = [NSColor colorWithHexString:KPKXmlString(entryElement, @"BackgroundColor")];
  entry.overrideURL = KPKXmlString(entryElement, @"OverrideURL");
  entry.tags = KPKXmlString(entryElement, @"Tags");
  
  DDXMLElement *timesElement = [entryElement elementForName:@"Times"];
  [self _parseTimes:entry.timeInfo element:timesElement];
  
  for (DDXMLElement *element in [entryElement elementsForName:@"String"]) {
    DDXMLElement *valueElement = [element elementForName:@"Value"];
    BOOL isProtected = KPKXmlBoolAttribute(valueElement, @"Protected") || KPKXmlBoolAttribute(valueElement, @"ProtecteInMemory");
    KPKAttribute *attribute = [[KPKAttribute alloc] initWithKey:KPKXmlString(element, @"Key")
                                                          value:[valueElement stringValue]
                                                    isProtected:isProtected];
    
    if([attribute.key isEqualToString:KPKTitleKey]) {
      entry.title = attribute.value;
    }
    else if([attribute.key isEqualToString:KPKUsernameKey]) {
      entry.username = attribute.value;
    }
    else if([attribute.key isEqualToString:KPKPasswordKey]) {
      entry.password = attribute.value;
    }
    else if([attribute.key isEqualToString:KPKURLKey]) {
      entry.url = attribute.value;
    }
    else if([attribute.key isEqualToString:KPKNotesKey]) {
      entry.notes = attribute.value;
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
  timeInfo.lastModificationTime = KPKXmlDate(_dateFormatter, nodeElement, @"LastModificationTime");
  timeInfo.creationTime = KPKXmlDate(_dateFormatter, nodeElement, @"CreationTime");
  timeInfo.lastAccessTime = KPKXmlDate(_dateFormatter, nodeElement, @"LastAccessTime");
  timeInfo.expiryTime = KPKXmlDate(_dateFormatter, nodeElement, @"ExpiryTime");
  timeInfo.expires = KPKXmlBool(nodeElement, @"Expires");
  timeInfo.usageCount = KPKXmlInteger(nodeElement, @"UsageCount");
  timeInfo.locationChanged = KPKXmlDate(_dateFormatter, nodeElement, @"LocationChanged");
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
    NSUUID *uuid = [NSUUID uuidWithEncodedString:KPKXmlString(iconElement, @"UUID")];
    KPKIcon *icon = [[KPKIcon alloc] initWithUUID:uuid encodedString:KPKXmlString(iconElement, @"Data")];
    [metaData.customIcons addObject:icon];
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
  DDXMLElement *binariesElement = [root elementForName:@"Binaries"];
  NSUInteger binaryCount = [[binariesElement elementsForName:@"Binary"] count];
  _binaryMap = [[NSMutableDictionary alloc] initWithCapacity:binaryCount];
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
    DDXMLElement *valueElement = [binaryElement elementForName:@"Value"];
    DDXMLNode *refAttribute = [valueElement attributeForName:@"Ref"];
    NSUInteger index = [[refAttribute stringValue] integerValue];
    
    KPKBinary *binary = _binaryMap[ @(index) ];
    binary.name = KPKXmlString(binaryElement, @"Key");
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
    KPKBinary *customData = [[KPKBinary alloc] initWithName:KPKXmlString(dataElement, @"Key") value:KPKXmlString(dataElement, @"Value") compressed:NO];
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
  autotype.defaultSequence = KPKXmlString(autotypeElement, @"DefaultSequence");
  NSInteger obfuscate = KPKXmlInteger(autotypeElement, @"DataTransferObfuscation");
  autotype.obfuscateDataTransfer = obfuscate > 0;
  autotype.entry = entry;
  
  for(DDXMLElement *associationElement in [autotypeElement elementsForName:@"Association"]) {
    KPKWindowAssociation *association = [[KPKWindowAssociation alloc] initWithWindow:KPKXmlString(associationElement, @"Window")
                                                                   keystrokeSequence:KPKXmlString(associationElement, @"KeystrokeSequence")];
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
    NSUUID *uuid = [[NSUUID alloc] initWithEncodedUUIDString:KPKXmlString(deletedObject, @"UUID")];
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
