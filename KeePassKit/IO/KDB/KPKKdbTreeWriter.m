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

#import "KPKKdbTreeWriter.h"
#import "KPKKdbFormat.h"

#import "KPKBinary.h"
#import "KPKDeletedNode.h"
#import "KPKEntry.h"
#import "KPKEntry_Private.h"
#import "KPKGroup.h"
#import "KPKGroup_Private.h"
#import "KPKIcon.h"
#import "KPKMetaData.h"
#import "KPKMetaData_Private.h"
#import "KPKNode_Private.h"
#import "KPKTimeInfo.h"
#import "KPKTree.h"
#import "KPKTree_Private.h"

#import "KPKDataStreamWriter.h"

#import "NSString+KPKEmpty.h"
#import "NSData+KPKRandom.h"
#import "NSDate+KPKAdditions.h"
#import "NSUIColor+KPKAdditions.h"
#import "NSUIImage+KPKAdditions.h"

#import "NSUUID+KPKAdditions.h"

@interface KPKKdbTreeWriter ()
@property (strong) KPKDataStreamWriter *dataWriter;
@property (copy) NSArray *entries;
@property (copy) NSArray *groups;

@property (strong) KPKTree *tree;

@property (nonatomic, readonly) BOOL writeRootGroup;

@end

@implementation KPKKdbTreeWriter

- (instancetype)initWithTree:(KPKTree *)tree {
  self = [super init];
  if(self) {
    _tree = tree;
    /*
     The root Group doesn't get written out
     
     Keepass doesn't allow entries in the root group.
     Only Meta-Entries are inside the root group.
     If a Tree with entries in the root group is saved,
     those groups should be placed inside another group.
     
     If no other groups are present, we use the root group,
     to prevent data loss!
     */
    
    _groups = self.writeRootGroup ? [@[self.tree.root] copy] : [self.tree.allGroups copy];
    /* collect meta entries after groups are initalized */
    NSArray *metaEntries = [self _collectMetaEntries];
    _entries = [[self.tree.allEntries arrayByAddingObjectsFromArray:metaEntries] copy];
  }
  return self;
}

- (NSUInteger)numberOfGroups {
  return self.groups.count;
}

- (NSUInteger)numberOfEntries {
  return self.entries.count;
}

- (NSData *)treeDataWithHeaderHash:(NSData *)hash {
  /* Having calculated all entries, we can now write the header hash */
  self.dataWriter = [KPKDataStreamWriter streamWriter];
  [self _writeHeaderHash:hash];
  
  BOOL success = self.writeRootGroup ? [self _writeGroups:@[self.tree.root]] : [self _writeGroups:self.tree.root.groups];
  
  for(KPKEntry *entry in self.entries) {
    success &= [self _writeEntry:entry];
  }
  return success ? [self.dataWriter data] : nil;
}

