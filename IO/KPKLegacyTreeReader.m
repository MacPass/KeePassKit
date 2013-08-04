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

#import "KPKLegacyTreeReader.h"
#import "KPKLegacyHeaderReader.h"
#import "KPKHeaderFields.h"
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

@interface KPKLegacyTreeReader () {
  NSData *_data;
  KPKDataStreamReader *_dataStreamer;
  KPKLegacyHeaderReader *_headerReader;
  NSMutableArray *_groupLevels;
  NSMutableArray *_groups;
  NSMutableArray *_entries;
  NSMutableDictionary *_groupIdToUUID;
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

- (BOOL)_readGroups:(NSError **)error {
  
  uint16 fieldType;
  uint32 fieldSize;
  uint8 dateBuffer[5];
  
  // Parse the groups
  for (NSUInteger groupIndex = 0; groupIndex < _headerReader.numberOfGroups; groupIndex++) {
    KPKGroup *group = [[KPKGroup alloc] init];
    
    // Parse the fields
    BOOL done = NO;
    while (!done) {
      fieldType = [_dataStreamer read2Bytes];
      fieldSize = [_dataStreamer read4Bytes];
      
      fieldType = CFSwapInt16LittleToHost(fieldType);
      fieldSize = CFSwapInt32LittleToHost(fieldSize);
      
      switch (fieldType) {
        case KPKFieldTypeCommonSize:
          if (fieldSize > 0) {
            if(![self _readExtendedData:error]) {
              return NO;
            }
          }
          break;
          
        case KPKFieldTypeGroupId: {
          uint32 groupId = CFSwapInt32LittleToHost([_dataStreamer read4Bytes]);
          group.uuid = [NSUUID UUID];
          _groupIdToUUID[@(groupId)] = group.uuid;
          break;
        }
          
        case KPKFieldTypeGroupName:
          group.name = [_dataStreamer stringWithLenght:fieldSize encoding:NSUTF8StringEncoding];
          break;
          
        case KPKFieldTypeGroupCreationTime:
          [_dataStreamer readBytes:dateBuffer length:fieldSize];
          group.timeInfo.creationTime = [NSDate dateFromPackedBytes:dateBuffer];
          break;
          
        case KPKFieldTypeGroupModificationTime:
          [_dataStreamer readBytes:dateBuffer length:fieldSize];
          group.timeInfo.lastModificationTime = [NSDate dateFromPackedBytes:dateBuffer];
          break;
          
        case KPKFieldTypeGroupAccessTime:
          [_dataStreamer readBytes:dateBuffer length:fieldSize];
          group.timeInfo.lastAccessTime = [NSDate dateFromPackedBytes:dateBuffer];
          break;
          
        case KPKFieldTypeGroupExpiryDate:
          [_dataStreamer readBytes:dateBuffer length:fieldSize];
          group.timeInfo.expiryTime = [NSDate dateFromPackedBytes:dateBuffer];
          break;
          
        case KPKFieldTypeGroupImage:
          group.icon = [_dataStreamer read4Bytes];
          group.icon = CFSwapInt32LittleToHost(group.icon);
          break;
          
        case KPKFieldTypeGroupLevel: {
          uint16 level = [_dataStreamer read2Bytes];
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

/*
 Keepass and KeepassX store additional information inside meta entries.
 This information can be mapped to some of the attributes inside the KDBX
 Metadata. Thus we need to try to parse those know meta entries, and store
 the ones we do not know to not destroy the file on write
 void CPwManager::_ParseMetaStream(PW_ENTRY *p, bool bAcceptUnknown)
 {
 ASSERT(_IsMetaStream(p) == TRUE);
 
 else if(_tcscmp(p->pszAdditional, PMS_STREAM_DEFAULTUSER) == 0)
 {
 LPTSTR lpName = _UTF8ToString(p->pBinaryData);
 m_strDefaultUserName = (LPCTSTR)lpName;
 SAFE_DELETE_ARRAY(lpName);
 }
 else if(_tcscmp(p->pszAdditional, PMS_STREAM_DBCOLOR) == 0)
 {
 if(p->uBinaryDataLen >= sizeof(COLORREF))
 memcpy(&m_clr, p->pBinaryData, sizeof(COLORREF));
 }
 else if(_tcscmp(p->pszAdditional, PMS_STREAM_SEARCHHISTORYITEM) == 0)
 {
 LPTSTR lpItem = _UTF8ToString(p->pBinaryData);
 m_vSearchHistory.push_back(std::basic_string<TCHAR>((LPCTSTR)lpItem));
 SAFE_DELETE_ARRAY(lpItem);
 }
 else if(_tcscmp(p->pszAdditional, PMS_STREAM_CUSTOMKVP) == 0)
 {
 CustomKvp kvp;
 if(DeserializeCustomKvp(p->pBinaryData, kvp))
 m_vCustomKVPs.push_back(kvp);
 }
 else // Unknown meta stream -- save it
 {
 if(bAcceptUnknown)
 {
 PWDB_META_STREAM msUnknown;
 msUnknown.strName = p->pszAdditional;
 msUnknown.vData.assign(p->pBinaryData, p->pBinaryData +
 p->uBinaryDataLen);
 
 if(_CanIgnoreUnknownMetaStream(msUnknown) == FALSE)
 m_vUnknownMetaStreams.push_back(msUnknown);
 }
 }
 }
 */
 
- (BOOL)_readEntries:(NSError **)error {
  
  uint16 fieldType;
  uint32 fieldSize;
  uint8 buffer[16];
  NSUUID *groupUUID;
  BOOL endOfStream;
  
  
  // Parse the entries
  for (NSUInteger iEntryIndex = 0; iEntryIndex < _headerReader.numberOfEntries; iEntryIndex++) {
    KPKEntry *entry = [[KPKEntry alloc] init];
    
    // Parse the entry
    endOfStream = NO;
    while (!endOfStream) {
      fieldType = [_dataStreamer read2Bytes];
      fieldSize = [_dataStreamer read4Bytes];
      
      fieldType = CFSwapInt16LittleToHost(fieldType);
      fieldSize = CFSwapInt32LittleToHost(fieldSize);
      
      switch (fieldType) {
        case KPKFieldTypeCommonSize:
          if (fieldSize > 0) {
            if(![self _readExtendedData:error]){
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
          uint32 groupId = CFSwapInt32LittleToHost([_dataStreamer read4Bytes]);
          groupUUID = _groupIdToUUID[@(groupId)];
          break;
        }
          
        case KPKFieldTypeEntryImage:
          entry.icon = CFSwapInt32LittleToHost([_dataStreamer read4Bytes]);
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
          KPKBinary *binary = [[KPKBinary alloc] init];
          
          binary.name = [_dataStreamer stringWithLenght:fieldSize encoding:NSUTF8StringEncoding];
          [entry addBinary:binary];
          break;
        }
        case KPKFieldTypeEntryBinaryData:
          if (fieldSize > 0) {
            KPKBinary *binary = [entry.binaries lastObject];
            binary.data = [_dataStreamer dataWithLength:fieldSize];;
          }
          break;
          
        case KPKFieldTypeCommonStop:
          if (fieldSize != 0) {
            KPKCreateError(error, KPKErrorLegacyInvalidFieldSize, @"ERROR_INVALID_FIELD_SIZE", "");
            return NO;
          }
          for(KPKGroup *group in _groups) {
            if([group.uuid isEqual:groupUUID]) {
              [group addEntry:entry];
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

- (BOOL)_readExtendedData:(NSError **)error {
  uint16 fieldType;
  uint32 fieldSize;
  uint8 buffer[32];
	
  
	while (YES) {
    fieldType = [_dataStreamer read2Bytes];
    fieldSize = [_dataStreamer read4Bytes];
    
    fieldSize = CFSwapInt32LittleToHost(fieldSize);
    fieldType = CFSwapInt16LittleToHost(fieldType);
		switch (fieldType) {
      case 0x0000:
        // Ignore field
        [_dataStreamer skipBytes:fieldSize];
        break;
        
      case 0x0001:
        if (fieldSize != 32) {
          KPKCreateError(error, KPKErrorLegacyInvalidFieldSize, @"ERROR_INVALID_FIELD_SIZE", "");
          return NO;
        }
        [_dataStreamer readBytes:buffer length:fieldSize];
        // Compare the header hash
        if (memcmp(_headerReader.headerHash.bytes, buffer, fieldSize) != 0) {
          KPKCreateError(error, KPKErrorLegacyHeaderHashMissmatch, @"ERROR_HEADER_HASH_MISSMATCH", "");
          return NO;
        }
        break;
        
      case 0x0002:
        // Ignore random data
        [_dataStreamer skipBytes:fieldSize];
        break;
        
      case 0xFFFF:
        return YES;
        
      default:
        KPKCreateError(error, KPKErrorLegacyInvalidFieldType, @"ERROR_INVALID_FIELD_TYPE", "");
        return NO;
		}
	}
}

- (void)_parseMetaEntry:(KPKEntry *)entry metaData:(KPKMetaData *)metaData {
  KPKBinary *binary = [entry.binaries lastObject];
  NSData *data = binary.data;
  if([data length] == 0) {
    return;
  }
  if([entry.title isEqualToString:KPKMetaEntryCustomKVP]) {
    // Custom KeyValueProvierd - unsupported!
    return;
  }
  if([entry.title isEqualToString:KPKMetaEntryDatabaseColor]) {
    [self _parseColorData:data metaData:metaData];
    return;
  }
  if([entry.title isEqualToString:KPKMetaEntryDefaultUsername] ) {
    metaData.defaultUserName = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return;
  }
  if([entry.title isEqualToString:KPKMetaEntryUIState]) {
    [self _parseUIStateData:data metaData:metaData];
    return;
  }
  
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
  NSUInteger length = [data length];
  uint32 groupId = 0;

  if(length >= 4) {
    [data getBytes:&groupId range:NSMakeRange(0, 4)];
    metaData.lastSelectedGroup = _groupIdToUUID[@(groupId)];
  }
  if(length >= 8 ) {
    [data getBytes:&groupId range:NSMakeRange(4,4)];
    metaData.lastTopVisibleGroup = _groupIdToUUID[@(groupId)];
  }
  NSData *uuidData;
  NSUUID *lastSelectedEntryUUID;
  if(length >= 24) {
    uuidData = [data subdataWithRange:NSMakeRange(8, 16)];
    lastSelectedEntryUUID = [[NSUUID alloc] initWithData:uuidData];
    // right now this data is ignored.
  }
  NSUUID *lastVisibleEntryUUID;
  if(length >= 40) {
    uuidData = [data subdataWithRange:NSMakeRange(24, 16)];
    lastVisibleEntryUUID = [[NSUUID alloc] initWithData:uuidData];
  }
  for(KPKGroup *group in _groups) {
    if([group.uuid isEqual:metaData.lastSelectedGroup]) {
      group.lastTopVisibleEntry = lastVisibleEntryUUID;
      break;
    }
  }
}

- (void)_parseColorData:(NSData *)data metaData:(KPKMetaData *)metaData {
  if([data length] == sizeof(uint32)) {
    // Stored ad COLORREF 0x00bbggrr;
    uint32 color;
    [data getBytes:&color length:4];
    metaData.color = nil;
  }
}

- (void)_readMetaEntries:(KPKTree *)tree {
  NSMutableArray *metaEntries = [[NSMutableArray alloc] initWithCapacity:[_entries count] / 2];
  for(KPKEntry *entry in _entries) {
    if([entry isMeta]) {
      [metaEntries addObject:entry];
      [self _parseMetaEntry:entry metaData:tree.metaData];
    }
  }
  
  [_entries removeObjectsInArray:metaEntries];
}

- (KPKTree *)_buildTree:(NSError **)error { 
  KPKTree *tree = [[KPKTree alloc] init];
  tree.metaData.rounds = _headerReader.rounds;
  [self _readMetaEntries:(KPKTree *)tree];

  NSInteger groupIndex;
  NSInteger parentIndex;
  NSUInteger groupLevel;
  NSUInteger parentLevel;
  
  KPKGroup *root = [[KPKGroup alloc] init];
  root.name = @"Groups"; /* Modify this to use the database Name? */
  root.parent = nil;
  tree.root = root;
  
  // Find the parent for every group
  for (groupIndex = 0; groupIndex < [_groups count]; groupIndex++) {
    KPKGroup *group = _groups[groupIndex];
    groupLevel = [_groupLevels[groupIndex] integerValue];
    
    if (groupLevel == 0) {
      [root addGroup:group];
      continue;
    }
    // The first item with a lower level is the parent
    for (parentIndex = groupIndex - 1; parentIndex >= 0; parentIndex--) {
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
      if (parentIndex == 0) {
        /*
        KPKCreateError(error, KPKErrorLegacyCorruptTree, @"ERROR_KDB_CORRUPT_TREE", "");
        return nil;
         */
        [root addGroup:group];
      }
    }
    
    KPKGroup *parent = _groups[parentIndex];
    [parent addGroup:group];
  }
  
  return tree;
}

@end
