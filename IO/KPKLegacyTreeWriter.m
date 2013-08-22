//
//  KPKBinaryTreeWriter.m
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

#import "KPKLegacyTreeWriter.h"
#import "KPKLegacyFormat.h"
#import "KPKLegacyHeaderWriter.h"
#import "KPKTree.h"
#import "KPKTimeInfo.h"
#import "KPKMetaData.h"
#import "KPKGroup.h"
#import "KPKEntry.h"
#import "KPKBinary.h"

#import "KPKDataStreamWriter.h"

#import "NSString+Empty.h"
#import "NSData+Random.h"
#import "NSDate+Packed.h"
#import "NSColor+KeePassKit.h"

@interface KPKLegacyTreeWriter () {
  KPKDataStreamWriter *_dataWriter;
  NSMutableArray *_groupIds;
  NSArray *_allEntries;
  NSArray *_allGroups;
}

@property (nonatomic, strong, readwrite) KPKLegacyHeaderWriter *headerWriter;

@end

@implementation KPKLegacyTreeWriter

- (instancetype)initWithTree:(KPKTree *)tree {
  self = [super init];
  if(self) {
    _tree = tree;
    _headerWriter = [[KPKLegacyHeaderWriter alloc] initWithTree:_tree];
    _groupIds = [[NSMutableArray alloc] initWithCapacity:[[tree allGroups] count]];
  }
  return self;
}

- (NSData *)treeData {
  NSMutableData *data = [[NSMutableData alloc] init];
  /*
   The root Group doesn't get written out
   
   Keepass doesn't allow entries in the root group.
   Only Meta-Entries are inside the root group.
   If a Tree with entries in the root group is saved,
   those groups should be placed inside another group,
   or discarded.
   */
  _allEntries = [_tree allEntries];
  BOOL writeRootGroup = ([_tree.root.entries count] > 0 && [_tree.root.groups count] == 0);
  _allGroups = writeRootGroup ? @[_tree.root] : [_tree allGroups];
  
  
  NSArray *metaEntries = [self _collectMetaEntries];
  self.headerWriter.groupCount = [_allGroups count];
  self.headerWriter.entryCount =  [_allEntries count] + [metaEntries count];
  
  /* Having calculated all entries, we can now write the header hash */
  _dataWriter = [[KPKDataStreamWriter alloc] initWithData:data];
  [_dataWriter write2Bytes:KPKFieldTypeCommonHash];
  /*
   2 byte hash field type
   4 byte hash field lenght
   32 byte hash
   2 byte random filed type
   4 byte random field length
   32 byte random data
   2 byte stop field type
   4 byte stop field length (0)
   */
  [_dataWriter write4Bytes:82];
  [self _writeHeaderHash];
  
  if(writeRootGroup) {
    [self _writeGroups:@[self.tree.root]];
  }
  else {
    [self _writeGroups:self.tree.root.groups];
  }
  
  for(KPKEntry *entry in _allEntries) {
    [self _writeEntry:entry];
  }
  for(KPKEntry *metaEntry in metaEntries){
    [self _writeEntry:metaEntry];
  }
  
  return [data copy];
}

- (void)_writeGroups:(NSArray *)groups {
  /*
   The groups need to be written depth-first.
   Since allGroups goes broadth first, we have to iterate diffently
   */
  for(KPKGroup *group in groups) {
    [self _writeGroup:group];
    [self _writeGroups:group.groups];
  }
}

- (void)_writeGroup:(KPKGroup *)group {
  uint32_t tmp32;
  [_groupIds addObject:group.uuid];
  tmp32 = CFSwapInt32HostToLittle((uint32_t)[_groupIds count] - 1);
  [self _writeField:KPKFieldTypeGroupId bytes:&tmp32 length:4];
  
  if (![NSString isEmptyString:group.name]){
    const char *title = [group.name cStringUsingEncoding:NSUTF8StringEncoding];
    [self _writeField:KPKFieldTypeGroupName bytes:(void *)title length:strlen(title)+1];
  }
  
  /* Time Information */
  [self _writeTimeInfo:group];
  
  /* Icon */
  tmp32 = CFSwapInt32HostToLittle((uint32_t)group.icon);
  [self _writeField:KPKFieldTypeGroupImage bytes:&tmp32 length:4];
  
  /* Determin the Group level */
  uint32_t level = 0;
  for(KPKGroup *parent = group.parent; parent != nil; parent = parent.parent) {
    level++;
  }
  level = CFSwapInt32HostToLittle(level);
  [self _writeField:KPKFieldTypeGroupLevel bytes:&level length:4];
  tmp32 = 0;
  [self _writeField:KPKFieldTypeGroupFlags bytes:&tmp32 length:4];
  
  /* Mark End of Group */
  [self _writeField:KPKFieldTypeCommonStop bytes:NULL length:0];
}

