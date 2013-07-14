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

#pragma mark Accessors

- (NSArray *)childEntries {
  NSMutableArray *childEntries = [NSMutableArray arrayWithArray:_entries];
  for(KPKGroup *group in _groups) {
    [childEntries addObjectsFromArray:[group childEntries]];
  }
  return  childEntries;
}

- (NSArray *)childGroups {
  NSMutableArray *childGroups = [NSMutableArray arrayWithArray:_groups];
  for(KPKGroup *group in _groups) {
    [childGroups addObjectsFromArray:[group childGroups]];
  }
  return childGroups;
}

#pragma mark -
#pragma mark Group/Entry editing

- (void)remove {
  /* Undo is handled in removeGroup */
  [self.parent removeGroup:self];
}

- (void)addGroup:(KPKGroup *)group atIndex:(NSUInteger)index {
  group.parent = self;
  index = MIN([_entries count], index);
  [[self.undoManger prepareWithInvocationTarget:self] removeGroup:group];
  [self insertObject:group inGroupsAtIndex:index];
}

- (void)removeGroup:(KPKGroup *)group {
  NSUInteger index = [_groups indexOfObject:group];
  if(index != NSNotFound) {
    [[self.undoManger prepareWithInvocationTarget:self] addGroup:self atIndex:index];
    group.parent = nil;
    [self removeObjectFromGroupsAtIndex:index];
  }
}

- (void)moveToGroup:(KPKGroup *)group atIndex:(NSUInteger)index {
  NSUInteger oldIndex = [self.parent.groups indexOfObject:self];
  if(oldIndex == NSNotFound) {
    return; // Parent does not contain us!
  }
  [[self.undoManger prepareWithInvocationTarget:self] moveToGroup:self.parent atIndex:oldIndex];
  BOOL wasEnabled = [self.undoManger isUndoRegistrationEnabled];
  [self.undoManger disableUndoRegistration];
  [self.parent removeGroup:group];
  [group addGroup:group atIndex:index];
  if(wasEnabled) {
    [self.undoManger enableUndoRegistration];
  }
}

- (void)addEntry:(KPKEntry *)entry atIndex:(NSUInteger)index {
  entry.parent = self;
  index = MIN([_entries count], index);
  [[self.undoManger prepareWithInvocationTarget:self] removeEntry:entry];
  [self insertObject:entry inEntriesAtIndex:index];
}

- (void)removeEntry:(KPKEntry *)entry {
  NSUInteger index = [_entries indexOfObject:entry];
  if(NSNotFound != index) {
    [[self.undoManger prepareWithInvocationTarget:self] addEntry:entry atIndex:index];
    [self removeObjectFromEntriesAtIndex:index];
    entry.parent = nil;
  }
}

- (void)moveEntry:(KPKEntry *)entry toGroup:(KPKGroup *)toGroup atIndex:(NSUInteger)index {
  NSUInteger oldIndex = [_entries indexOfObject:entry];
  if(index != NSNotFound) {
    [[self.undoManger prepareWithInvocationTarget:toGroup] moveEntry:entry toGroup:self atIndex:oldIndex];
    BOOL wasEnabled = [self.undoManger isUndoRegistrationEnabled];
    [self.undoManger disableUndoRegistration];
    [self removeEntry:entry];
    [toGroup addEntry:entry atIndex:index];
    if(wasEnabled) {
      [self.undoManger enableUndoRegistration];
    }
  }
}

- (BOOL)containsGroup:(KPKGroup *)group {
  if(self == group) {
    return YES;
  }
  BOOL containsGroup = (nil != [self groupForUUID:group.uuid]);
  return containsGroup;
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

#pragma mark Seaching

- (KPKEntry *)entryForUUID:(NSUUID *)uuid {
  NSArray *filterdEntries = [[self childEntries] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
    return [uuid isEqual:(NSUUID *)[evaluatedObject uuid]];
  }]];
  NSAssert([filterdEntries count] <= 1, @"NSUUID hast to be unique");
  return [filterdEntries lastObject];
}

- (KPKGroup *)groupForUUID:(NSUUID *)uuid {
  NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
    return [uuid isEqual:(NSUUID *)[evaluatedObject uuid]];
  }];
  NSArray *filteredGroups = [[self childGroups] filteredArrayUsingPredicate:predicate];
  NSAssert([filteredGroups count] <= 1, @"NSUUID hast to be unique");
  return  [filteredGroups lastObject];
}


#pragma mark -
#pragma mark KVC

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

