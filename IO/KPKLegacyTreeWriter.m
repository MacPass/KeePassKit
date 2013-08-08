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

#import "KPKDataStreamWriter.h"

#import "NSString+Empty.h"
#import "NSData+Random.h"
#import "NSDate+Packed.h"

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
  uint8_t packedDate[5];
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
  [group.timeInfo.creationTime packToBytes:packedDate];
  [self _writeField:KPKFieldTypeGroupCreationTime bytes:packedDate length:5];
  [group.timeInfo.lastModificationTime packToBytes:packedDate];
  [self _writeField:KPKFieldTypeGroupModificationTime bytes:packedDate length:5];
  [group.timeInfo.lastAccessTime packToBytes:packedDate];
  [self _writeField:KPKFieldTypeGroupAccessTime bytes:packedDate length:5];
  [group.timeInfo.expiryTime packToBytes:packedDate];
  [self _writeField:KPKFieldTypeGroupExpiryDate bytes:packedDate length:5];
  
  tmp32 = CFSwapInt32HostToLittle((uint32_t)group.icon);
  [self _writeField:KPKFieldTypeGroupImage bytes:&tmp32 length:4];
  /*
   // Get the level of the group
   uint16_t level = -1;
   for (KdbGroup *g = group; g.parent != nil; g = g.parent) {
   level++;
   }
   
   level = CFSwapInt16HostToLittle(level);
   [self appendField:8 size:2 bytes:&level withOutputStream:outputStream];
   
   Flags shoudl be zeroed out
   tmp32 = CFSwapInt32HostToLittle(group.flags);
   [self appendField:9 size:4 bytes:&tmp32 withOutputStream:outputStream];
   */
  // End of the group
  [self _writeField:KPKFieldTypeCommonStop bytes:NULL length:0];
}

- (void)_writeEntry:(KPKEntry *)entry {
  // TODO
}

- (void)_writeMetaData {
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
