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
#import "KPKGroup.h"
#import "KPKGroup+Private.h"
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

//@synthesize deleted = _deleted;
@dynamic notes;
@dynamic title;
@dynamic minimumVersion;
@dynamic updateTiming;

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
  NSAssert(NO, @"Unable to call %@ on %@", NSStringFromSelector(_cmd), NSStringFromClass([self class]));
  self = nil;
  return nil;
}

- (instancetype)initWithUUID:(NSUUID *)uuid {
  NSAssert(NO, @"Unable to call %@ on %@", NSStringFromSelector(_cmd), NSStringFromClass([self class]));
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
  BOOL editable = YES;
  if(self.tree) {
    editable &= self.tree.isEditable;
  }
  /* we allow only to be edited when we've got no pending edits */
  return ( !self.rollbackNode);
}

- (BOOL)hasDefaultIcon {
  /* if we have a custom icon, we are certainly not default */
  if(self.iconUUID) {
    return NO;
  }
  return (self.iconId == [[self class] defaultIcon]);
}

- (BOOL)isTrash {
  return [self.asGroup.uuid isEqual:self.tree.metaData.trashUuid];
}

- (BOOL)isUserTemplateGroup {
  return [self.asGroup.uuid isEqual:self.tree.metaData.entryTemplatesGroup];
}

- (BOOL)isUserTemplate {
  return [self isDecendantOf:self.tree.templates];
}

- (BOOL)isTrashed {
  if(self.isTrash) {
    return NO; // Trash is not trashed
  }
  return [self.tree.trash isAnchestorOf:self];
}

- (KPKGroup *)rootGroup {
  KPKGroup *rootGroup = self.parent;
  if(!rootGroup) {
    return self.asGroup;
  }
  while(rootGroup.parent) {
    rootGroup = rootGroup.parent;
  }
  return rootGroup;
}

- (BOOL)isAnchestorOf:(KPKNode *)node {
  if(!node) {
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

- (void)setIconId:(NSInteger)iconId {
  _iconId = iconId;
  [self wasModified];
}

- (void)setIconUUID:(NSUUID *)iconUUID {
  _iconUUID = iconUUID;
  [self wasModified];
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
  //[self.undoManager beginUndoGrouping];
  KPKGroup *trash = [self.tree createTrash];
  NSAssert(self.tree.trash == trash, @"Trash should be nil or equal");
  if(trash) {
    [self moveToGroup:trash];
  }
  else {
    [self remove];
  }
  //[self.undoManager endUndoGrouping];
}

- (void)remove {
  [[self.undoManager prepareWithInvocationTarget:self] addToGroup:self.parent atIndex:[self.parent _indexForNode:self]];
  //self.deleted = YES;
  NSAssert(nil == self.tree.deletedObjects[self.uuid], @"Node already registered as deleted!");
  self.tree.mutableDeletedObjects[self.uuid] = [[KPKDeletedNode alloc] initWithNode:self];
  [self.parent _removeChild:self];
}

- (void)moveToGroup:(KPKGroup *)group {
  [self moveToGroup:group atIndex:NSNotFound];
}

- (void)moveToGroup:(KPKGroup *)group atIndex:(NSUInteger)index {
  [[group.undoManager prepareWithInvocationTarget:self] moveToGroup:self.parent atIndex:[self.parent _indexForNode:self]];
  [self.parent _removeChild:self];
  [group _addChild:self atIndex:index];
  [self wasMoved];
}

- (void)addToGroup:(KPKGroup *)group {
  [self addToGroup:group atIndex:[self.parent _indexForNode:self]];
}

- (void)addToGroup:(KPKGroup *)group atIndex:(NSUInteger)index {
  /* new items do not have an undomanager, so we have to use the group */
  [[group.undoManager prepareWithInvocationTarget:self] remove];
  [group _addChild:self atIndex:index];
  self.tree.mutableDeletedObjects[self.uuid] = nil;
  [self wasMoved];
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
  self = [self _initWithUUID:nil];
  return self;
}

- (instancetype)_initWithUUID:(NSUUID *)uuid {
  self = [super init];
  if (self) {
    _uuid = uuid ? uuid : [[NSUUID alloc] init];
    _timeInfo = [[KPKTimeInfo alloc] init];
    _iconId = [[self class] defaultIcon];
    _deleted = NO;
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
  }
  return self;
}

- (void)_encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.timeInfo forKey:NSStringFromSelector(@selector(timeInfo))];
  [aCoder encodeObject:self.uuid forKey:NSStringFromSelector(@selector(uuid))];
  [aCoder encodeInteger:self.minimumVersion forKey:NSStringFromSelector(@selector(minimumVersion))];
  [aCoder encodeInteger:self.iconId forKey:NSStringFromSelector(@selector(iconId))];
  [aCoder encodeObject:self.iconUUID forKey:NSStringFromSelector(@selector(iconUUID))];
}

- (instancetype)_copyWithUUUD:(NSUUID *)uuid {
  return [self _shallowCopyWithUUID:uuid];
}

- (instancetype)_shallowCopyWithUUID:(NSUUID *)uuid {
  KPKNode *copy = [[[self class] alloc] _initWithUUID:uuid];
  copy.iconId = self.iconId;
  copy.iconUUID = self.iconUUID;
  copy.parent = self.parent;
  copy.notes = self.notes;
  copy.title = self.title;
  copy.timeInfo = self.timeInfo;
  return copy;
}

# pragma mark Editing
- (void)beginEditing {
  self.rollbackNode = [self _shallowCopyWithUUID:self.uuid];
}

- (BOOL)cancelEditing {
  [self _updateToNode:self.rollbackNode];
  self.rollbackNode = nil;
  return YES;
}

- (BOOL)commitEditing {
  self.rollbackNode = nil;
  return YES;
}

- (void)_updateToNode:(KPKNode *)node {
  if(!node) {
    return; // Nothing to do!
  }
  /* UUID should be the same */
  NSAssert([self.uuid isEqual:node], @"Cannot update to node with differen UUID");
  
  NSAssert(node.asGroup || node.asEntry, @"Cannot update to abstract KPKNode class");
  NSAssert(node.asGroup == self.asGroup && node.asEntry == self.asEntry, @"Cannot update accross types");
  
  //if(node.asGroup) {
    [[self.undoManager prepareWithInvocationTarget:self] _updateToNode:[self _shallowCopyWithUUID:self.uuid]];
  //}
  /* Do not update parent/child structure, we just want "content" to update */
  self.iconId = node.iconId;
  self.iconUUID = node.iconUUID;
  self.title = node.title;
  self.notes = node.notes;
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