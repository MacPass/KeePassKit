//
//  KPKTree.m
//  KeePassKit
//
//  Created by Michael Starke on 11.07.13.
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

#import "KPKTree.h"
#import "KPKGroup.h"
#import "KPKEntry.h"
#import "KPKMetaData.h"

@class KPKIcon;

@implementation KPKTree

- (id)init {
  self = [super init];
  if(self) {
    _metadata = [[KPKMetaData alloc] init];
    _deletedObjects = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (KPKGroup *)createGroup:(KPKGroup *)parent {
  KPKGroup *group = [[KPKGroup alloc] init];
  group.undoManager = self.undoManager;
  group.parent = parent;
  return group;
}

- (KPKEntry *)createEntry:(KPKGroup *)parent {
  KPKEntry *entry = [[KPKEntry alloc] init];
  entry.parent = parent;
  entry.undoManager = self.undoManager;
  return entry;
}

- (void)setRoot:(KPKGroup *)root {
  if(!_groups || [_groups count] == 0) {
    _groups = @[root];
    return;
  }
  id group = _groups[0];
  if(group != root) {
    _groups = @[root];
  }
}

- (NSUndoManager *)undoManager {
  return self.metadata.undoManager;
}

- (void)setUndoManager:(NSUndoManager *)undoManager {
  self.metadata.undoManager = undoManager;
}

- (KPKGroup *)root {
  return _groups[0];
}

- (NSArray *)allGroups {
  return [self.root childGroups];
}

- (NSArray *)allEntries {
  return [self.root childEntries];
}

@end
