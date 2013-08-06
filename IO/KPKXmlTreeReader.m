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

#import "KPKFormat.h"
#import "KPKErrors.h"

#import "RandomStream.h"
#import "Arc4RandomStream.h"
#import "Salsa20RandomStream.h"

#import "NSMutableData+Base64.h"
#import "KPKIcon.h"

#import "DDXML.h"
#import "DDXMLElementAdditions.h"

#import "NSUUID+KeePassKit.h"
#import "NSColor+KeePassKit.h"

#define KPKYES(attribute) [[attribute stringValue] isEqualToString:@"True"]
#define KPKNO(attribute) [[attribute stringValue] isEqualToString:@"False"]
#define KPKString(element,name) [[element elementForName:name] stringValue]
#define KPKInteger(element,name) [[[element elementForName:name] stringValue] integerValue]
#define KPKBool(element,name) [[[element elementForName:name] stringValue] boolValue]
#define KPKDate(formatter,element,name) [formatter dateFromString:[[element elementForName:name] stringValue]]

@interface KPKXmlTreeReader () {
@private
  DDXMLDocument *_document;
  KPKXmlHeaderReader *_headerReader;
  RandomStream *_randomStream;
  NSDateFormatter *_dateFormatter;
  NSMutableDictionary *_binaryMap;
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
  DDXMLElement *meta = [rootElement elementForName:@"Meta"];
  if(!meta) {
    KPKCreateError(error, KPKErrorXMLMetaElementMissing, @"ERROR_META_ELEMENT_MISSING", "");
    return nil;
  }
  [self _parseMeta:meta metaData:tree.metaData];
  
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
  