- (void)_writeEntry:(KPKEntry *)entry {
  uint8_t dateBuffer[16];
  uint32_t tmp32;
  
  [entry.uuid getUUIDBytes:dateBuffer];
  [self _writeField:KPKFieldTypeEntryUUID bytes:dateBuffer length:16];
  
  NSUInteger groupId = [_groupIds indexOfObject:entry.parent.uuid];
  /* Shift all entries in the root group inside the first group */
  if([_tree.root.entries containsObject:entry]) {
    KPKGroup *firstGroup = _allGroups[0];
    groupId = [_groupIds indexOfObject:firstGroup.uuid];
  }
  if(groupId == NSNotFound) {
    /* TODO: Error since we are missing the group id */
    return;
  }
  tmp32 = CFSwapInt32HostToLittle((uint32_t)groupId);
  [self _writeField:KPKFieldTypeEntryGroupId bytes:&tmp32 length:4];
  
  tmp32 = CFSwapInt32HostToLittle((uint32_t)entry.icon);
  [self _writeField:KPKFieldTypeEntryImage bytes:&tmp32 length:4];
  
  
  [self _writeString:entry.title forField:KPKFieldTypeEntryTitle];
  [self _writeString:entry.url forField:KPKFieldTypeEntryURL];
  [self _writeString:entry.username forField:KPKFieldTypeEntryUsername];
  [self _writeString:entry.password forField:KPKFieldTypeEntryPassword];
  [self _writeString:entry.notes forField:KPKFieldTypeEntryNotes];
  
  [self _writeTimeInfo:entry];
  
  /* We only save the last binary if there is more than one */
  KPKBinary *firstBinary = [entry.binaries lastObject];
  [self _writeString:firstBinary.name forField:KPKFieldTypeEntryBinaryDescription];
  if(firstBinary && [firstBinary.data length] > 0) {
    [self _writeField:KPKFieldTypeEntryBinaryData data:firstBinary.data];
  }
  else {
    [self _writeField:KPKFieldTypeEntryBinaryData bytes:NULL length:0];
  }
  /* Mark end of Entries */
  [self _writeField:KPKFieldTypeCommonStop bytes:NULL length:0];
  
}

- (NSArray *)_collectMetaEntries {
  /*
   Store metadata in entries:
   
   - tree state
   - treestate (KPX style?)
   */
  NSMutableArray *metaEntries = [[NSMutableArray alloc] init];
  if(![NSString isEmptyString:self.tree.metaData.defaultUserName]) {
    NSData *defaultUsernameData = [self.tree.metaData.defaultUserName dataUsingEncoding:NSUTF8StringEncoding];
    KPKEntry *defaultUsernameEntry = [KPKEntry metaEntryWithData:defaultUsernameData name:KPKMetaEntryDefaultUsername];
    [metaEntries addObject:defaultUsernameEntry];
  }
  if(self.tree.metaData.color != nil) {
    KPKEntry *treeColorEntry = [KPKEntry metaEntryWithData:[self.tree.metaData.copy colorData] name:KPKMetaEntryDatabaseColor];
    [metaEntries addObject:treeColorEntry];
  }
  if([self.tree.metaData.customIcons  count] > 0) {
    KPKEntry *customIconEntry = [KPKEntry metaEntryWithData:[self _customIconData] name:KPKMetaEntryKeePassXCustomIcon2];
    [metaEntries addObject:customIconEntry];
  }
  for(KPKBinary *metaBinary in self.tree.metaData.unknownMetaEntryData) {
    KPKEntry *metaEntry = [KPKEntry metaEntryWithData:metaBinary.data name:metaBinary.name];
    [metaEntries addObject:metaEntry];
  }
  KPKGroup *firstGroup = _allGroups[0];
  NSAssert(firstGroup != nil, @"Cannot write tree without any groups");
  [metaEntries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    KPKEntry *entry = obj;
    entry.parent = firstGroup;
  }];
  return metaEntries;
}

