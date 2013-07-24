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

#import "KPKGroup.h"

@interface KPKLegacyTreeReader () {
  NSData *_data;
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
  
  return NO;
  
  uint16_t fieldType;
  uint32_t fieldSize;
  uint8_t dateBuffer[5];
  BOOL endOfStream;
  
  // Parse the groups
  for (uint32_t i = 0; i < _headerReader.numberOfGroups; i++) {
    KPKGroup *group = [[KPKGroup alloc] init];
    
    // Parse the fields
    NSUInteger location = 0;
    while (true) {
      [_data getBytes:&fieldType range:NSMakeRange(location, 2)];
      location += 2;
      [_data getBytes:&fieldSize range:NSMakeRange(location, 4)];
      location +=4;
      
      fieldType = CFSwapInt16LittleToHost(fieldType);
      fieldSize = CFSwapInt32LittleToHost(fieldSize);
      /*
       switch (fieldType) {
       case KPKFieldTypeCommonSize:
       if (fieldSize > 0) {
       [self readExtData:inputStream];
       }
       break;
       
       case KPKFieldTypeGroupId:
       group.groupId = [inputStream readInt32];
       group.groupId = CFSwapInt32LittleToHost(group.groupId);
       break;
       
       case KPKFieldTypeGroupName:
       group.name = [inputStream readCString:fieldSize encoding:NSUTF8StringEncoding];
       break;
       
       case KPKFieldTypeGroupCreationTime:
       [inputStream read:dateBuffer length:fieldSize];
       group.creationTime =  [NSDate dateFromPackedBytes:dateBuffer];
       break;
       
       case KPKFieldTypeGroupModificationTime:
       [inputStream read:dateBuffer length:fieldSize];
       group.lastModificationTime = [NSDate dateFromPackedBytes:dateBuffer];
       break;
       
       case KPKFieldTypeGroupAccessTime:
       [inputStream read:dateBuffer length:fieldSize];
       group.lastAccessTime = [NSDate dateFromPackedBytes:dateBuffer];
       break;
       
       case KPKFieldTypeGroupExpiryDate:
       [inputStream read:dateBuffer length:fieldSize];
       group.expiryTime = [NSDate dateFromPackedBytes:dateBuffer];
       break;
       
       case KPKFieldTypeGroupImage:
       group.image = [inputStream readInt32];
       group.image = CFSwapInt32LittleToHost(group.image);
       break;
       
       case KPKFieldTypeGroupLevel: {
       uint16_t level = [inputStream readInt16];
       level = CFSwapInt16LittleToHost(level);
       [levels addObject:@(level)];
       break;
       }
       
       case KPKFieldTypeGroupFlags:
       group.flags = [inputStream readInt32];
       group.flags = CFSwapInt32LittleToHost(group.flags);
       break;
       
       case KPKFieldTypeCommonStop:
       if (fieldSize != 0) {
       group = nil;
       @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field size" userInfo:nil];
       }
       
       [groups addObject:group];
       
       endOfStream = YES;
       break;
       
       default:
       group = nil;
       @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid field type" userInfo:nil];
       }
       */
    }
  }
  return YES;
}


@end
