//
//  KPKNode.m
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


#import "KPKNode.h"
#import "KPKNode+Private.h"
#import "KPKEntry.h"
#import "KPKEditingSession.h"
#import "KPKEditingSession+Private.h"
#import "KPKGroup.h"
#import "KPKIconTypes.h"
#import "KPKTimeInfo.h"
#import "KPKTree.h"
#import "KPKTree+Private.h"
#import "KPKMetaData.h"

#import "NSUUID+KeePassKit.h"

@implementation KPKNode {
  BOOL _deleted;
  KPKTree *_tree;
}

@synthesize deleted = _deleted;
@dynamic notes;
@dynamic title;
@dynamic minimumVersion;

+ (NSUInteger)defaultIcon {
  return KPKIconPassword;
}

+ (NSSet *)keyPathsForValuesAffectingTree {
  return [NSSet setWithObject:NSStringFromSelector(@selector(parent))];
}

+ (NSSet *)keyPathsForValuesAffectingParentGroup {
  return [NSSet setWithObject:NSStringFromSelector(@selector(parent))];
}

- (instancetype)init {
  return [self initWithUUID:nil];
}

- (instancetype)initWithUUID:(NSUUID *)uuid {
  NSAssert(NO,@"KPKNode cannot be directly initalized");
  self = nil;
  return self;
}

- (instancetype)copyWithTitle:(NSString *)titleOrNil options:(KPKCopyOptions)options {
  /* not implemented */
  NSAssert(NO, @"Unable to call %@ on %@", NSStringFromSelector(_cmd), NSStringFromClass([self class]));
  return nil;
}

- (BOOL)isEqual:(id)object {
  if(![self isKindOfClass:[KPKNode class]]) {
    return NO;
  }
  return [self isEqualToNode:object];
}

- (BOOL)isEqualToNode:(KPKNode *)aNode {
  /* pointing to the same instance */
  if(nil != self && self == aNode) {
    return YES;
  }
  /* We do not compare UUIDs as those are supposed to be different for nodes unless they are encoded/decoded */
  NSAssert([aNode isKindOfClass:[KPKNode class]], @"Unsupported type for quality test");
  //BOOL isEqual = [_timeInfo isEqual:aNode->_timeInfo]
  BOOL isEqual = (_iconId == aNode->_iconId)
  && (_iconUUID == aNode.iconUUID || [_iconUUID isEqual:aNode->_iconUUID])
  && (self.title == aNode.title || [self.title isEqual:aNode.title])
  && (self.notes == aNode.notes || [self.notes isEqual:aNode.notes]);
  return isEqual;
}

#pragma mark Properties
- (BOOL)isEditable {
  if(self.tree) {
    return self.tree.isEditable;
  }
  return YES;
}

- (BOOL)hasDefaultIcon {
  /* if we have a custom icon, we are certainly not default */
  if(self.iconUUID) {
    return NO;
  }
  return (self.iconId == [[self class] defaultIcon]);
}

- (BOOL)isTrash {
  return self.asGroup.uuid == self.tree.metaData.trashUuid;
}

- (BOOL)isTrashed {
  if(self.isTrash) {
    return NO; // Trash is not trashed
  }
  return [self.tree.trash isAnchestorOf:self];
}

- (KPKGroup *)rootGroup {
  KPKGroup *rootGroup = self.parent;
  while(rootGroup) {
    rootGroup = rootGroup.parent;
  }
  return rootGroup;
}

- (BOOL)isAnchestorOf:(KPKNode *)node {
  if(nil == node) {
    return NO;
  }
  KPKNode *ancestor = node.parent;
  while(ancestor) {
    if(ancestor == self) {
      return YES;
    }
    ancestor = ancestor.parent;
  }
  return NO;
}

- (BOOL)isDecendantOf:(KPKNode *)node {
  return [node isAnchestorOf:self];
}

- (NSUndoManager *)undoManager {
  return self.tree.undoManager;
}

#pragma mark KPKTimerecording
- (void)setUpdateTiming:(BOOL)updateTiming {
  self.timeInfo.updateTiming = updateTiming;
}

- (BOOL)updateTiming {
  return self.timeInfo.updateTiming;
}

- (void)wasModified {
  [self.timeInfo wasModified];
}

- (void)wasAccessed {
  [self.timeInfo wasAccessed];
}

- (void)wasMoved {
  [self.timeInfo wasMoved];
}

- (void)trashOrRemove {
  /* If we do create a trahs group we should also remove it after a undo operation */
  if(self == self.tree.trash) {
    return; // Prevent recursive trashing of trash group
  }
  [self.undoManager beginUndoGrouping];
  KPKGroup *trash = [self.tree createTrash];
  NSAssert(self.tree.trash == trash, @"Trash should be nil or equal");
  if(trash) {
    [self.asEntry moveToGroup:trash];
    [self.asGroup moveToGroup:trash];
  }
  else {
    [self remove];
  }
  [self.undoManager endUndoGrouping];
}

