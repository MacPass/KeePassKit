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
#import "KPKGroup.h"
#import "KPKNode.h"
#import "KPKEntry.h"
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

#define KPKYES(attribute) [[attribute stringValue] isEqualToString:@"True"]
#define KPKNO(attribute) [[attribute stringValue] isEqualToString:@"False"]
#define KPKString(element,name) [[element elementForName:name] stringValue]
#define KPKInteger(element,name) [[[element elementForName:name] stringValue] integerValue]
#define KPKBool(element,name) [[[element elementForName:name] stringValue] boolValue]
#define KPKDate(formatter,element,name) [formatter dateFromString:[[element elementForName:name] stringValue]]

@interface KPKXmlTreeReader () {
@private
  DDXMLDocument *_document;
  KPKXmlHeaderReader *_cipherInfo;
  RandomStream *_randomStream;
  NSDateFormatter *_dateFormatter;
}
@end

@implementation KPKXmlTreeReader

- (id)initWithData:(NSData *)data cipherInformation:(KPKXmlHeaderReader *)cipher {
  self = [super init];
  if(self) {
    _document = [[DDXMLDocument alloc] initWithData:data options:0 error:nil];
    _cipherInfo = cipher;
    if(![self _setupRandomStream]) {
      _document = nil;
      _cipherInfo = nil;
      self = nil;
      return nil;
    }
    _dateFormatter = [[NSDateFormatter alloc] init];
    _dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    _dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
    
  }
  return self;
}

