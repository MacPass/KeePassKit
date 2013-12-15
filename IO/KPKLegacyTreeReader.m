//
//  KPKBinaryTreeReader.m
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
//  Reading of KeepassX Metadata is extracted from KeepassX sources
//  Licensed under GPLv2 Copyright (C) 2012 Felix Geyer <debfx@fobos.de>
//

#import "KPKLegacyTreeReader.h"
#import "KPKLegacyFormat.h"
#import "KPKLegacyHeaderReader.h"
#import "KPKDataStreamReader.h"

#import "KPKTree.h"
#import "KPKMetaData.h"
#import "KPKGroup.h"
#import "KPKEntry.h"
#import "KPKBinary.h"
#import "KPKTimeInfo.h"
#import "KPKErrors.h"

#import "NSDate+Packed.h"
#import "NSUUID+KeePassKit.h"
#import "NSColor+KeePassKit.h"

@interface KPKLegacyTreeReader () {
  NSData *_data;
  KPKDataStreamReader *_dataStreamer;
  KPKLegacyHeaderReader *_headerReader;
  NSMutableArray *_groupLevels;
  NSMutableArray *_groups;
  NSMutableArray *_entries;
  NSMutableDictionary *_groupIdToUUID;
  NSMutableDictionary *_iconUUIDMap;
}

@end

@implementation KPKLegacyTreeReader

- (id)initWithData:(NSData *)data headerReader:(id<KPKHeaderReading>)headerReader {
  NSAssert([headerReader isKindOfClass:[KPKLegacyHeaderReader class]], @"Incompatible header reader type supplied");
  self = [super init];
  if(self) {
    _data = data;
    _dataStreamer = [[KPKDataStreamReader alloc] initWithData:_data];
    _headerReader = (KPKLegacyHeaderReader *)headerReader;
    _groupLevels = [[NSMutableArray alloc] initWithCapacity:_headerReader.numberOfGroups];
    _groups = [[NSMutableArray alloc] initWithCapacity:_headerReader.numberOfGroups];
    _groupIdToUUID = [[NSMutableDictionary alloc] initWithCapacity:_headerReader.numberOfGroups];
    _entries = [[NSMutableArray alloc] initWithCapacity:_headerReader.numberOfEntries];
    
  }
  return self;
}

- (KPKTree *)tree:(NSError *__autoreleasing *)error {
  
  if(![self _readGroups:error]) {
    return nil;
  }
  
  if(![self _readEntries:error]) {
    return nil;
  }
  
  return [self _buildTree:error];
}


#pragma mark -
#pragma mark Content Reading Groups/Entries/Tree

- (KPKTree *)_buildTree:(NSError **)error {
  KPKTree *tree = [[KPKTree alloc] init];
  tree.metaData.rounds = _headerReader.rounds;
  /* Read the meta entries after all groups
   and entries are parsed to be able to search for them
   since KeePassX Stores custom icons for entries and groups
   */
  [self _readMetaEntries:(KPKTree *)tree];
  
  NSInteger groupIndex;
  NSInteger parentIndex;
  NSUInteger groupLevel;
  NSUInteger parentLevel;
  
  /*
   Root Group does not get stored inside KDB file
   initalize it with sane defaults
   */
  KPKGroup *rootGroup = [[KPKGroup alloc] init];
  rootGroup.name = NSLocalizedString(@"DATABASE", "");
  rootGroup.iconId = 48;
  tree.root = rootGroup;
  rootGroup.isExpanded = YES;
  
  // Find the parent for every group
  for(groupIndex = 0; groupIndex < [_groups count]; groupIndex++) {
    KPKGroup *group = _groups[groupIndex];
    groupLevel = [_groupLevels[groupIndex] integerValue];
    BOOL foundLostGroup = NO;
    if (groupLevel == 0) {
      [rootGroup addGroup:group];
      continue;
    }
    // The first item with a lower level is the parent
    for(parentIndex = groupIndex - 1; parentIndex >= 0; parentIndex--) {
      parentLevel = [_groupLevels[parentIndex] integerValue];
      if (parentLevel < groupLevel) {
        if (groupLevel - parentLevel != 1) {
          KPKCreateError(error, KPKErrorLegacyCorruptTree, @"ERROR_KDB_CORRUPT_TREE", "");
          return nil;
        }
        else {
          break;
        }
      }
      if(parentIndex == 0) {
        /*
         KPKCreateError(error, KPKErrorLegacyCorruptTree, @"ERROR_KDB_CORRUPT_TREE", "");
         return nil;
         */
        foundLostGroup = YES;
        [tree.root addGroup:group];
        group.updateTiming = NO;
      }
    }
    if(!foundLostGroup) {
      KPKGroup *parent = _groups[parentIndex];
      [parent addGroup:group];
      group.updateTiming = NO;
    }
  }
  for(KPKEntry *entry in tree.root.entries) {
    entry.updateTiming = YES;
    entry.tree = tree;
  }
  for(KPKGroup *group in [tree allGroups]) {
    group.tree = tree;
    for(KPKEntry *entry in group.entries) {
      entry.updateTiming = YES;
      entry.tree = tree;
    }
  }
  
  return tree;
}

