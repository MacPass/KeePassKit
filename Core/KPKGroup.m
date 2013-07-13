//
//  KPKGroup.m
//  KeePassKit
//
//  Created by Michael Starke on 12.07.13.
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

#import "KPKGroup.h"
#import "KPKEntry.h"

@interface KPKGroup () {
  @private
    NSMutableArray *_groups;
    NSMutableArray *_entries;
}

@end

@implementation KPKGroup

- (id)init {
  self = [super init];
  if (self) {
    _groups = [[NSMutableArray alloc] initWithCapacity:8];
    _entries = [[NSMutableArray alloc] initWithCapacity:16];
    _canAddEntries = YES;
  }
  return self;
}

- (void)addGroup:(KPKGroup *)group {
  group.parent = self;
  [self insertObject:group inGroupsAtIndex:[self.groups count]];
}

- (void)removeGroup:(KPKGroup *)group {
  group.parent = nil;
  [_groups removeObject:group];
}

- (void)moveToGroup:(KPKGroup *)group {
  [self.parent removeGroup:group];
  [group addGroup:group];
}

- (void)addEntry:(KPKEntry *)entry {
  entry.parent = self;
  [_entries addObject:entry];
}

- (void)removeEntry:(KPKEntry *)entry {
  entry.parent = nil;
  [_entries removeObject:entry];
}

- (void)moveEntry:(KPKEntry *)entry toGroup:(KPKEntry *)toGroup {
  //[self removeEntry:entry];
  //[toGroup addEntry:entry];
}

- (BOOL)containsGroup:(KPKGroup *)group {
  // Check trivial case where group is passed to itself
  if (self == group) {
    return YES;
  } else {
    // Check subgroups
    for (KPKGroup *subGroup in self.groups) {
      if ([subGroup containsGroup:group]) {
        return YES;
      }
    }
    return NO;
  }
}

- (NSString*)description {
  return [NSString stringWithFormat:@"KdbGroup [image=%ld, name=%@, creationTime=%@, lastModificationTime=%@, lastAccessTime=%@, expiryTime=%@]",
          self.image,
          _name,
          self.creationTime,
          self.lastModificationTime,
          self.lastAccessTime,
          self.expiryTime];
}


- (NSUInteger)countOfEntries {
  return [_entries count];
}

- (void)insertObject:(KPKEntry *)entry inEntriesAtIndex:(NSUInteger)index {
  [_entries insertObject:entry atIndex:index];
}

- (void)removeObjectFromEntriesAtIndex:(NSUInteger)index {
  [_entries removeObjectAtIndex:index];
}

- (NSUInteger)countOfGroups {
  return [_groups count];
}

- (void)insertObject:(KPKGroup *)group inGroupsAtIndex:(NSUInteger)index {
  [_groups insertObject:group atIndex:index];
}

- (void)removeObjectFromGroupsAtIndex:(NSUInteger)index {
  [_groups removeObjectAtIndex:index];
}

@end

