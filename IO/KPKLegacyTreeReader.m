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
#import "KPKDataStreamer.h"

#import "KPKGroup.h"
#import "KPKEntry.h"
#import "KPKBinary.h"
#import "KPKTimeInfo.h"
#import "KPKErrors.h"

#import "NSDate+Packed.h"

@interface KPKLegacyTreeReader () {
  NSData *_data;
  KPKDataStreamer *_dataStreamer;
  KPKLegacyHeaderReader *_headerReader;
  NSMutableArray *_levels;
  NSMutableArray *_groups;
  NSMutableArray *_entries;
  
}

@end

@implementation KPKLegacyTreeReader

- (id)initWithData:(NSData *)data headerReader:(id<KPKHeaderReading>)headerReader {
  NSAssert([headerReader isKindOfClass:[KPKLegacyHeaderReader class]], @"Incompatible header reader type supplied");
  self = [super init];
  if(self) {
    _data = data;
    _dataStreamer = [[KPKDataStreamer alloc] initWithData:_data];
    _headerReader = (KPKLegacyHeaderReader *)headerReader;
    _levels = [[NSMutableArray alloc] initWithCapacity:_headerReader.numberOfGroups];
    _groups = [[NSMutableArray alloc] initWithCapacity:_headerReader.numberOfGroups];
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
  
  /*
   // Parse entries
   [self readEntries:aesInputStream];
   
   // Build the tree
   return [self buildTree];
   } @finally {
   aesInputStream = nil;
   }*/
  return nil;
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
          /* Read the 4 bytes and fill the rest with zeros */
          uint8 bytes[16] = { 0 };
          [_dataStreamer readBytes:&bytes length:4];
          group.uuid = [[NSUUID alloc] initWithUUIDBytes:bytes];
          //group.groupId = [inputStream readInt32];
          //group.groupId = CFSwapInt32LittleToHost(group.groupId);
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
          [_levels addObject:@(level)];
          break;
        }
          
        case KPKFieldTypeGroupFlags:
          /*
           Flags contain information about the tree state
           isExpanded
           */
          [_dataStreamer read4Bytes];
          /*group.flags = [inputStream readInt32];
           group.flags = CFSwapInt32LittleToHost(group.flags);*/
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
          //          if ([inputStream read:buffer length:fieldSize] != fieldSize) {
          //
          //            @throw [NSException exceptionWithName:@"IOException" reason:@"Failed to read UUID" userInfo:nil];
          //          }
          [_dataStreamer readBytes:buffer length:fieldSize];
          entry.uuid = [[NSUUID alloc] initWithUUIDBytes:buffer];
          break;
          
        case KPKFieldTypeEntryGroupId: {
          uint8 bytes[16] = { 0 };
          [_dataStreamer readBytes:&bytes length:4];
          groupUUID = [[NSUUID alloc] initWithUUIDBytes:bytes];
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



@end