- (BOOL)_readGroups:(NSError **)error {
  
  uint16_t fieldType;
  uint32_t fieldSize;
  uint8_t dateBuffer[5];
  
  // Parse the groups
  for (NSUInteger groupIndex = 0; groupIndex < _headerReader.numberOfGroups; groupIndex++) {
    KPKGroup *group = [[KPKGroup alloc] init];
    group.updateTiming = NO;
    
    // Parse the fields
    BOOL done = NO;
    while (!done) {
      fieldType = [_dataStreamer read2Bytes];
      fieldSize = [_dataStreamer read4Bytes];
      
      fieldType = CFSwapInt16LittleToHost(fieldType);
      fieldSize = CFSwapInt32LittleToHost(fieldSize);
      
      switch (fieldType) {
        case KPKFieldTypeCommonHash:
          if(fieldSize > 0) {
            if(![self _readHashData:error]) {
              return NO;
            }
          }
          break;
          
        case KPKFieldTypeGroupId: {
          uint32_t groupId = CFSwapInt32LittleToHost([_dataStreamer read4Bytes]);
          group.uuid = [NSUUID UUID];
          _groupIdToUUID[@(groupId)] = group.uuid;
          break;
        }
          
        case KPKFieldTypeGroupName:
          group.name = [_dataStreamer stringWithLenght:fieldSize encoding:NSUTF8StringEncoding];
          break;
          
        case KPKFieldTypeGroupCreationTime:
          if(fieldSize != 5) {
            KPKCreateError(error, KPKErrorLegacyInvalidFieldSize, @"ERROR_INVALID_FIELD_SIZE", "");
            return NO;
          }
          [_dataStreamer readBytes:dateBuffer length:fieldSize];
          group.timeInfo.creationTime = [NSDate dateFromPackedBytes:dateBuffer];
          break;
          
        case KPKFieldTypeGroupModificationTime:
          if(fieldSize != 5) {
            KPKCreateError(error, KPKErrorLegacyInvalidFieldSize, @"ERROR_INVALID_FIELD_SIZE", "");
            return NO;
          }
          [_dataStreamer readBytes:dateBuffer length:fieldSize];
          group.timeInfo.lastModificationTime = [NSDate dateFromPackedBytes:dateBuffer];
          break;
          
        case KPKFieldTypeGroupAccessTime:
          if(fieldSize != 5) {
            KPKCreateError(error, KPKErrorLegacyInvalidFieldSize, @"ERROR_INVALID_FIELD_SIZE", "");
            return NO;
          }
          [_dataStreamer readBytes:dateBuffer length:fieldSize];
          group.timeInfo.lastAccessTime = [NSDate dateFromPackedBytes:dateBuffer];
          break;
          
        case KPKFieldTypeGroupExpiryDate:
          if(fieldSize != 5) {
            KPKCreateError(error, KPKErrorLegacyInvalidFieldSize, @"ERROR_INVALID_FIELD_SIZE", "");
            return NO;
          }
          [_dataStreamer readBytes:dateBuffer length:fieldSize];
          group.timeInfo.expiryTime = [NSDate dateFromPackedBytes:dateBuffer];
          break;
          
        case KPKFieldTypeGroupImage:
          if(fieldSize != 4) {
            KPKCreateError(error, KPKErrorLegacyInvalidFieldSize, @"ERROR_INVALID_FIELD_SIZE", "");
            return NO;
          }
          group.iconId = [_dataStreamer read4Bytes];
          group.iconId = CFSwapInt32LittleToHost(group.iconId);
          break;
          
        case KPKFieldTypeGroupLevel: {
          if(fieldSize != 2) {
            KPKCreateError(error, KPKErrorLegacyInvalidFieldSize, @"ERROR_INVALID_FIELD_SIZE", "");
            return NO;
          }
          uint16_t level = [_dataStreamer read2Bytes];
          level = CFSwapInt16LittleToHost(level);
          NSAssert(group.uuid != nil, @"UUDI needs to be present");
          [_groupLevels addObject:@(level)];
          break;
        }
          
        case KPKFieldTypeGroupFlags:
          /*
           KeePass suggest ignoring this is fine
           group.flags = [inputStream readInt32];
           group.flags = CFSwapInt32LittleToHost(group.flags);
           */
          [_dataStreamer skipBytes:4];
          
          break;
          
        case KPKFieldTypeCommonStop:
          if (fieldSize != 0) {
            group = nil;
            KPKCreateError(error, KPKErrorLegacyInvalidFieldSize, @"ERROR_INVALID_FIELD_SIZE", "");
            return NO;
          }
          [_groups addObject:group];
          done = YES;
          break;
          
        default:
          group = nil;
          KPKCreateError(error, KPKErrorLegacyInvalidFieldType, @"ERROR_INVALID_FIELD_TYPE", "");
          return NO;
      }
    }
  }
  return YES;
}

