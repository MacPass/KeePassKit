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
  BOOL _firstGroup;
}

@end

@implementation KPKLegacyTreeWriter

- (id)initWithTree:(KPKTree *)tree headerWriter:(id<KPKHeaderWriting>)headerWriter {
  self = [super init];
  if(self) {
    _tree = tree;
    _firstGroup = YES;
    _groupIds = [[NSMutableArray alloc] initWithCapacity:[[tree allGroups] count]];
  }
  return self;
}

- (NSData *)treeData {
  NSMutableData *data = [[NSMutableData alloc] init];
  _dataWriter = [[KPKDataStreamWriter alloc] initWithData:data];
  
  /*
   The root Group doesn't get written out
   
   Keepass doesn't allow entries in the root group.
   Only Meta-Entries are inside the root group.
   If a Tree with entries in the root group is saved,
   those groups should be placed inside another group,
   or discarded.
   */
  for(KPKGroup *group in [_tree allGroups]) {
    [self _writeGroup:group];
  }
  
  for(KPKEntry *entry in [_tree allEntries]) {
    [self _writeEntry:entry];
  }
  // Metadata can be converted to entries
  [self _writeMetaData];
  
  return nil;
}

- (void)_writeGroup:(KPKGroup *)group {
  uint32_t tmp32;
  
  if(_firstGroup) {
    [_dataWriter write4Bytes:KPKFieldTypeCommonSize];
    [_dataWriter write4Bytes:88]; // Size of the hash information
    [self _writeHeaderHash];
    _firstGroup = NO;
  }
  [_groupIds addObject:group.uuid];
  tmp32 = CFSwapInt32HostToLittle((uint32_t)[_groupIds count] - 1);
  [self _writeField:KPKFieldTypeEntryGroupId bytes:&tmp32 length:4];
  
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
  uint32_t level = -1;
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

- (void)_writeMetaData {
  /*
   Store metadata in entries:
   
   1. default username
   2. tree state
   3. database color
   4. custom icons (KPX style)
   5. treestate (KPX style?)
   */
  if(![NSString isEmptyString:self.tree.metaData.defaultUserName]) {
    NSData *defaultUsernameData = [self.tree.metaData.defaultUserName dataUsingEncoding:NSUTF8StringEncoding];
    KPKEntry *defaultUsernameEntry = [KPKEntry metaEntryWithData:defaultUsernameData name:KPKMetaEntryDefaultUsername];
    [self.tree.metaData.unknownMetaEntries addObject:defaultUsernameEntry];
  }
  if(self.tree.metaData.color != nil) {
  }
  // Write metadata based on tree metadata.
  //[_tree.metaData.unknownMetaEntries];
}

- (void)_writeHeaderHash {
  
  /* Compute a sha256 hash of the header up to but not including the contentsHash */
  //
  NSData *headerHash;// = [Kdb3Utils hashHeader:&header];
  [self _writeField:KPKFieldTypeHeaderHash data:headerHash];
  
  /* Generate some random data to prevent guessing attacks that use the content hash */
  [self _writeField:KPKFieldTypeRandomData data:[NSData dataWithRandomBytes:32]];
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
  [_dataWriter write4Bytes:(uint32_t)type];
  [_dataWriter write4Bytes:(uint32_t)length];
  if(length > 0) {
    [_dataWriter writeBytes:bytes length:length];
  }
}

@end