  tree.root = [self _parseGroup:rootGroup];
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

- (void)_parseMeta:(DDXMLElement *)root metaData:(KPKMetaData *)data {
  
  data.generator = KPKString(root, @"Generator");
  data.databaseName = KPKString(root, @"DatabaseName");
  data.databaseNameChanged = KPKDate(_dateFormatter, root, @"DatabaseNameChanged");
  data.databaseDescription = KPKString(root, @"DatabaseDescription");
  data.databaseNameChanged = KPKDate(_dateFormatter, root, @"DatabaseDescriptionChanged");
  data.defaultUserName = KPKString(root, @"DefaultUserName");
  data.defaultUserNameChanged = KPKDate(_dateFormatter, root, @"DefaultUserNameChanged");
  data.maintenanceHistoryDays = KPKInteger(root, @"MaintenanceHistoryDays");
  /*
   Color is HTML Hex code!
   */
  
  data.color = [NSColor colorWithHexString:KPKString(root, @"Color")];
  data.masterKeyChanged = KPKDate(_dateFormatter, root, @"MasterKeyChanged");
  data.masterKeyChangeIsRequired = KPKInteger(root, @"MasterKeyChangeRec");
  data.masterKeyChangeIsForced = KPKInteger(root, @"MasterKeyChangeForce");
  
  DDXMLElement *memoryProtectionElement = [root elementForName:@"MemoryProtection"];
  
  data.protectTitle = KPKBool(memoryProtectionElement, @"ProtectTitle");
  data.protectUserName = KPKBool(memoryProtectionElement, @"ProtectUserName");
  data.protectUserName = KPKBool(memoryProtectionElement, @"ProtectPassword");
  data.protectUserName = KPKBool(memoryProtectionElement, @"ProtectURL");
  data.protectUserName = KPKBool(memoryProtectionElement, @"ProtectNotes");
  
  data.recycleBinEnabled = KPKBool(root, @"RecycleBinEnabled");
  data.recycleBinUuid = [NSUUID uuidWithEncodedString:KPKString(root, @"RecycleBinUUID")];
  data.recycleBinChanged = KPKDate(_dateFormatter, root, @"RecycleBinChanged");
  data.entryTemplatesGroup = [NSUUID uuidWithEncodedString:KPKString(root, @"EntryTemplatesGroup")];
  data.entryTemplatesGroupChanged = KPKDate(_dateFormatter, root, @"EntryTemplatesGroupChanged");
  data.historyMaxItems = KPKInteger(root, @"HistoryMaxItems");
  data.historyMaxSize = KPKInteger(root, @"HistoryMaxSize");
  data.lastSelectedGroup = [NSUUID uuidWithEncodedString:KPKString(root, @"LastSelectedGroup")];
  data.lastTopVisibleGroup = [NSUUID uuidWithEncodedString:KPKString(root, @"LastTopVisibleGroup")];
  
  [self _parseCustomIcons:root meta:data];
  [self _parseBinaries:root meta:data];
  [self _parseCustomData:root meta:data];
}

- (KPKGroup *)_parseGroup:(DDXMLElement *)groupElement {
  KPKGroup *group = [[KPKGroup alloc] init];
  
  group.updateTiming = NO;
  
  group.uuid = [NSUUID uuidWithEncodedString:KPKString(groupElement, @"UUID")];
  if (group.uuid == nil) {
    group.uuid = [NSUUID UUID];
  }
  
  group.name = KPKString(groupElement, @"Name");
  group.notes = KPKString(groupElement, @"Notes");
  group.icon = KPKInteger(groupElement, @"IconID");
  
  DDXMLElement *customIconUuidElement = [groupElement elementForName:@"CustomIconUUID"];
  if (customIconUuidElement != nil) {
    group.iconUUID = [NSUUID uuidWithEncodedString:[customIconUuidElement stringValue]];
  }
  
  DDXMLElement *timesElement = [groupElement elementForName:@"Times"];
  [self _parseTimes:group.timeInfo element:timesElement];
  
  group.isExpanded =  KPKBool(groupElement, @"IsExpanded");
  
  group.defaultAutoTypeSequence = KPKString(groupElement, @"DefaultAutoTypeSequence");
  
  NSString *enableAutoType = KPKString(groupElement, @"EnableAutoType");
  NSString *enableSearching = KPKString(groupElement, @"EnableSearching");
  
  group.isAutoTypeEnabled = (NSOrderedSame == [enableAutoType compare:@"null" options:NSCaseInsensitiveSearch]);
  group.isSearchEnabled = (NSOrderedSame == [enableSearching compare:@"null" options:NSCaseInsensitiveSearch]);
  group.lastTopVisibleEntry = [NSUUID uuidWithEncodedString:KPKString(groupElement, @"LastTopVisibleEntry")];
  
  for (DDXMLElement *element in [groupElement elementsForName:@"Entry"]) {
    KPKEntry *entry = [self _createEntry:element ignoreHistory:NO];
    entry.parent = group;
    [group addEntry:entry atIndex:[group.entries count]];
  }
  
  for (DDXMLElement *element in [groupElement elementsForName:@"Group"]) {
    KPKGroup *subGroup = [self _parseGroup:element];
    subGroup.parent = group;
    [group addGroup:subGroup atIndex:[group.groups count]];
  }
  
  group.updateTiming = YES;
  return group;
}

- (KPKEntry *)_createEntry:(DDXMLElement *)entryElement ignoreHistory:(BOOL)ignoreHistory {
  KPKEntry *entry = [[KPKEntry alloc] init];
  
  entry.updateTiming = NO;
  
  entry.uuid = [NSUUID uuidWithEncodedString:KPKString(entryElement, @"UUID")];
  if (entry.uuid == nil) {
    entry.uuid = [NSUUID UUID];
  }
  
  entry.icon = KPKInteger(entryElement, @"IconID");
  
  DDXMLElement *customIconUuidElement = [entryElement elementForName:@"CustomIconUUID"];
  if (customIconUuidElement != nil) {
    entry.iconUUID = [NSUUID uuidWithEncodedString:[customIconUuidElement stringValue]];
  }
  
  entry.foregroundColor =  [NSColor colorWithHexString:KPKString(entryElement, @"ForegroundColor")];
  entry.backgroundColor = [NSColor colorWithHexString:KPKString(entryElement, @"BackgroundColor")];
  entry.overrideURL = KPKString(entryElement, @"OverrideURL");
  entry.tags = KPKString(entryElement, @"Tags");
  
  DDXMLElement *timesElement = [entryElement elementForName:@"Times"];
  [self _parseTimes:entry.timeInfo element:timesElement];
  
  for (DDXMLElement *element in [entryElement elementsForName:@"String"]) {
    DDXMLElement *valueElement = [element elementForName:@"Value"];
    DDXMLNode *protectedAttribute = [valueElement attributeForName:@"Protected"];
    KPKAttribute *attribute = [[KPKAttribute alloc] initWithKey:KPKString(element, @"Key")
                                                          value:[valueElement stringValue]
                                                    isProtected:KPKYES(protectedAttribute)];
    
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
  timeInfo.lastModificationTime = KPKDate(_dateFormatter, nodeElement, @"LastModificationTime");
  timeInfo.creationTime = KPKDate(_dateFormatter, nodeElement, @"CreationTime");
  timeInfo.lastAccessTime = KPKDate(_dateFormatter, nodeElement, @"LastAccessTime");
  timeInfo.expiryTime = KPKDate(_dateFormatter, nodeElement, @"ExpiryTime");
  timeInfo.expires = KPKBool(nodeElement, @"Expires");
  timeInfo.usageCount = KPKInteger(nodeElement, @"UsageCount");
  timeInfo.locationChanged = KPKDate(_dateFormatter, nodeElement, @"LocationChanged");
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
  DDXMLElement *customIconsElement = [root elementForName:@"CustomIcons"];
  for (DDXMLElement *iconElement in [customIconsElement elementsForName:@"Icon"]) {
    NSUUID *uuid = [NSUUID uuidWithEncodedString:KPKString(iconElement, @"UUID")];
    KPKIcon *icon = [[KPKIcon alloc] initWithUUID:uuid encodedString:KPKString(iconElement, @"Data")];
    [metaData.customIcons addObject:icon];
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
  for (DDXMLElement *element in [binariesElement elementsForName:@"Binary"]) {
    DDXMLNode *idAttribute = [element attributeForName:@"ID"];
    DDXMLNode *compressedAttribute = [element attributeForName:@"Compressed"];
    
    KPKBinary *binary = [[KPKBinary alloc] initWithName:@"UNNAMED" value:[element stringValue] compressed:KPKYES(compressedAttribute)];
    NSUInteger index = [[idAttribute stringValue] integerValue];
    _binaryMap[ @(index) ] = binary;
  }
}

- (void)_parseEntryBinaries:(DDXMLElement *)entryElement entry:(KPKEntry *)entry {
  /*
   
   */
  
  for (DDXMLElement *binaryElement in [entryElement elementsForName:@"Binary"]) {
    DDXMLElement *valueElement = [binaryElement elementForName:@"Value"];
    DDXMLNode *refAttribute = [valueElement attributeForName:@"Ref"];
    NSUInteger index = [[refAttribute stringValue] integerValue];
    
    KPKBinary *binary = _binaryMap[ @(index) ];
    binary.name = KPKString(binaryElement, @"Key");
    [entry addBinary:binary];
  }
}

- (void)_parseCustomData:(DDXMLElement *)root meta:(KPKMetaData *)metaData {
  DDXMLElement *customDataElement = [root elementForName:@"CustomData"];
  for (DDXMLElement *dataElement in [customDataElement elementsForName:@"Item"]) {
    /*
     <CustomData>
     <Item>
     <Key></Key>
     <Value>-Base64EncodedValue-</Value>
     </Item>
     </CustomData>
     */
    KPKBinary *customData = [[KPKBinary alloc] initWithName:KPKString(dataElement, @"Key") value:KPKString(dataElement, @"Value") compressed:NO];
    [metaData.customData addObject:customData];
  }
}

- (void)_parseEntryAutotype:(DDXMLElement *)entryElement entry:(KPKEntry *)entry {
  //
  //  entry.autoType = [self parseAutoType:[root elementForName:@"AutoType"]];
  //
}

- (void)_parseHistory:(DDXMLElement *)entryElement entry:(KPKEntry *)entry {
  
  DDXMLElement *historyElement = [entryElement elementForName:@"History"];
  if (historyElement != nil) {
    for (DDXMLElement *entryElement in [historyElement elementsForName:@"Entry"]) {
      KPKEntry *historyEntry = [self _createEntry:entryElement ignoreHistory:YES];
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
    NSUUID *uuid = [[NSUUID alloc] initWithEncodedUUIDString:KPKString(deletedObject, @"UUID")];
    NSDate *date = KPKDate(_dateFormatter, deletedObject, @"DeletionTime");
    KPKDeletedNode *deletedNode = [[KPKDeletedNode alloc] initWithUUID:uuid date:date];
    tree.deletedObjects[ deletedNode.uuid ] = deletedNode;
  }
}

- (BOOL)_setupRandomStream {
  switch(_headerReader.randomStreamID ) {
    case KPKRandomStreamSalsa20:
      _randomStream = [[Salsa20RandomStream alloc] init:_headerReader.protectedStreamKey];
      return YES;
      
    case KPKRandomStreamArc4:
      _randomStream = [[Arc4RandomStream alloc] init:_headerReader.protectedStreamKey];
      return YES;
      
    default:
      return NO;
  }
}
@end