- (BOOL)_readEntries:(NSError **)error {
  
  uint16_t fieldType;
  uint32_t fieldSize;
  uint8_t buffer[16];
  NSUUID *groupUUID;
  BOOL endOfStream;
  
  
  // Parse the entries
  for (NSUInteger iEntryIndex = 0; iEntryIndex < _headerReader.numberOfEntries; iEntryIndex++) {
    KPKEntry *entry = [[KPKEntry alloc] init];
    entry.updateTiming = NO;
    KPKBinary *binary; // placeholder for binary reading
    
    // Parse the entry
    endOfStream = NO;
    while (!endOfStream) {
      if([_dataStreamer countOfReadableBytes] == 0) {
        KPKCreateError(error, KPKErrorLegacyCorruptTree, @"ERROR_CORRUPT_DATA", "");
        return NO;
      }
      fieldType = [_dataStreamer read2Bytes];
      fieldSize = [_dataStreamer read4Bytes];
      
      fieldType = CFSwapInt16LittleToHost(fieldType);
      fieldSize = CFSwapInt32LittleToHost(fieldSize);
      
      switch (fieldType) {
        case KPKFieldTypeCommonHash:
          if(fieldSize > 0) {
            if(![self _readHashData:error]) {
              return NO;
            }
          }
          break;
          
        case KPKFieldTypeEntryUUID:
          if (fieldSize != 16) {
            KPKCreateError(error, KPKErrorLegacyInvalidFieldSize, @"ERROR_INVALID_FIELD_SIZE", "");
            return NO;
          }
          [_dataStreamer readBytes:buffer length:fieldSize];
          entry.uuid = [[NSUUID alloc] initWithUUIDBytes:buffer];
          break;
          
        case KPKFieldTypeEntryGroupId: {
          uint32_t groupId = CFSwapInt32LittleToHost([_dataStreamer read4Bytes]);
          groupUUID = _groupIdToUUID[@(groupId)];
          break;
        }
          
        case KPKFieldTypeEntryImage:
          entry.iconId = CFSwapInt32LittleToHost([_dataStreamer read4Bytes]);
          break;
          
        case KPKFieldTypeEntryTitle:
          entry.title = [_dataStreamer stringWithLenght:fieldSize encoding:NSUTF8StringEncoding];
          break;
          
        case KPKFieldTypeEntryURL:
          entry.url = [_dataStreamer stringWithLenght:fieldSize encoding:NSUTF8StringEncoding];
          break;
          
        case KPKFieldTypeEntryUsername:
          entry.username = [_dataStreamer stringWithLenght:fieldSize encoding:NSUTF8StringEncoding];
          break;
          
        case KPKFieldTypeEntryPassword:
          entry.password = [_dataStreamer stringWithLenght:fieldSize encoding:NSUTF8StringEncoding];
          break;
          
        case KPKFieldTypeEntryNotes:
          entry.notes = [_dataStreamer stringWithLenght:fieldSize encoding:NSUTF8StringEncoding];
          [self _parseNotes:entry];
          break;
          
        case KPKFieldTypeEntryCreationTime:
          if (fieldSize != 5) {
            KPKCreateError(error, KPKErrorLegacyInvalidFieldSize, @"ERROR_INVALID_FIELD_SIZE", "");
            return NO;
          }
          [_dataStreamer readBytes:buffer length:fieldSize];
          entry.timeInfo.creationTime = [NSDate dateFromPackedBytes:buffer];
          break;
          
        case KPKFieldTypeEntryModificationTime:
          if (fieldSize != 5) {
            KPKCreateError(error, KPKErrorLegacyInvalidFieldSize, @"ERROR_INVALID_FIELD_SIZE", "");
            return NO;
          }
          [_dataStreamer readBytes:buffer length:fieldSize];
          entry.timeInfo.lastModificationTime = [NSDate dateFromPackedBytes:buffer];
          break;
          
        case KPKFieldTypeEntryAccessTime:
          if (fieldSize != 5) {
            KPKCreateError(error, KPKErrorLegacyInvalidFieldSize, @"ERROR_INVALID_FIELD_SIZE", "");
            return NO;
          }
          [_dataStreamer readBytes:buffer length:fieldSize];
          entry.timeInfo.lastAccessTime = [NSDate dateFromPackedBytes:buffer];
          break;
          
        case KPKFieldTypeEntryExpiryDate:
          if (fieldSize != 5) {
            KPKCreateError(error, KPKErrorLegacyInvalidFieldSize, @"ERROR_INVALID_FIELD_SIZE", "");
            return NO;
          }
          [_dataStreamer readBytes:buffer length:fieldSize];
          entry.timeInfo.expiryTime = [NSDate dateFromPackedBytes:buffer];
          break;
          
        case KPKFieldTypeEntryBinaryDescription: {
          binary = [[KPKBinary alloc] init];
          
          binary.name = [_dataStreamer stringWithLenght:fieldSize encoding:NSUTF8StringEncoding];
          break;
        }
        case KPKFieldTypeEntryBinaryData:
          NSAssert(binary != nil, @"Description field has to be read fist");
          if (fieldSize > 0) {
            binary.data = [_dataStreamer dataWithLength:fieldSize];
            [entry addBinary:binary];
          }
          break;
          
        case KPKFieldTypeCommonStop:
          if (fieldSize != 0) {
            KPKCreateError(error, KPKErrorLegacyInvalidFieldSize, @"ERROR_INVALID_FIELD_SIZE", "");
            return NO;
          }
          /* Only add non-meta entries to the groups as the other are stored separately */
          if(![entry isMeta]) {
            for(KPKGroup *group in _groups) {
              if([group.uuid isEqual:groupUUID]) {
                [group addEntry:entry];
              }
            }
          }
          [_entries addObject:entry];
          
          endOfStream = YES;
          break;
          
        default:
          KPKCreateError(error, KPKErrorLegacyInvalidFieldType, @"ERROR_INVALID_FIELD_TYPE", "");
          return NO;
      }
    }
  }
  return YES;
}

