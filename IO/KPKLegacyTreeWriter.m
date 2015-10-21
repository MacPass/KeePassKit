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

#import "NSUUID+KeePassKit.h"

@interface KPKLegacyTreeWriter () {
  KPKDataStreamWriter *_dataWriter;
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
  }
  return self;
}

- (NSData *)treeData {
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
  _dataWriter = [KPKDataStreamWriter streamWriter];
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
  
  BOOL success = writeRootGroup ? [self _writeGroups:@[self.tree.root]] : [self _writeGroups:self.tree.root.groups];
  
  for(KPKEntry *entry in _allEntries) {
    success &= [self _writeEntry:entry];
  }
  for(KPKEntry *metaEntry in metaEntries){
    success &= [self _writeEntry:metaEntry];
  }
  return success ? [_dataWriter data] : nil;
}

#pragma mark Group/Entry Writing

- (BOOL)_writeGroups:(NSArray *)groups {
  /*
   The groups need to be written depth-first.
   Since allGroups goes broadth first, we have to iterate diffently
   */
  BOOL success = YES;
  for(KPKGroup *group in groups) {
    success &= [self _writeGroup:group];
    success &= [self _writeGroups:group.groups];
  }
  return success;
}

- (BOOL)_writeGroup:(KPKGroup *)group {
  uint32_t tmp32;
  uint32_t groupId = [self _groupIdForGroup:group];
  if(groupId == 0 ) {
    // Create error?
    return NO;
  }
  tmp32 = CFSwapInt32HostToLittle(groupId);
  [self _writeField:KPKFieldTypeGroupId bytes:&tmp32 length:4];
  
  if (![NSString isEmptyString:group.title]){
    const char *title = [group.title cStringUsingEncoding:NSUTF8StringEncoding];
    [self _writeField:KPKFieldTypeGroupName bytes:(void *)title length:strlen(title)+1];
  }
  
  /* Time Information */
  [self _writeTimeInfo:group];
  
  /* Icon */
  tmp32 = CFSwapInt32HostToLittle((uint32_t)group.iconId);
  [self _writeField:KPKFieldTypeGroupImage bytes:&tmp32 length:4];
  
  /*
   Determin the Group level
   since we might write the root group,
   that has no parent, we need to correct the level
   */
  uint16_t level = (group.parent != nil) ? -1 : 0;
  for(KPKGroup *parent = group.parent; parent != nil; parent = parent.parent) {
    level++;
  }
  
  level = CFSwapInt16HostToLittle(level);
  [self _writeField:KPKFieldTypeGroupLevel bytes:&level length:2];
  tmp32 = 0;
  [self _writeField:KPKFieldTypeGroupFlags bytes:&tmp32 length:4];
  
  /* Mark End of Group */
  [self _writeField:KPKFieldTypeCommonStop bytes:NULL length:0];

  return YES;
}

- (BOOL)_writeEntry:(KPKEntry *)entry {
  [self _writeField:KPKFieldTypeEntryUUID data:[entry.uuid uuidData]];
  
  /* Shift all entries in the root group inside the first group */
  uint32_t groupId = [self _groupIdForGroup:entry.parent];
  if([_tree.root.entries containsObject:entry]) {
    KPKGroup *firstGroup = _allGroups[0];
    groupId = [self _groupIdForGroup:firstGroup];
  }
  if(groupId == 0) {
    return NO; // Error
  }
  uint32_t tmp32;
  tmp32 = CFSwapInt32HostToLittle(groupId);
  [self _writeField:KPKFieldTypeEntryGroupId bytes:&tmp32 length:4];
  
  tmp32 = CFSwapInt32HostToLittle((uint32_t)entry.iconId);
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
  
  return YES;
}

#pragma mark Meta Entries