- (NSData *)_customIconData {
  /* Theoretica structures, variabel data sizes are mapped to fixed arrays with size 1
   
   struct KPXCustomIconData {
   uint32_t dataSize;
   uint8_t data[1];
   };
   
   struct KPXEntryIconInfo {
   uint8_t  uuidBytes[16];
   uint32_t iconId;
   };
   
   struct KPXGroupIconInfo {
   uint32_t groupId;
   uint32_t icondId;
   };
   
   struct KPXCustomIcons {
   uint32_t iconCount;
   uint32_t entryCount;
   uint32_t groupCount;
   struct KPXCustomIconData data[1]; // 1 -> iconCount
   struct KPXEntryIconInfo entryIcon[1]; // 1 -> entryCount
   struct KPXGroupIconInfo groupIcon[1]; // 1 -> groupCount
   };
   */
  NSMutableArray *_iconEntries = [[NSMutableArray alloc] initWithCapacity:[_allEntries count]];
  NSMutableArray *_groupEntries = [[NSMutableArray alloc] initWithCapacity:[_allGroups count]];
  [_allEntries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    KPKNode *node = obj;
    if(node.customIcon) {
      [_iconEntries addObject:node];
    }
  }];
  [_allGroups enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    KPKNode *node = obj;
    if(node.customIcon) {
      [_groupEntries addObject:node];
    }
  }];
  
  NSArray *icons = self.tree.metaData.customIcons;
  NSMutableData *iconData = [[NSMutableData alloc] initWithCapacity:1024*1024];
  KPKDataStreamWriter *dataWriter = [[KPKDataStreamWriter alloc] initWithData:iconData];
  [dataWriter write4Bytes:(uint32_t)[icons count]];
  [dataWriter write4Bytes:(uint32)[_iconEntries count]];
  [dataWriter write4Bytes:(uint32)[_groupEntries count]];
  
  
  for(KPKIcon *icon in icons) {
    NSData *pngData = [icon pngData];
    [dataWriter write4Bytes:(uint32_t)[pngData length]];
    [dataWriter writeData:pngData];
  }
  
  for(KPKEntry *entryNode in _allEntries) {
    
  }
  
  return iconData;
}

- (void)_writeHeaderHash {
  /* Compute a sha256 hash of the header up to but not including the contentsHash */
  [self _writeField:KPKHeaderHashFieldTypeHeaderHash data:[_headerWriter headerHash]];
  
  /* Generate some random data to prevent guessing attacks that use the content hash */
  [self _writeField:KPKHeaderHashFieldTypeRandomData data:[NSData dataWithRandomBytes:32]];
  [self _writeField:KPKFieldTypeCommonStop bytes:NULL length:0];
}

- (void)_writeString:(NSString *)string forField:(KPKLegacyFieldType)type {
  const char *bufferString = "";
  if (![NSString isEmptyString:string]) {
    bufferString = [string cStringUsingEncoding:NSUTF8StringEncoding];
  }
  [self _writeField:type bytes:bufferString length:strlen(bufferString) + 1];
}

- (void)_writeTimeInfo:(KPKNode *)node {
  BOOL isEntry = [node isKindOfClass:[KPKEntry class]];
  uint8_t dateBuffer[5];
  
  [node.timeInfo.creationTime packToBytes:dateBuffer];
  [self _writeField:(isEntry ? KPKFieldTypeEntryCreationTime : KPKFieldTypeGroupCreationTime )
              bytes:dateBuffer
             length:5];
  
  [node.timeInfo.lastModificationTime packToBytes:dateBuffer];
  [self _writeField:(isEntry ? KPKFieldTypeEntryModificationTime : KPKFieldTypeGroupModificationTime )
              bytes:dateBuffer
             length:5];
  
  [node.timeInfo.lastAccessTime packToBytes:dateBuffer];
  [self _writeField:(isEntry ? KPKFieldTypeEntryAccessTime : KPKFieldTypeGroupAccessTime )
              bytes:dateBuffer
             length:5];
  
  [node.timeInfo.expiryTime packToBytes:dateBuffer];
  [self _writeField:(isEntry ? KPKFieldTypeEntryExpiryDate : KPKFieldTypeGroupExpiryDate )
              bytes:dateBuffer
             length:5];
}


- (void)_writeField:(KPKLegacyFieldType)type data:(NSData *)data {
  [self _writeField:type bytes:data.bytes length:[data length]];
}

- (void)_writeField:(KPKLegacyFieldType)type bytes:(const void *)bytes length:(NSUInteger)length {
  [_dataWriter write2Bytes:(uint16_t)type];
  [_dataWriter write4Bytes:(uint32_t)length];
  if(length > 0) {
    [_dataWriter writeBytes:bytes length:length];
  }
}

@end