- (BOOL)_readHashData:(NSError **)error {
  uint16_t fieldType;
  uint32_t fieldSize;
  NSData *headerHash;
	
  while(YES) {
    if([_dataStreamer countOfReadableBytes] == 0) {
      KPKCreateError(error, KPKErrorLegacyCorruptTree, @"ERROR_CORRUPT_DATA", "");
      return NO;
    }
    fieldType = [_dataStreamer read2Bytes];
    fieldSize = [_dataStreamer read4Bytes];
    
    fieldType = CFSwapInt16LittleToHost(fieldType);
    fieldSize = CFSwapInt32LittleToHost(fieldSize);
		switch (fieldType) {
      case KPKFieldTypeCommonHash:
        [_dataStreamer skipBytes:fieldSize];
        break;
        
      case KPKHeaderHashFieldTypeHeaderHash:
        if (fieldSize != 32) {
          KPKCreateError(error, KPKErrorLegacyInvalidFieldSize, @"ERROR_INVALID_FIELD_SIZE", "");
          return NO;
        }
        headerHash = [_dataStreamer dataWithLength:fieldSize];
        if(![headerHash isEqualToData:_headerReader.headerHash]) {
          KPKCreateError(error, KPKErrorPasswordAndOrKeyfileWrong, @"ERROR_PASSWORD_OR_KEYFILE_WRONG", "");
          return NO;
        }
        break;
        
      case KPKHeaderHashFieldTypeRandomData:
        // Ignore random data
        [_dataStreamer skipBytes:fieldSize];
        break;
        
      case KPKFieldTypeCommonStop:
        return YES;
        
      default:
        KPKCreateError(error, KPKErrorLegacyInvalidFieldType, @"ERROR_INVALID_FIELD_TYPE", "");
        return NO;
		}
	}
}

