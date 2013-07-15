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

@implementation KPKTree

- (id)init {
  return [self initWithData:nil password:nil];
}

- (id)initWithData:(NSData *)data password:(KPKPassword *)password {
  self = [super init];
  if(self) {
    
  }
  return self;
}

- (KPKGroup *)createGroup:(KPKGroup *)parent {
  KPKGroup *group = [[KPKGroup alloc] init];
  group.undoManger = self.undoManger;
  group.parent = parent;
  return group;
}

- (KPKEntry *)createEntry:(KPKGroup *)parent {
  KPKEntry *entry = [[KPKEntry alloc] init];
  entry.parent = parent;
  entry.undoManger = self.undoManger;
  return entry;
}

- (void)setRoot:(KPKGroup *)root {
  id group = _groups[0];
  if(group != root) {
    _groups = @[root];
  }
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
