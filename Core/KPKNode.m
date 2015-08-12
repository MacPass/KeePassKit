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
#import "KPKEntry.h"
#import "KPKGroup.h"
#import "KPKIconTypes.h"
#import "KPKTimeInfo.h"
#import "KPKTree.h"
#import "KPKMetaData.h"

#import "NSUUID+KeePassKit.h"

@implementation KPKNode

@dynamic notes;
@dynamic title;

+ (BOOL)supportsSecureCoding {
  return YES;
}

+ (NSUInteger)defaultIcon {
  return KPKIconPassword;
}

- (id)init {
  self = [super init];
  if (self) {
    _uuid = [[NSUUID alloc] init];
    _minimumVersion = KPKLegacyVersion;
    _timeInfo = [[KPKTimeInfo alloc] init];
    _iconId = [[self class] defaultIcon];
    _deleted = NO;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [self init];
  if(self) {
    _uuid = [aDecoder decodeObjectOfClass:[NSUUID class] forKey:NSStringFromSelector(@selector(uuid))];
    _minimumVersion = (KPKVersion) [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(minimumVersion))];
    _iconId = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(iconId))];
    _iconUUID = [aDecoder decodeObjectOfClass:[NSUUID class] forKey:NSStringFromSelector(@selector(iconUUID))];
    /* decode time info at last */
    _timeInfo = [aDecoder decodeObjectOfClass:[KPKTimeInfo class] forKey:NSStringFromSelector(@selector(timeInfo))];
    _deleted = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(deleted))];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.timeInfo forKey:NSStringFromSelector(@selector(timeInfo))];
  [aCoder encodeObject:self.uuid forKey:NSStringFromSelector(@selector(uuid))];
  [aCoder encodeInteger:self.minimumVersion forKey:NSStringFromSelector(@selector(minimumVersion))];
  [aCoder encodeInteger:self.iconId forKey:NSStringFromSelector(@selector(iconId))];
  [aCoder encodeObject:self.iconUUID forKey:NSStringFromSelector(@selector(iconUUID))];
  [aCoder encodeBool:self.deleted forKey:NSStringFromSelector(@selector(deleted))];
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
  BOOL isEqual = [_timeInfo isEqual:aNode->_timeInfo]
  && (_iconId == aNode->_iconId)
  && [_iconUUID isEqual:aNode->_iconUUID]
  && [self.title isEqual:aNode.title]
  && [self.notes isEqual:aNode.notes];
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
  return [self asGroup].uuid == self.tree.metaData.trashUuid;
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

- (void)updateToNode:(KPKNode *)node {
  if(!node) {
    return; // Nothing to do!
  }
  NSAssert([node asGroup] || [node asEntry], @"Cannot update to abstract KPKNode class");
  /* UUID should be the same */
  if(![self.uuid isEqualTo:node.uuid]) {
    NSAssert(NO, @"Nodes should never update to differen UUIDs!");
    return;
  }
  KPKNode *copy = [self copy];
  [[self.undoManager prepareWithInvocationTarget:self] updateToNode:copy];
  /* Do not update parent/child structure, we just want "content" to update */
  self.iconId = node.iconId;
  self.minimumVersion = node.minimumVersion;
  self.timeInfo = node.timeInfo;
  self.iconUUID = node.iconUUID;
  /* Update the Timing! */
  [self wasModified];
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
    [[self asEntry] moveToGroup:trash];
    [[self asGroup] moveToGroup:trash];
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

@end