- (KPKTree *)tree:(NSError *__autoreleasing *)error {
  if(!_document) {
    return nil;
  }
  
  DDXMLElement *rootElement = [_document rootElement];
  if(![[rootElement name] isEqualToString:@"KeePassFile"]) {
    KPKCreateError(error, KPKErrorXMLRootElementMissing, @"ERROR_KEEPASSFILE_ELEMENT_MISSING", "");
  }
  
  [self _decodeProtected:rootElement];
  
  KPKTree *tree = [[KPKTree alloc] init];
  /* Set the information we got from the header */
  tree.rounds = _cipherInfo.rounds;
  tree.compressionAlgorithm = _cipherInfo.compressionAlgorithm;
  /* Parse the rest of the metadata from the file */
  DDXMLElement *meta = [rootElement elementForName:@"Meta"];
  if (meta != nil) {
    [self _parseMeta:meta tree:tree];
  }
  
  DDXMLElement *root = [rootElement elementForName:@"Root"];
  if(!root) {
    KPKCreateError(error, KPKErrorXMLRootElementMissing, @"ERROR_ROOT_ELEMENT_MISSING", "");
    return nil;
  }

  DDXMLElement *element = [root elementForName:@"Group"];
  if(!element) {
    KPKCreateError(error, KPKErrorXMLGroupElementMissing, @"ERROR_GROUP_ELEMENT_MISSING", "");
    return nil;
  }

  tree.root = [self _parseGroup:element];
  
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

- (void)_parseMeta:(DDXMLElement *)root tree:(KPKTree *)tree {
  
  tree.generator = KPKString(root, @"Generator");
  tree.databaseName = KPKString(root, @"DatabaseName");
  tree.databaseNameChanged = KPKDate(_dateFormatter, root, @"DatabaseNameChanged");
  tree.databaseDescription = KPKString(root, @"DatabaseDescription");
  tree.databaseNameChanged = KPKDate(_dateFormatter, root, @"DatabaseDescriptionChanged");
  tree.defaultUserName = KPKString(root, @"DefaultUserName");
  tree.defaultUserNameChanged = KPKDate(_dateFormatter, root, @"DefaultUserNameChanged");
  tree.maintenanceHistoryDays = KPKInteger(root, @"MaintenanceHistoryDays");
  tree.color = KPKString(root, @"Color");
  tree.masterKeyChanged = KPKDate(_dateFormatter, root, @"MasterKeyChanged");
  tree.masterKeyChangeIsRequired = KPKInteger(root, @"MasterKeyChangeRec");
  tree.masterKeyChangeIsForced = KPKInteger(root, @"MasterKeyChangeForce");
  
  DDXMLElement *memoryProtectionElement = [root elementForName:@"MemoryProtection"];
  
  tree.protectTitle = KPKBool(memoryProtectionElement, @"ProtectTitle");
  tree.protectUserName = KPKBool(memoryProtectionElement, @"ProtectUserName");
  tree.protectUserName = KPKBool(memoryProtectionElement, @"ProtectPassword");
  tree.protectUserName = KPKBool(memoryProtectionElement, @"ProtectURL");
  tree.protectUserName = KPKBool(memoryProtectionElement, @"ProtectNotes");
  
  DDXMLElement *customIconsElement = [root elementForName:@"CustomIcons"];
  for (DDXMLElement *element in [customIconsElement elementsForName:@"Icon"]) {
    NSUUID *uuid = [NSUUID uuidWithEncodedString:KPKString(element, @"UUID")];
    KPKIcon *icon = [[KPKIcon alloc] initWithUUID:uuid encodedString:KPKString(root, @"Data")];
    [tree.customIcons addObject:icon];
  }
  
  tree.recycleBinEnabled = KPKBool(root, @"RecycleBinEnabled");
  tree.recycleBinUuid = [NSUUID uuidWithEncodedString:KPKString(root, @"RecycleBinUUID")];
  tree.recycleBinChanged = KPKDate(_dateFormatter, root, @"RecycleBinChanged");
  tree.entryTemplatesGroup = [NSUUID uuidWithEncodedString:KPKString(root, @"EntryTemplatesGroup")];
  tree.entryTemplatesGroupChanged = KPKDate(_dateFormatter, root, @"EntryTemplatesGroupChanged");
  tree.historyMaxItems = KPKInteger(root, @"HistoryMaxItems");
  tree.historyMaxSize = KPKInteger(root, @"HistoryMaxSize");
  tree.lastSelectedGroup = [NSUUID uuidWithEncodedString:KPKString(root, @"LastSelectedGroup")];
  tree.lastTopVisibleGroup = [NSUUID uuidWithEncodedString:KPKString(root, @"LastTopVisibleGroup")];
  
  /*
   Binaries need to be stored and then associated with entires
   */
  
//  DDXMLElement *binariesElement = [root elementForName:@"Binaries"];
//  for (DDXMLElement *element in [binariesElement elementsForName:@"Binary"]) {
//    [tree.binaries addObject:[self parseBinary:element]];
//  }
//  
//  DDXMLElement *customDataElement = [root elementForName:@"CustomData"];
//  for (DDXMLElement *element in [customDataElement elementsForName:@"Item"]) {
//    [tree.customData addObject:[self parseCustomItem:element]];
//  }
}

- (KPKGroup *)_parseGroup:(DDXMLElement *)groupNode {
  KPKGroup *group = [[KPKGroup alloc] init];
  
  group.uuid = [NSUUID uuidWithEncodedString:KPKString(groupNode, @"UUID")];
  if (group.uuid == nil) {
    group.uuid = [NSUUID UUID];
  }
  
  group.name = KPKString(groupNode, @"Name");
  group.notes = KPKString(groupNode, @"Notes");
  group.icon = KPKInteger(groupNode, @"IconID");
  
  
  DDXMLElement *timesElement = [groupNode elementForName:@"Times"];
  [self _parseTimes:group element:timesElement];
  
//  group.isExpanded = [[[root elementForName:@"IsExpanded"] stringValue] boolValue];
//  group.defaultAutoTypeSequence = [[root elementForName:@"DefaultAutoTypeSequence"] stringValue];
//  group.EnableAutoType = [[root elementForName:@"EnableAutoType"] stringValue];
//  group.EnableSearching = [[root elementForName:@"EnableSearching"] stringValue];
//  group.LastTopVisibleEntry = [self parseUuidString:[[root elementForName:@"LastTopVisibleEntry"] stringValue]];
  
  for (DDXMLElement *element in [groupNode elementsForName:@"Entry"]) {
    KPKEntry *entry = [self _parseEntry:element];
    entry.parent = group;
    [group addEntry:entry atIndex:[group.entries count]];
  }
  
  for (DDXMLElement *element in [groupNode elementsForName:@"Group"]) {
    KPKGroup *subGroup = [self _parseGroup:element];
    subGroup.parent = group;
    [group addGroup:subGroup atIndex:[group.groups count]];
  }
  
  return group;
}

- (KPKEntry *)_parseEntry:(DDXMLElement *)entryElement {
  KPKEntry *entry = [[KPKEntry alloc] init];
  
  entry.uuid = [NSUUID uuidWithEncodedString:KPKString(entryElement, @"UUID")];
  if (entry.uuid == nil) {
    entry.uuid = [NSUUID UUID];
  }
  
  entry.icon = KPKInteger(entryElement, @"IconID");
  
//  DDXMLElement *customIconUuidElement = [root elementForName:@"CustomIconUUID"];
//  if (customIconUuidElement != nil) {
//    entry.customIconUuid = [self parseUuidString:[customIconUuidElement stringValue]];
//  }
  
//  entry.foregroundColor = [[root elementForName:@"ForegroundColor"] stringValue];
//  entry.backgroundColor = [[root elementForName:@"BackgroundColor"] stringValue];
//  entry.overrideUrl = [[root elementForName:@"OverrideURL"] stringValue];
//  entry.tags = [[root elementForName:@"Tags"] stringValue];
  
  DDXMLElement *timesElement = [entryElement elementForName:@"Times"];
  [self _parseTimes:entry element:timesElement];
  
  for (DDXMLElement *element in [entryElement elementsForName:@"String"]) {
    KPKAttribute *attribute = [[KPKAttribute alloc] initWithKey:KPKString(element, @"Key")
                                                          value:KPKString(element, @"Value")
                                                    isProtected:KPKBool(element, @"Protected")];
    
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
      [entry.customAttributes addObject:attribute];
    }
  }
  
//  for (DDXMLElement *element in [root elementsForName:@"Binary"]) {
//    [entry.binaries addObject:[self parseBinaryRef:element]];
//  }
//  
//  entry.autoType = [self parseAutoType:[root elementForName:@"AutoType"]];
//  
//  DDXMLElement *historyElement = [root elementForName:@"History"];
//  if (historyElement != nil) {
//    for (DDXMLElement *element in [historyElement elementsForName:@"Entry"]) {
//      [entry.history addObject:[self parseEntry:element]];
//    }
//  }
  
  return entry;
}

- (void)_parseTimes:(KPKNode *)node element:(DDXMLElement *)nodeElement {
  node.lastModificationTime = KPKDate(_dateFormatter, nodeElement, @"LastModificationTime");
  node.creationTime = KPKDate(_dateFormatter, nodeElement, @"CreationTime");
  node.lastAccessTime = KPKDate(_dateFormatter, nodeElement, @"LastAccessTime");
  node.expiryTime = KPKDate(_dateFormatter, nodeElement, @"ExpiryTime");
  node.expires = KPKBool(nodeElement, @"Expires");
  node.usageCount = KPKInteger(nodeElement, @"UsageCount");
  node.locationChanged = KPKDate(_dateFormatter, nodeElement, @"LocationChanged");
}

- (BOOL)_setupRandomStream {
  switch(_cipherInfo.randomStreamID ) {
    case KPKRandomStreamSalsa20:
      _randomStream = [[Salsa20RandomStream alloc] init:_cipherInfo.protectedStreamKey];
      return YES;
      
    case KPKRandomStreamArc4:
      _randomStream = [[Arc4RandomStream alloc] init:_cipherInfo.protectedStreamKey];
      return YES;
      
    default:
      return NO;
  }
}
@end