- (void)_parseNotes:(KPKEntry *)notes {
  /*
   TODO
   
   Notes contain Autotype information.
   Parse notes and extract any exsisting
   autotype info
   
   Autotype on KeePass1 Files workd with different values,
   need to be converted!
   
   See http://keepass.info/help/base/autotype.html for references!
   */
}

#pragma mark -
#pragma mark Meta Entries

/*
 Keepass and KeepassX store additional information inside meta entries.
 This information can be mapped to some of the attributes inside the KDBX
 Metadata. Thus we need to try to parse those know meta entries, and store
 the ones we do not know to not destroy the file on write
 */
- (void)_readMetaEntries:(KPKTree *)tree {
  NSMutableArray *metaEntries = [[NSMutableArray alloc] initWithCapacity:[_entries count] / 2];
  for(KPKEntry *entry in _entries) {
    if([entry isMeta]) {
      [metaEntries addObject:entry];
      if(![self _parseMetaEntry:entry metaData:tree.metaData]) {
        /* We need to store unknown data to write it back out */
        KPKBinary *binary = [entry.binaries lastObject];
        if(binary) {
          KPKBinary *metaBinary = [[KPKBinary alloc] init];
          metaBinary.data = binary.data;
          metaBinary.name = entry.title;
          [tree.metaData.unknownMetaEntryData addObject:metaBinary];
        }
      }
    }
  }
  [_entries removeObjectsInArray:metaEntries];
}