- (NSArray <KPKEntry *>*)_collectMetaEntries {
  /* Store metadata in entries */
  NSMutableArray<KPKEntry *> *metaEntries = [[NSMutableArray alloc] init];
  if(![NSString isEmptyString:self.tree.metaData.defaultUserName]) {
    NSData *defaultUsernameData = [self.tree.metaData.defaultUserName dataUsingEncoding:NSUTF8StringEncoding];
    KPKEntry *defaultUsernameEntry = [KPKEntry metaEntryWithData:defaultUsernameData name:KPKMetaEntryDefaultUsername];
    [metaEntries addObject:defaultUsernameEntry];
  }
  if(self.tree.metaData.color != nil) {
    KPKEntry *treeColorEntry = [KPKEntry metaEntryWithData:[self.tree.metaData.color colorData] name:KPKMetaEntryDatabaseColor];
    [metaEntries addObject:treeColorEntry];
  }
  if([self.tree.metaData.customIcons  count] > 0) {
    KPKEntry *customIconEntry = [KPKEntry metaEntryWithData:[self _customIconData] name:KPKMetaEntryKeePassXCustomIcon2];
    [metaEntries addObject:customIconEntry];
  }
  KPKEntry *uiStateEntry = [KPKEntry metaEntryWithData:[self _uiStateData] name:KPKMetaEntryUIState];
  [metaEntries addObject:uiStateEntry];
  KPKEntry *treeStateEntry = [KPKEntry metaEntryWithData:[self _kpxTreeStateData] name:KPKMetaEntryKeePassXGroupTreeState];
  [metaEntries addObject:treeStateEntry];
  
  for(KPKBinary *metaBinary in self.tree.metaData.unknownMetaEntryData) {
    KPKEntry *metaEntry = [KPKEntry metaEntryWithData:metaBinary.data name:metaBinary.name];
    [metaEntries addObject:metaEntry];
  }
  KPKGroup *firstGroup = _allGroups[0];
  NSAssert(firstGroup != nil, @"Cannot write tree without any groups");
  for(KPKEntry *entry in metaEntries) {
    entry.parent = firstGroup;
  }
  return metaEntries;
}

#pragma mark Metadata Helper

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
  NSMutableArray *_iconEntries = [[NSMutableArray alloc] initWithCapacity:MAX(1,[_allEntries count])];
  NSMutableArray *_iconGroups = [[NSMutableArray alloc] initWithCapacity:MAX(1,[_allGroups count])];
  for(KPKNode *node in _allEntries) {
    if(node.iconUUID) {
      [_iconEntries addObject:node];
    }
  }
  for(KPKNode *node in _allGroups) {
    if(node.iconUUID) {
      [_iconGroups addObject:node];
    }
  }
  
  NSArray *icons = self.tree.metaData.customIcons;
  NSMutableData *iconData = [[NSMutableData alloc] initWithCapacity:1024*1024];
  KPKDataStreamWriter *dataWriter = [[KPKDataStreamWriter alloc] initWithData:iconData];
  [dataWriter write4Bytes:(uint32_t)[icons count]];
  [dataWriter write4Bytes:(uint32)[_iconEntries count]];
  [dataWriter write4Bytes:(uint32)[_iconGroups count]];
  
  
  for(KPKIcon *icon in icons) {
    NSData *pngData = [icon pngData];
    [dataWriter write4Bytes:(uint32_t)[pngData length]];
    [dataWriter writeData:pngData];
  }
  
  for(KPKEntry *entry in _iconEntries) {
    KPKIcon *entryIcon = [self.tree.metaData findIcon:entry.iconUUID];
    if(entryIcon) {
      [dataWriter writeData:[entry.uuid uuidData]];
      NSInteger index = [icons indexOfObject:entryIcon];
      NSAssert(index != NSNotFound, @"Icon cannot be missing");
      [dataWriter write4Bytes:(uint32_t)index];
    }
  }
  
  for(KPKGroup *group in _iconGroups) {
    KPKIcon *groupIcon = [self.tree.metaData findIcon:group.iconUUID];
    if(groupIcon) {
      uint32_t groupId = [self _groupIdForGroup:group];
      NSAssert(groupId != 0, @"Group has to have Id != 0");
      [dataWriter write4Bytes:groupId];
      NSInteger index = [icons indexOfObject:groupIcon];
      NSAssert(index != NSNotFound, @"Icon cannot be missing");
      [dataWriter write4Bytes:(uint32_t)index];
    }
  }
  
  return iconData;
}

