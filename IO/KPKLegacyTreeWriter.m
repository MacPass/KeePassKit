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
#import "KPKDataStreamWriter.h"
#import "KPKTree.h"
#import "KPKMetaData.h"

@interface KPKLegacyTreeWriter () {
  KPKDataStreamWriter *_dataWriter;
}

@end

@implementation KPKLegacyTreeWriter

- (id)initWithTree:(KPKTree *)tree headerWriter:(id<KPKHeaderWriting>)headerWriter {
  self = [super init];
  if(self) {
    _tree = tree;
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
  // TODO
}

- (void)_writeEntry:(KPKEntry *)entry {
  // TODO
}

- (void)_writeMetaData {
  // Write metadata based on tree metadata.
  //[_tree.metaData.unknownMetaEntries];
}

@end