- (BOOL)_parseMetaEntry:(KPKEntry *)entry metaData:(KPKMetaData *)metaData {
  KPKBinary *binary = [entry.binaries lastObject];
  NSData *data = binary.data;
  if([data length] == 0) {
    return NO;
  }
  if([entry.notes isEqualToString:KPKMetaEntryCustomKVP]) {
    // Custom KeyValueProvierd - unsupported!
    return NO;
  }
  if([entry.notes isEqualToString:KPKMetaEntryDatabaseColor]) {
    [self _parseColorData:data metaData:metaData];
    return YES;
  }
  if([entry.notes isEqualToString:KPKMetaEntryDefaultUsername] ) {
    metaData.defaultUserName = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return YES;
  }
  if([entry.notes isEqualToString:KPKMetaEntryUIState]) {
    [self _parseUIStateData:data metaData:metaData];
    return YES;
  }
  if([entry.notes isEqualToString:KPKMetaEntryKeePassXCustomIcon2]) {
    return [self _parseKPXCustomIcon:data metaData:metaData];
  }
  if([entry.notes isEqualToString:KPKMetaEntryKeePassXGroupTreeState]) {
    return [self _parseKPXTreeState:data];
  }
  return NO;
}
/*
 Keepass Structure
 typedef struct _PMS_SIMPLE_UI_STATE
 {
 DWORD uLastSelectedGroupId;
 DWORD uLastTopVisibleGroupId;
 BYTE aLastSelectedEntryUuid[16];
 BYTE aLastTopVisibleEntryUuid[16];
 DWORD dwReserved01;
 .
 .
 .
 DWORD dwReserved16;
 } PMS_SIMPLE_UI_STATE;
 */
- (void)_parseUIStateData:(NSData *)data metaData:(KPKMetaData *)metaData {
  KPKDataStreamReader *dataReader = [[KPKDataStreamReader alloc] initWithData:data];
  uint32_t groupId = 0;
  
  if([dataReader countOfReadableBytes] >= 4) {
    groupId = [dataReader read4Bytes];
    metaData.lastSelectedGroup = _groupIdToUUID[@(groupId)];
  }
  if([dataReader countOfReadableBytes] >= 4) {
    groupId = [dataReader read4Bytes];
    metaData.lastTopVisibleGroup = _groupIdToUUID[@(groupId)];
  }
  NSData *uuidData;
  NSUUID *lastSelectedEntryUUID;
  if([dataReader countOfReadableBytes] >= 16) {
    uuidData = [dataReader dataWithLength:16];
    lastSelectedEntryUUID = [[NSUUID alloc] initWithData:uuidData];
    // right now this data is ignored.
  }
  NSUUID *lastVisibleEntryUUID;
  if([dataReader countOfReadableBytes] >= 16) {
    uuidData = [dataReader dataWithLength:16];
    lastVisibleEntryUUID = [[NSUUID alloc] initWithData:uuidData];
  }
  for(KPKGroup *group in _groups) {
    if([group.uuid isEqual:metaData.lastSelectedGroup]) {
      group.lastTopVisibleEntry = lastVisibleEntryUUID;
      break;
    }
  }
}

/*
 Stored as uint32_t (COLORREF)  0x00bbggrr;
 */
- (void)_parseColorData:(NSData *)data metaData:(KPKMetaData *)metaData {
  if([data length] == sizeof(uint32_t)) {
    
    uint32_t color;
    [data getBytes:&color length:4];
    color = CFSwapInt32LittleToHost(color);
    /* Read only the first 3 bytes, leave the last one out */
    NSData *colorData = [NSData dataWithBytesNoCopy:&color length:3 freeWhenDone:NO];
    metaData.color = [NSColor colorWithData:colorData];
  }
}

