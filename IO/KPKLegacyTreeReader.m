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
  
  /*
   @try {
   // Parse groups
   [self readGroups:aesInputStream];
   
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
    
  uint16_t fieldType;
  uint32_t fieldSize;
  uint8_t dateBuffer[5];
  
  // Parse the groups
  for (NSUInteger groupIndex = 0; groupIndex < _headerReader.numberOfGroups; groupIndex++) {
    KPKGroup *group = [[KPKGroup alloc] init];
    
    // Parse the fields
    while (true) {
      fieldType = [_dataStreamer read2Bytes];
      fieldSize = [_dataStreamer read4Bytes];
      
      fieldType = CFSwapInt16LittleToHost(fieldType);
      fieldSize = CFSwapInt32LittleToHost(fieldSize);
      
      switch (fieldType) {
        case KPKFieldTypeCommonSize:
          if (fieldSize > 0) {
            [self _readExtendedData];
          }
          break;
          
        case KPKFieldTypeGroupId: {
          uint32 bytes = [_dataStreamer read4Bytes];
          //group.groupId = [inputStream readInt32];
          //group.groupId = CFSwapInt32LittleToHost(group.groupId);
          break;
          
        }
          
        case KPKFieldTypeGroupName: {
          char characters[fieldSize];
          [_dataStreamer readBytes:characters length:fieldSize];
          group.name = [NSString stringWithCString:characters encoding:NSUTF8StringEncoding];
          break;
        }
        
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
          uint16_t level = [_dataStreamer read2Bytes];
          level = CFSwapInt16LittleToHost(level);
          [_levels addObject:@(level)];
          break;
        }
          
        case KPKFieldTypeGroupFlags:
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
          return YES; // Finished
          
        default:
          group = nil;
          KPKCreateError(error, KPKErrorLegacyInvalidFieldType, @"ERROR_INVALID_FIELD_TYPE", "");
          return NO;
      }
    }
  }
  return YES;
}

- (void)_readExtendedData {

}


@end