- (void)remove {
  /* not implemented */
  NSAssert(NO, @"Unable to call %@ on %@", NSStringFromSelector(_cmd), NSStringFromClass([self class]));
}

- (KPKGroup *)asGroup {
  return nil;
}

- (KPKEntry *)asEntry {
  return nil;
}

#pragma mark -
#pragma mark Private Extensions
- (instancetype)_init {
  self = [super init];
  if (self) {
    _uuid = [[NSUUID alloc] init];
    _timeInfo = [[KPKTimeInfo alloc] init];
    _iconId = [[self class] defaultIcon];
    _deleted = NO;
  }
  return self;
}

- (instancetype)_initWithUUID:(NSUUID *)uuid {
  self = [self _init];
  if(self && uuid) {
    _uuid = uuid;
  }
  return self;
}

- (instancetype)_initWithCoder:(NSCoder *)aDecoder {
  self = [self _init];
  if(self) {
    _uuid = [aDecoder decodeObjectOfClass:[NSUUID class] forKey:NSStringFromSelector(@selector(uuid))];
    _iconId = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(iconId))];
    _iconUUID = [aDecoder decodeObjectOfClass:[NSUUID class] forKey:NSStringFromSelector(@selector(iconUUID))];
    /* decode time info at last */
    _timeInfo = [aDecoder decodeObjectOfClass:[KPKTimeInfo class] forKey:NSStringFromSelector(@selector(timeInfo))];
    _deleted = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(deleted))];
  }
  return self;
}

- (void)_encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.timeInfo forKey:NSStringFromSelector(@selector(timeInfo))];
  [aCoder encodeObject:self.uuid forKey:NSStringFromSelector(@selector(uuid))];
  [aCoder encodeInteger:self.minimumVersion forKey:NSStringFromSelector(@selector(minimumVersion))];
  [aCoder encodeInteger:self.iconId forKey:NSStringFromSelector(@selector(iconId))];
  [aCoder encodeObject:self.iconUUID forKey:NSStringFromSelector(@selector(iconUUID))];
  [aCoder encodeBool:self.deleted forKey:NSStringFromSelector(@selector(deleted))];
}

- (void)_copyDataFromNode:(KPKNode *)node {
  /* As subclasses might call us, use dynamic resolving! */
  self.iconId = node.iconId;
  self.iconUUID = node.iconUUID;
  self.timeInfo = node.timeInfo;
  self.deleted = node.deleted;
  self.parent = node.parent;
  self.notes = node.notes;
  self.title = node.title;
}

- (instancetype)_copyWithUUUD:(NSUUID *)uuid {
  // nothing to do here!
  return nil;
}

# pragma mark Editing
- (KPKEditingSession *)beginEditing {
  self.editingSession = [KPKEditingSession _editingSessionWithSource:self];
  return self.editingSession;
}

- (BOOL)cancelEditing {
  BOOL hasChanges = self.editingSession.hasChanges;
  self.editingSession = nil;
  return hasChanges;
}

- (BOOL)commitEditing {
  BOOL hasChanges = self.editingSession.hasChanges;
  if(!hasChanges) {
    NSAssert(self == self.editingSession.source, @"Source of editing sessiong needs to be self!");
    [self _revertToNode:self.editingSession.node];
  }
  self.editingSession = nil;
  return hasChanges;
}

- (void)_revertToNode:(KPKNode *)node {
  if(!node) {
    return; // Nothing to do!
  }
  /* UUID should be the same */
  NSAssert([self.uuid isEqual:node], @"Cannot update to node with differen UUID");
  
  NSAssert(node.asGroup || node.asEntry, @"Cannot update to abstract KPKNode class");
  NSAssert(node.asGroup == self.asGroup && node.asEntry == self.asEntry, @"Cannot update accross types");
  [[self.undoManager prepareWithInvocationTarget:self] _revertToNode:[self _copyWithUUUD:self.uuid]];
  /* Do not update parent/child structure, we just want "content" to update */
  self.iconId = node.iconId;
  self.timeInfo = node.timeInfo;
  self.iconUUID = node.iconUUID;
  /* Update the Timing! */
  [self wasModified];
}

- (KPKTree *)tree {
  if(self.parent) {
    return self.parent.tree;
  }
  return _tree;
}

- (void)setTree:(KPKTree *)tree {
  if(self.parent) {
    _tree = nil;
    return;
  }
  _tree = tree;
}

@end