- (BOOL)_parseKPXCustomIcon:(NSData *)data metaData:(KPKMetaData *)metaData {
  
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
  
  if([data length] < 12) {
    return NO; // Data is truncated
  }
  
  KPKDataStreamReader *dataReader = [[KPKDataStreamReader alloc] initWithData:data];
  uint32_t numberOfIcons = CFSwapInt32LittleToHost([dataReader read4Bytes]);
  uint32_t numberOfEntries = CFSwapInt32LittleToHost([dataReader read4Bytes]);
  uint32_t numberOfGroups = CFSwapInt32LittleToHost([dataReader read4Bytes]);
  
  /* Read Icons */
  NSMutableArray *iconUUIDs = [[NSMutableArray alloc] initWithCapacity:numberOfIcons];
  _iconUUIDMap = [[NSMutableDictionary  alloc] initWithCapacity:numberOfIcons];
  for(NSUInteger index = 0; index < numberOfIcons; index++) {
    if([dataReader countOfReadableBytes] < 4) {
      return NO; // Data is truncated
    }
    uint32_t iconDataSize = CFSwapInt32LittleToHost([dataReader read4Bytes]);
    if([dataReader countOfReadableBytes] < iconDataSize) {
      return NO; // Data is truncated
    }
    KPKIcon *icon = [[KPKIcon alloc] initWithData:[dataReader dataWithLength:iconDataSize]];
    [metaData addCustomIcon:icon];
    [iconUUIDs addObject:icon.uuid];
    _iconUUIDMap[ icon.uuid ] = icon;
  }
  
  if([dataReader countOfReadableBytes] < (numberOfEntries * 20)) {
    return NO; // Data truncated
  }
  /* Read Entries */
  for(NSUInteger entryIndex = 0; entryIndex < numberOfEntries; entryIndex++) {
    NSUUID *entryUUID = [[NSUUID alloc] initWithData:[dataReader dataWithLength:16]];
    uint32_t iconId = CFSwapInt32LittleToHost([dataReader read4Bytes]);
    KPKEntry *entry = [self _findEntryForUUID:entryUUID];
    if([iconUUIDs count] <= iconId) {
      return NO;
    }
    entry.iconUUID = iconUUIDs[iconId];
  }
  if([dataReader countOfReadableBytes] < (numberOfGroups * 8)) {
    return NO; // Data truncated
  }
  /* Read Groups */
  for(NSUInteger groupIndex = 0; groupIndex < numberOfGroups; groupIndex++) {
    uint32_t groupId = CFSwapInt32LittleToHost([dataReader read4Bytes]);
    uint32_t groupIconId = CFSwapInt32LittleToHost([dataReader read4Bytes]);
    NSUUID *groupUUID = _groupIdToUUID[ @(groupId) ];
    if( !groupUUID || groupIconId >= [iconUUIDs count]) {
      return NO;
    }
    KPKGroup *group = [self _findGroupForUUID:groupUUID];
    group.iconUUID = iconUUIDs[groupIconId];
  }
  return YES;
}

- (BOOL)_parseKPXTreeState:(NSData *)data {
  
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
  
  if([data length] < 4) {
    return NO;
  }
  
  KPKDataStreamReader *dataReader = [[KPKDataStreamReader alloc] initWithData:data];
  uint32_t count = CFSwapInt32LittleToHost([dataReader read4Bytes]);
  
  if([data length] - 4 != (count * 5)) {
    return NO; // Data is truncated
  }
  
  for(NSUInteger index = 0; index < count; index++) {
    uint32_t groupId = CFSwapInt32LittleToHost([dataReader read4Bytes]);
    BOOL isExpanded = [dataReader readByte];
    NSUUID *groupUUID = _groupIdToUUID[ @(groupId) ];
    if(!groupUUID) {
      continue;
    }
    KPKGroup *group = [self _findGroupForUUID:groupUUID];
    group.isExpanded = isExpanded;
  }
  return YES;
}

#pragma mark -
#pragma mark Helper

- (KPKGroup *)_findGroupForUUID:(NSUUID *)uuid {
  for(KPKGroup *group in _groups) {
    if([group.uuid isEqual:uuid]) {
      return group;
    }
  }
  return nil;
}

- (KPKEntry *)_findEntryForUUID:(NSUUID *)uuid {
  for(KPKEntry *entry in _entries) {
    if([entry.uuid isEqual:uuid]) {
      return entry;
    }
  }
  return nil;
}

@end
