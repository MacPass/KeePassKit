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
#import "KPKTree.h"
#import "KPKDeletedNode.h"

@interface KPKGroup () {
@private
  NSMutableArray *_groups;
  NSMutableArray *_entries;
}

@end

@implementation KPKGroup

+ (NSUInteger)defaultIcon {
  return 48;
}

- (id)init {
  self = [super init];
  if (self) {
    _groups = [[NSMutableArray alloc] initWithCapacity:8];
    _entries = [[NSMutableArray alloc] initWithCapacity:16];
    self.updateTiming = YES;
  }
  return self;
}

#pragma mark -
#pragma mark Properties

- (void)setExpires:(BOOL)expires {
  [[self.undoManager prepareWithInvocationTarget:self] setExpires:_expires];
  self.expires = expires;
  [self wasModified];
}

- (void)setName:(NSString *)name {
  if(![_name isEqualToString:name]) {
    [self.undoManager registerUndoWithTarget:self selector:@selector(setName:) object:self.name];
    _name = [name copy];
    [self wasModified];
  }
}

- (void)setNotes:(NSString *)notes {
  if(![_notes isEqualToString:notes]) {
    [self.undoManager registerUndoWithTarget:self selector:@selector(setName:) object:self.notes];
    _notes = [notes copy];
    [self wasModified];
  }
}

#pragma mark -
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

- (void)addGroup:(KPKGroup *)group {
  [self addGroup:group atIndex:[_groups count]];
}

- (void)addGroup:(KPKGroup *)group atIndex:(NSUInteger)index {
  group.parent = self;
  group.tree = self.tree;
  index = MIN([_groups count], index);
  [[self.undoManager prepareWithInvocationTarget:self] removeGroup:group];
  /* Remove entries that might have been added to the deleted objects */
  [self.tree.deletedObjects removeObjectForKey:group.uuid];
  [self insertObject:group inGroupsAtIndex:index];
  [self wasModified];
}

- (void)removeGroup:(KPKGroup *)group {
  NSUInteger index = [_groups indexOfObject:group];
  if(index != NSNotFound) {
    [[self.undoManager prepareWithInvocationTarget:self] addGroup:self atIndex:index];
    group.parent = nil;
    /* Add group to deleted objects */
    self.tree.deletedObjects[ group.uuid ] = [[KPKDeletedNode alloc] initWithNode:group];
    [self removeObjectFromGroupsAtIndex:index];
    [self wasModified];
  }
}

- (void)moveToGroup:(KPKGroup *)group atIndex:(NSUInteger)index {
  NSUInteger oldIndex = [self.parent.groups indexOfObject:self];
  if(oldIndex == NSNotFound) {
    return; // Parent does not contain us!
  }
  [[self.undoManager prepareWithInvocationTarget:self] moveToGroup:self.parent atIndex:oldIndex];
  BOOL wasEnabled = [self.undoManager isUndoRegistrationEnabled];
  [self.undoManager disableUndoRegistration];
  [self.parent removeGroup:group];
  [group addGroup:group atIndex:index];
  if(wasEnabled) {
    [self.undoManager enableUndoRegistration];
  }
  [self wasModified];
  [self wasMoved];
}

- (void)addEntry:(KPKEntry *)entry {
  [self addEntry:entry atIndex:[self.entries count]];
}

- (void)addEntry:(KPKEntry *)entry atIndex:(NSUInteger)index {
  entry.parent = self;
  index = MIN([_entries count], index);
  [[self.undoManager prepareWithInvocationTarget:self] removeEntry:entry];
  /* Remove the deleted Object */
  [self.tree.deletedObjects removeObjectForKey:entry.uuid];
  [self insertObject:entry inEntriesAtIndex:index];
}

- (void)removeEntry:(KPKEntry *)entry {
  NSUInteger index = [_entries indexOfObject:entry];
  if(NSNotFound != index) {
    [[self.undoManager prepareWithInvocationTarget:self] addEntry:entry atIndex:index];
    [self removeObjectFromEntriesAtIndex:index];
    /* Add the entry to the deleted Objects */
    self.tree.deletedObjects[ entry.uuid ] = [[KPKDeletedNode alloc] initWithNode:entry];
    entry.parent = nil;
  }
}

- (void)moveEntry:(KPKEntry *)entry toGroup:(KPKGroup *)toGroup atIndex:(NSUInteger)index {
  NSUInteger oldIndex = [_entries indexOfObject:entry];
  if(index != NSNotFound) {
    [[self.undoManager prepareWithInvocationTarget:toGroup] moveEntry:entry toGroup:self atIndex:oldIndex];
    BOOL wasEnabled = [self.undoManager isUndoRegistrationEnabled];
    [self.undoManager disableUndoRegistration];
    [self removeEntry:entry];
    [toGroup addEntry:entry atIndex:index];
    if(wasEnabled) {
      [self.undoManager enableUndoRegistration];
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
  return [NSString stringWithFormat:@"%@ [image=%ld, name=%@, %@]",
          [self class],
          self.icon,
          self.name,
          self.timeInfo];
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


- (BOOL)isAnchestorOfGroup:(KPKGroup *)group {
  if(group == nil) {
    return NO;
  }
  KPKGroup *ancestor = group.parent;
  while(ancestor) {
    if(ancestor == self) {
      return YES;
    }
    ancestor = ancestor.parent;
  }
  return NO;
}

- (void)clear {
  NSUInteger groupCount = [_groups count];
  for(NSInteger index = (groupCount - 1); index > -1; index--) {
    [self removeObjectFromGroupsAtIndex:index];
  }
  NSUInteger entryCount = [_entries count];
  for(NSInteger index = (entryCount - 1); index > -1; index--) {
    [self removeObjectFromEntriesAtIndex:index];
  }
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