- (BOOL)writeRootGroup {
  NSAssert(self.tree, @"Tree cannot be nil!");
  return ((self.tree.root.mutableEntries.count > 0) && (self.tree.root.mutableGroups.count == 0));
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
    success &= [self _writeGroups:group.mutableGroups];
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
  
  if (group.title.kpk_isNotEmpty){
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
  [self _writeField:KPKFieldTypeEntryUUID data:entry.uuid.kpk_uuidData];
  
  /* Shift all entries in the root group inside the first group */
  uint32_t groupId = [self _groupIdForGroup:entry.parent];
  if([self.tree.root.mutableEntries containsObject:entry]) {
    groupId = [self _groupIdForGroup:self.groups.firstObject];
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
  KPKBinary *firstBinary = entry.mutableBinaries.lastObject;
  [self _writeString:firstBinary.name forField:KPKFieldTypeEntryBinaryDescription];
  if(firstBinary && firstBinary.data.length > 0) {
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
  if(self.tree.metaData.defaultUserName.kpk_isNotEmpty) {
    NSData *defaultUsernameData = [self.tree.metaData.defaultUserName dataUsingEncoding:NSUTF8StringEncoding];
    KPKEntry *defaultUsernameEntry = [KPKEntry metaEntryWithData:defaultUsernameData name:KPKMetaEntryDefaultUsername];
    [metaEntries addObject:defaultUsernameEntry];
  }
  if(self.tree.metaData.databaseName.kpk_isNotEmpty) {
    NSData *databaseNameData = [self.tree.metaData.databaseName dataUsingEncoding:NSUTF8StringEncoding];
    KPKEntry *databaseNameEntry = [KPKEntry metaEntryWithData:databaseNameData name:KPKMetaEntryKeePassKitDatabaseName];
    [metaEntries addObject:databaseNameEntry];
  }
  if(self.tree.metaData.databaseDescription.kpk_isNotEmpty) {
    NSData *databaseDescriptionData = [self.tree.metaData.databaseDescription dataUsingEncoding:NSUTF8StringEncoding];
    KPKEntry *databaseDescriptionEntry = [KPKEntry metaEntryWithData:databaseDescriptionData name:KPKMetaEntryKeePassKitDatabaseDescription];
    [metaEntries addObject:databaseDescriptionEntry];
  }
  if(self.tree.metaData.color != nil) {
    KPKEntry *treeColorEntry = [KPKEntry metaEntryWithData:self.tree.metaData.color.kpk_colorData name:KPKMetaEntryDatabaseColor];
    [metaEntries addObject:treeColorEntry];
  }
  if((self.tree.metaData.mutableCustomIcons).count > 0) {
    KPKEntry *customIconEntry = [KPKEntry metaEntryWithData:[self _customIconData] name:KPKMetaEntryKeePassXCustomIcon2];
    [metaEntries addObject:customIconEntry];
  }
  KPKEntry *uiStateEntry = [KPKEntry metaEntryWithData:[self _uiStateData] name:KPKMetaEntryUIState];
  [metaEntries addObject:uiStateEntry];
  KPKEntry *treeStateEntry = [KPKEntry metaEntryWithData:[self _kpxTreeStateData] name:KPKMetaEntryKeePassXGroupTreeState];
  [metaEntries addObject:treeStateEntry];
  
  KPKEntry *trashEntry = [KPKEntry metaEntryWithData:[self _trashData] name:KPKMetaEntryKeePassKitTrash];
  [metaEntries addObject:trashEntry];
  
  // TODO: Add Group UUIDs and DeletedObjects
  
  
  for(KPKBinary *metaBinary in self.tree.metaData.mutableUnknownMetaEntryData) {
    KPKEntry *metaEntry = [KPKEntry metaEntryWithData:metaBinary.data name:metaBinary.name];
    [metaEntries addObject:metaEntry];
  }
  KPKGroup *firstGroup = self.groups.firstObject;
  NSAssert(firstGroup != nil, @"Cannot write tree without any groups");
  for(KPKEntry *entry in metaEntries) {
    entry.parent = firstGroup;
  }
  return metaEntries;
}

#pragma mark Metadata Helper

- (NSData *)_customIconData {
  /* Theoretica structure
   
   struct KPXCustomIconData {
   uint32_t dataSize;
   uint8_t data[dataSize];
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
   struct KPXCustomIconData data[iconCount];
   struct KPXEntryIconInfo entryIcon[entryCount];
   struct KPXGroupIconInfo groupIcon[groupCount];
   };
   */
  NSArray <KPKEntry *> *entries = self.tree.allEntries;
  NSMutableArray *_iconEntries = [[NSMutableArray alloc] initWithCapacity:MAX(1,entries.count)];
  NSMutableArray *_iconGroups = [[NSMutableArray alloc] initWithCapacity:MAX(1,self.groups.count)];
  for(KPKNode *node in entries) {
    if(node.iconUUID) {
      [_iconEntries addObject:node];
    }
  }
  for(KPKNode *node in self.groups) {
    if(node.iconUUID) {
      [_iconGroups addObject:node];
    }
  }
  
  NSArray *icons = self.tree.metaData.mutableCustomIcons;
  NSMutableData *iconData = [[NSMutableData alloc] initWithCapacity:1024*1024];
  KPKDataStreamWriter *dataWriter = [[KPKDataStreamWriter alloc] initWithData:iconData];
  [dataWriter write4Bytes:CFSwapInt32HostToLittle((uint32_t)icons.count)];
  [dataWriter write4Bytes:CFSwapInt32HostToLittle((uint32_t)_iconEntries.count)];
  [dataWriter write4Bytes:CFSwapInt32HostToLittle((uint32_t)_iconGroups.count)];
  
  
  for(KPKIcon *icon in icons) {
    NSData *pngData = icon.image.kpk_pngData;
    if(pngData) {
      [dataWriter write4Bytes:CFSwapInt32HostToLittle((uint32_t)pngData.length)];
      [dataWriter writeData:pngData];
    }
  }
  
  for(KPKEntry *entry in _iconEntries) {
    KPKIcon *entryIcon = [self.tree.metaData findIcon:entry.iconUUID];
    if(entryIcon) {
      [dataWriter writeData:entry.uuid.kpk_uuidData];
      NSInteger index = [icons indexOfObjectIdenticalTo:entryIcon];
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
      NSInteger index = [icons indexOfObjectIdenticalTo:groupIcon];
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
   struct KPXGroupState states[numberOfEntries];
   };
   */
  KPKDataStreamWriter *writer = [KPKDataStreamWriter streamWriter];
  [writer write4Bytes:(uint32_t)self.groups.count];
  for(KPKGroup *group in self.groups) {
    uint32_t groupId = [self _groupIdForGroup:group];
    [writer write4Bytes:CFSwapInt32HostToLittle((uint32_t)groupId)];
    [writer writeByte:group.isExpanded];
  }
  return  writer.data;
}

- (NSData *)_groupUUIDsData {
  /*
   struct KPKGroupUUIDs {
    uint32_t numberOfUUIDs;
    uuid_t UUID;
  };
  */
  KPKDataStreamWriter *writer = [KPKDataStreamWriter streamWriter];
  [writer write4Bytes:CFSwapInt32HostToLittle((uint32_t)self.groups.count)];
  for(KPKGroup *group in self.groups) {
    [writer writeData:group.uuid.kpk_uuidData];
  }
  return writer.data;
}

- (NSData *)_deltedObjectsData {
  /*
  struct KPKDeletedObject {
    uuid_t UUID;
    uint8_t date[5];
  }
  
  struct KPKDeletedObjects {
    uint32_t count;
    struct KPKDeletedObject objects[count];
  };
  */
  NSAssert(self.tree.mutableDeletedObjects.count < UINT32_MAX, @"Unable to store deleted objects. Exceeding maxium capacity of deleted objects");
  if(self.tree.mutableDeletedObjects.count >= UINT32_MAX) {
    return nil;
  }
  
  KPKDataStreamWriter *writer = [KPKDataStreamWriter streamWriter];
  [writer write4Bytes:CFSwapInt32HostToLittle((uint32_t)self.tree.mutableDeletedObjects.count)];
  for(KPKDeletedNode *node in self.tree.mutableDeletedObjects) {
    [writer writeData:node.uuid.kpk_uuidData];
    [writer writeData:node.deletionDate.kpk_packedBytes];
  }
  return writer.data;
}

- (NSData *)_trashData {
  /*
   struct {
    BOOL useTrash
    uint32_t trashGroupId
   } KPKTrashData;
   */
  KPKDataStreamWriter *writer = [KPKDataStreamWriter streamWriter];
  [writer writeByte:self.tree.metaData.useTrash];
  KPKGroup *trash = [self.tree.root groupForUUID:self.tree.metaData.trashUuid];
  uint32_t groupId = [self _groupIdForGroup:trash];
  [writer write4Bytes:CFSwapInt32HostToLittle(groupId)];
  return writer.data;
}

#pragma mark Header

- (void)_writeHeaderHash:(NSData *)hash {
  [self.dataWriter write2Bytes:KPKFieldTypeCommonHash];
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
  [self.dataWriter write4Bytes:CFSwapInt32HostToLittle(82)];
  /* Compute a sha256 hash of the header up to but not including the contentsHash */
  [self _writeField:KPKHeaderHashFieldTypeHeaderHash data:hash];
  
  /* Generate some random data to prevent guessing attacks that use the content hash */
  [self _writeField:KPKHeaderHashFieldTypeRandomData data:[NSData kpk_dataWithRandomBytes:32]];
  [self _writeField:KPKFieldTypeCommonStop bytes:NULL length:0];
}

#pragma mark Writing Helper

- (void)_writeString:(NSString *)string forField:(KPKLegacyFieldType)type {
  const char *bufferString = "";
  if(string.kpk_isNotEmpty) {
    bufferString = [string cStringUsingEncoding:NSUTF8StringEncoding];
  }
  [self _writeField:type bytes:bufferString length:strlen(bufferString) + 1];
}

- (void)_writeTimeInfo:(KPKNode *)node {
  BOOL isEntry = (nil != node.asEntry);
  
  [self _writeField:(isEntry ? KPKFieldTypeEntryCreationTime : KPKFieldTypeGroupCreationTime )
               data:[NSDate kpk_packedBytesFromDate:node.timeInfo.creationDate]];
  
  [self _writeField:(isEntry ? KPKFieldTypeEntryModificationTime : KPKFieldTypeGroupModificationTime )
               data:[NSDate kpk_packedBytesFromDate:node.timeInfo.modificationDate]];
  
  [self _writeField:(isEntry ? KPKFieldTypeEntryAccessTime : KPKFieldTypeGroupAccessTime )
               data:[NSDate kpk_packedBytesFromDate:node.timeInfo.accessDate]];
  
  /*
   Keepass stores only the date. If the date is set, expire is true.
   If no date is set the entry does not expire
   */
  NSDate *expiryDate = node.timeInfo.expires ? node.timeInfo.expirationDate : nil;
  [self _writeField:(isEntry ? KPKFieldTypeEntryExpiryDate : KPKFieldTypeGroupExpiryDate )
               data:[NSDate kpk_packedBytesFromDate:expiryDate]];
}


- (void)_writeField:(KPKLegacyFieldType)type data:(NSData *)data {
  [self _writeField:type bytes:data.bytes length:data.length];
}

- (void)_writeField:(KPKLegacyFieldType)type bytes:(const void *)bytes length:(NSUInteger)length {
  [self.dataWriter write2Bytes:CFSwapInt16HostToLittle((uint16_t)type)];
  [self.dataWriter write4Bytes:CFSwapInt32HostToLittle((uint32_t)length)];
  if(length > 0) {
    [self.dataWriter writeBytes:bytes length:length];
  }
}

/* Returns the group index for the searched group. 0 indicates an error */
- (uint32_t)_groupIdForGroup:(KPKGroup *)group {
  if(nil == group) {
    return 0;
  }
  NSUInteger groupId = [self.groups indexOfObjectIdenticalTo:group];
  if(groupId == NSNotFound) {
    return 0;
  }
  NSAssert(groupId < UINT32_MAX, @"Group count should not exceed uint32");
  /* Shift the index up once, since Keepass doesn't like 0 as group Ids */
  return (uint32_t)(groupId + 1);
}

@end