- (NSData *)_uiStateData {
  KPKSimpleUiState uiState;
  /*
   NSUInteger lastSelectedGroupId = [_groupIds indexOfObject:self.tree.metaData.lastSelectedGroup];
   NSUInteger lastTopVisibleGroupId = [_groupIds indexOfObject:self.tree.metaData.lastTopVisibleGroup];
   uiState.uLastSelectedGroupId = (lastSelectedGroupId == NSNotFound) ? 0 : (uint32_t)lastSelectedGroupId;
   uiState.uLastTopVisibleGroupId = (lastTopVisibleGroupId == NSNotFound) ? 0 : (uint32_t)lastTopVisibleGroupId;
   */
  uuid_t nullBytes = {0};
  memcpy(uiState.aLastSelectedEntryUuid, nullBytes, 16);
  memcpy(uiState.aLastTopVisibleEntryUuid, nullBytes, 16);
  uiState.dwReserved01 = 0;
  uiState.dwReserved02 = 0;
  uiState.dwReserved03 = 0;
  uiState.dwReserved04 = 0;
  uiState.dwReserved05 = 0;
  uiState.dwReserved06 = 0;
  uiState.dwReserved07 = 0;
  uiState.dwReserved08 = 0;
  uiState.dwReserved09 = 0;
  uiState.dwReserved10 = 0;
  uiState.dwReserved11 = 0;
  uiState.dwReserved12 = 0;
  uiState.dwReserved13 = 0;
  uiState.dwReserved14 = 0;
  uiState.dwReserved15 = 0;
  uiState.dwReserved16 = 0;
  
  return [NSData dataWithBytes:&uiState length:sizeof(uiState)];
}

- (NSData *)_kpxTreeStateData {
  /*
   struct KPXGroupState {
   uint32 groupId;
   BOOL isExpanded;
   };
   
   struct KPXTreeState {
   uint32 numerOfEntries;
   struct KPXGroupState states[];
   };
   */
  KPKDataStreamWriter *writer = [KPKDataStreamWriter streamWriter];
  [writer write4Bytes:(uint32_t)[_allGroups count]];
  for(KPKGroup *group in _allGroups) {
    uint32_t groupId = [self _groupIdForGroup:group];
    [writer write4Bytes:(uint32_t)groupId];
    [writer writeByte:group.isExpanded];
  }
  return  [writer data];
}

#pragma mark Header

- (void)_writeHeaderHash {
  /* Compute a sha256 hash of the header up to but not including the contentsHash */
  [self _writeField:KPKHeaderHashFieldTypeHeaderHash data:[_headerWriter headerHash]];
  
  /* Generate some random data to prevent guessing attacks that use the content hash */
  [self _writeField:KPKHeaderHashFieldTypeRandomData data:[NSData dataWithRandomBytes:32]];
  [self _writeField:KPKFieldTypeCommonStop bytes:NULL length:0];
}

#pragma mark Writing Helper

- (void)_writeString:(NSString *)string forField:(KPKLegacyFieldType)type {
  const char *bufferString = "";
  if (![NSString isEmptyString:string]) {
    bufferString = [string cStringUsingEncoding:NSUTF8StringEncoding];
  }
  [self _writeField:type bytes:bufferString length:strlen(bufferString) + 1];
}

- (void)_writeTimeInfo:(KPKNode *)node {
  BOOL isEntry = [node isKindOfClass:[KPKEntry class]];
  
  [self _writeField:(isEntry ? KPKFieldTypeEntryCreationTime : KPKFieldTypeGroupCreationTime )
               data:[NSDate packedBytesFromDate:node.timeInfo.creationDate]];
  
  [self _writeField:(isEntry ? KPKFieldTypeEntryModificationTime : KPKFieldTypeGroupModificationTime )
               data:[NSDate packedBytesFromDate:node.timeInfo.modificationDate]];
  
  [self _writeField:(isEntry ? KPKFieldTypeEntryAccessTime : KPKFieldTypeGroupAccessTime )
               data:[NSDate packedBytesFromDate:node.timeInfo.accessDate]];
  
  /*
   Keepass stores only the date. If the date is set, expire is true.
   If no date is set the entry does not expire
   */
  NSDate *expiryDate = node.timeInfo.expires ? node.timeInfo.expirationDate : nil;
  [self _writeField:(isEntry ? KPKFieldTypeEntryExpiryDate : KPKFieldTypeGroupExpiryDate )
               data:[NSDate packedBytesFromDate:expiryDate]];
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

/* Returns the group index for the searched group. 0 indicates an error */
- (uint32_t)_groupIdForGroup:(KPKGroup *)group {
  if(nil == group) {
    return 0;
  }
  NSUInteger groupId = [_allGroups indexOfObject:group];
  if(groupId == NSNotFound) {
    return 0;
  }
  NSAssert(groupId < UINT32_MAX, @"Group count should not exceed uint32");
  /* Shift the index up once, since Keepass doesn't like 0 as group Ids */
  return (uint32_t)(groupId + 1);
}

@end
