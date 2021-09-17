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
#import "KPKNode_Private.h"
#import "KPKDeletedNode.h"
#import "KPKEntry.h"
#import "KPKGroup.h"
#import "KPKGroup_Private.h"
#import "KPKIconTypes.h"
#import "KPKTimeInfo.h"
#import "KPKTimeInfo_Private.h"
#import "KPKTree.h"
#import "KPKTree_Private.h"
#import "KPKMetaData.h"

#import "KPKPair.h"
#import "KPKScopedSet.h"
#import "NSUUID+KPKAdditions.h"

@implementation KPKNode

@dynamic notes;
@dynamic title;
@dynamic minimumVersion;
@dynamic updateTiming;
@dynamic customData;

@synthesize tree = _tree;

+ (NSUInteger)defaultIcon {
  return KPKIconPassword;
}

+ (NSSet *)keyPathsForValuesAffectingHasDefaultIcon {
  return [NSSet setWithArray:@[ NSStringFromSelector(@selector(iconUUID)), NSStringFromSelector(@selector(iconId)) ]];
}

+ (NSSet *)keyPathsForValuesAffectingIcon {
  return [NSSet setWithArray:@[NSStringFromSelector(@selector(iconUUID)), NSStringFromSelector(@selector(tree))]];
}

+ (NSSet *)keyPathsForValuesAffectingTree {
  return [NSSet setWithObject:NSStringFromSelector(@selector(parent))];
}

+ (NSSet *)keyPathsForValuesAffectingParentGroup {
  return [NSSet setWithObject:NSStringFromSelector(@selector(parent))];
}

+ (NSSet *)keyPathsForValuesAffectingCustomData {
  return [NSSet setWithObject:NSStringFromSelector(@selector(mutableCustomData))];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingIndex {
  if(self.class == KPKNode.class) {
    return [NSSet setWithObject:NSStringFromSelector(@selector(parent))];
  }
  return [self.class keyPathsForValuesAffectingIndex];
}

- (instancetype)init {
  [self doesNotRecognizeSelector:_cmd];
  self = nil;
  return nil;
}

- (instancetype)initWithUUID:(NSUUID *)uuid {
  [self doesNotRecognizeSelector:_cmd];
  self = nil;
  return self;
}

- (instancetype)copyWithTitle:(NSString *)titleOrNil options:(KPKCopyOptions)options {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (KPKComparsionResult)compareToNode:(KPKNode *)aNode {
  return [self _compareToNode:aNode options:0];
}

- (KPKComparsionResult)_compareToNode:(KPKNode *)aNode options:(KPKNodeCompareOptions)options {
  /* pointing to the same instance */
  if(self == aNode) {
    return KPKComparsionEqual;
  }
  
  /* We do not compare UUIDs as those are supposed to be different for nodes unless they are encoded/decoded */
  NSAssert([aNode isKindOfClass:KPKNode.class], @"Unsupported type for quality test");
  
  /* if UUIDs dont's match, nodes aren't considered equal! */
  if(!(options & KPKNodeCompareOptionIgnoreUUID)) {
    if(![self.uuid isEqual:aNode.uuid]) {
      return KPKComparsionDifferent;
    }
  }
  
  if(!(options & KPKNodeCompareOptionIgnoreAccessDate)) {
    NSComparisonResult result = [self.timeInfo.accessDate compare:aNode.timeInfo.accessDate];
    if(result != NSOrderedSame) {
      return KPKComparsionDifferent;
    }
  }
  if(!(options & KPKNodeCompareOptionIgnoreModificationDate)) {
    NSComparisonResult result = [self.timeInfo.modificationDate compare:aNode.timeInfo.modificationDate];
    if(result != NSOrderedSame) {
      return KPKComparsionDifferent;
    }
  }
  
  if(self.tags.count != aNode.tags.count) {
    // FIXME: Tag order should not matter!
    if(![self.tags isEqualToArray:aNode.tags]) {
      return KPKComparsionDifferent;
    }
  }
  
  if(![self.mutableCustomData isEqualToDictionary:aNode.mutableCustomData]) {
    return KPKComparsionDifferent;
  }
  
  BOOL isEqual = (_iconId == aNode->_iconId)
  && (_iconUUID == aNode.iconUUID || [_iconUUID isEqual:aNode->_iconUUID])
  && (self.title == aNode.title || [self.title isEqual:aNode.title])
  && (self.notes == aNode.notes || [self.notes isEqual:aNode.notes]);
  return (isEqual ? KPKComparsionEqual : KPKComparsionDifferent);
}

- (NSString*)description {
  return [NSString stringWithFormat:@"{%@, image=%ld, title=%@, parent=%@}", self.class, self.iconId, self.title, self.parent.title];
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
  return (self.iconId == [self.class defaultIcon]);
}

- (KPKIcon *)icon {
  return [self.tree.metaData findIcon:self.iconUUID];
}

- (NSUInteger)index {
  if(self.parent) {
    return [self.parent _indexForNode:self];
  }
  return 0;
}

- (BOOL)isTrash {
  return [self.asGroup.uuid isEqual:self.tree.metaData.trashUuid];
}

- (BOOL)isUserTemplateGroup {
  return [self.asGroup.uuid isEqual:self.tree.metaData.entryTemplatesGroupUuid];
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

- (NSDictionary<NSString *,NSString *> *)customData {
  return [self.mutableCustomData copy];
}

- (KPKGroup *)rootGroup {
  if(!self.parent) {
    return self.asGroup;
  }
  return self.parent.rootGroup;
}

- (BOOL)isAnchestorOf:(KPKNode *)node {
  if(!node) {
    return NO;
  }
  if(self == node) {
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
  [[self.undoManager prepareWithInvocationTarget:self] setIconId:self.iconId];
  [self touchModified];
  _iconId = iconId;
}

- (void)setIconUUID:(NSUUID *)iconUUID {
  [[self.undoManager prepareWithInvocationTarget:self] setIconUUID:self.iconUUID];
  [self touchModified];
  _iconUUID = iconUUID;
}

- (void)setTimeInfo:(KPKTimeInfo *)timeInfo {
  if(self.timeInfo != timeInfo) {
    _timeInfo = [timeInfo copy];
    _timeInfo.node = self;
  }
}

- (void)setTags:(NSArray<NSString *> *)tags {
  [[self.undoManager prepareWithInvocationTarget:self] setTags:self.tags];
  [self.undoManager setActionName:NSLocalizedStringFromTableInBundle(@"SET_TAGS", nil, [NSBundle bundleForClass:self.class], @"Action name for setting the tags of an enty")];
  [self.tree _unregisterTags:_tags];
  
  tags = [[NSSet setWithArray:tags].allObjects sortedArrayUsingSelector:@selector(compare:)];
 
  _tags = tags ? [[NSArray alloc] initWithArray:tags copyItems:YES] : nil;
  [self.tree _registerTags:_tags];
}

- (NSString *)breadcrumb {
  return [self breadcrumbWithSeparator:@"."];
}

- (NSString *)breadcrumbWithSeparator:(NSString *)separator {
  if(self.parent) {
    return [[self.parent breadcrumbWithSeparator:separator] stringByAppendingFormat:@"%@%@", separator, self.title];
  }
  return self.title;
}

- (NSIndexPath *)indexPath {
  if(self.parent) {
    NSUInteger myIndex = self.asGroup ? [self.parent.mutableGroups indexOfObjectIdenticalTo:self.asGroup] : [self.parent.mutableEntries indexOfObjectIdenticalTo:self.asEntry];
    NSIndexPath *parentIndexPath = [self.parent indexPath];
    NSAssert( nil != parentIndexPath, @"existing parents should always yield a indexPath");
    return [parentIndexPath indexPathByAddingIndex:myIndex];
  }
  NSUInteger indexes[] = {0,0};
  return [[NSIndexPath alloc] initWithIndexes:indexes length:(sizeof(indexes)/sizeof(NSUInteger))];
}

#pragma mark KPKTimerecording
- (void)setUpdateTiming:(BOOL)updateTiming {
  self.timeInfo.updateTiming = updateTiming;
}

- (BOOL)updateTiming {
  return self.timeInfo.updateTiming;
}

- (void)touchModified {
  [self.timeInfo touchModified];
}

- (void)touchAccessed {
  [self.timeInfo touchAccessed];
}

- (void)touchMoved {
  [self.timeInfo touchMoved];
}

- (void)trashOrRemove {
  /* If we do create a trash group we should also remove it after a undo operation */
  if(self == self.tree.trash) {
    return; // Prevent recursive trashing of trash group
  }
  if(self.tree.metaData.useTrash) {
    [self.undoManager beginUndoGrouping];
  }
  KPKGroup *trash = [self.tree createTrash];
  NSAssert(self.tree.trash == trash, @"Trash should be nil or equal");
  if(trash) {
    [self moveToGroup:trash];
  }
  else {
    [self remove];
  }
  if(trash) {
    [self.undoManager endUndoGrouping];
  }
}

- (void)remove {
  for(KPKGroup *group in self.asGroup.mutableGroups.reverseObjectEnumerator) {
    [group remove];
  }
  for(KPKEntry *entry in self.asGroup.mutableEntries.reverseObjectEnumerator) {
    [entry remove];
  }
  [[self.undoManager prepareWithInvocationTarget:self] addToGroup:self.parent atIndex:self.index];
  if(nil != self.tree.mutableDeletedObjects[self.uuid]) {
    NSLog(@"Internal inconsitency: Node %@ already registered as deleted!", self);
  }
  self.tree.mutableDeletedObjects[self.uuid] = [[KPKDeletedNode alloc] initWithUUID:self.uuid];
  /* keep a strong reference for undo support in the tree */
  if(nil != self.tree.mutableDeletedNodes[self.uuid]) {
    NSLog(@"Internal inconsintency: Node %@ is already deleted!", self);
  }
  self.tree.mutableDeletedNodes[self.uuid] = self;
  [self.parent _removeChild:self];
}

- (void)moveToGroup:(KPKGroup *)group {
  [self moveToGroup:group atIndex:NSNotFound];
}

- (void)moveToGroup:(KPKGroup *)group atIndex:(NSUInteger)index {
  /* TODO handle moving accross trees! */
  if(self.tree && group.tree) {
    NSAssert(self.tree == group.tree, @"Moving nodes between trees is not supported. Use -remove and -addToGroup: instead.");
  }
  if(self.parent == group && self.index == index) {
    return; // no need to move, we're where we want to be
  }
  [[self.undoManager prepareWithInvocationTarget:self] moveToGroup:self.parent atIndex:self.index];
  self.previousParent = self.parent.uuid;
  [self.parent _removeChild:self];
  [group _addChild:self atIndex:index];
  [self touchMoved];
}

- (void)addToGroup:(KPKGroup *)group {
  [self addToGroup:group atIndex:NSNotFound];
}

- (void)addToGroup:(KPKGroup *)group atIndex:(NSUInteger)index {
  /* setup parent relationship to make undo possible */
  NSAssert(self.parent == nil, @"Added nodes cannot have a parent. Please use -moveToGroup:atIndex: and moveToGroup: instead");
  self.parent = group;
  [[self.undoManager prepareWithInvocationTarget:self] remove];
  [group _addChild:self atIndex:index];
  /* remove deleted object if we undo a remove */
  self.tree.mutableDeletedObjects[self.uuid] = nil;
  /* clean node store since we now have a strong ref again */
  self.tree.mutableDeletedNodes[self.uuid] = nil;
  [self touchMoved];
}

- (KPKGroup *)asGroup {
  return nil;
}

- (KPKEntry *)asEntry {
  return nil;
}

- (BOOL)_updateFromNode:(KPKNode *)node options:(KPKUpdateOptions)options {
  NSComparisonResult result = [self.timeInfo.modificationDate compare:node.timeInfo.modificationDate];
  if(result == NSOrderedAscending || (options & KPKUpdateOptionIgnoreModificationTime)) {
    KPK_SCOPED_NO_BEGIN(self.updateTiming)
    self.iconId = node.iconId;
    self.iconUUID = node.iconUUID;
    self.title = node.title;
    self.notes = node.notes;
    self.mutableCustomData = [[NSMutableDictionary alloc] initWithDictionary:node.mutableCustomData copyItems:YES];
    KPK_SCOPED_NO_END(self.updateTiming)
    return YES;
  }
  return NO;
}

- (void)removeCustomDataForKey:(NSString *)key {
  if(!key) {
    return;
  }
  NSString *value = self.mutableCustomData[key];
  if(!value) {
    return;
  }
  [[self.undoManager prepareWithInvocationTarget:self] setCustomData:value forKey:key];
  [self removeCustomDataObject:[KPKPair pairWithKey:key value:value]];
}

- (void)setCustomData:(NSString *)value forKey:(NSString *)key {
  if(key && value) {
    [[self.undoManager prepareWithInvocationTarget:self] removeCustomDataForKey:key];
    [self addCustomDataObject:[KPKPair pairWithKey:key value:value]];
  }
}

- (void)clearCustomData {
  for(NSString *key in self.mutableCustomData) {
    [[self.undoManager prepareWithInvocationTarget:self] setCustomData:self.mutableCustomData[key] forKey:key];
  }
  
  NSMutableSet *pairs = [[NSMutableSet alloc] initWithCapacity:self.mutableCustomData.count];
  for(NSString *key in self.mutableCustomData) {
    [pairs addObject:[KPKPair pairWithKey:key value:self.mutableCustomData[key]]];
  }
  [self removeCustomData:pairs];
}

#pragma mark -
#pragma mark KVO


#pragma mark -
#pragma mark Private Extensions
- (instancetype)_init {
  self = [self _initWithUUID:nil];
  return self;
}

- (instancetype)_initWithUUID:(NSUUID *)uuid {
  self = [super init];
  if (self) {
    _uuid = uuid ? [uuid copy] : [[[NSUUID alloc] init] copy];
    self.timeInfo = [[KPKTimeInfo alloc] init];
    _iconId = self.class.defaultIcon;
    _mutableCustomData = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (instancetype)_initWithCoder:(NSCoder *)aDecoder {
  self = [self _init];
  if(self) {
    _uuid = [[aDecoder decodeObjectOfClass:NSUUID.class forKey:NSStringFromSelector(@selector(uuid))] copy];
    _iconId = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(iconId))];
    _iconUUID = [[aDecoder decodeObjectOfClass:NSUUID.class forKey:NSStringFromSelector(@selector(iconUUID))] copy];
    _tags = [[aDecoder decodeObjectOfClass:NSArray.class forKey:NSStringFromSelector(@selector(tags))] copy];
    _mutableCustomData = [aDecoder decodeObjectOfClass:NSMutableDictionary.class forKey:NSStringFromSelector(@selector(mutableCustomData))];
    _previousParent = [aDecoder decodeObjectOfClass:NSUUID.class forKey:NSStringFromSelector(@selector(previousParent))];
    /* decode time info at last */
    self.timeInfo = [aDecoder decodeObjectOfClass:KPKTimeInfo.class forKey:NSStringFromSelector(@selector(timeInfo))];
    
  }
  return self;
}

- (void)_encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.timeInfo forKey:NSStringFromSelector(@selector(timeInfo))];
  [aCoder encodeObject:self.uuid forKey:NSStringFromSelector(@selector(uuid))];
  [aCoder encodeInteger:self.iconId forKey:NSStringFromSelector(@selector(iconId))];
  [aCoder encodeObject:self.iconUUID forKey:NSStringFromSelector(@selector(iconUUID))];
  [aCoder encodeObject:_tags forKey:NSStringFromSelector(@selector(tags))];
  [aCoder encodeObject:self.previousParent forKey:NSStringFromSelector(@selector(previousParent))];
  [aCoder encodeObject:self.mutableCustomData forKey:NSStringFromSelector(@selector(mutableCustomData))];
}

- (instancetype)_copyWithUUID:(NSUUID *)uuid {
  KPKNode *copy = [[self.class alloc] _initWithUUID:uuid];
  KPK_SCOPED_NO_BEGIN(copy.updateTiming);
  copy.iconId = self.iconId;
  copy.iconUUID = self.iconUUID;
  copy.notes = self.notes;
  copy.title = self.title;
  copy.timeInfo = self.timeInfo;
  copy.mutableCustomData = [[NSMutableDictionary alloc] initWithDictionary:self.mutableCustomData copyItems:YES];
  copy.tags = self.tags;
  copy.previousParent = self.previousParent;
  KPK_SCOPED_NO_END(copy.updateTiming);
  return copy;
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
  /* TODO update tags! */
  _tree = tree;
}

- (void)_regenerateUUIDs {
  _uuid = [[[NSUUID alloc] init] copy];
}

- (void)_traverseNodesWithOptions:(KPKNodeTraversalOptions)options block:(void (^)(KPKNode *, BOOL *))block {
  [self doesNotRecognizeSelector:_cmd];
}

- (void)_traverseNodesWithBlock:(void (^)(KPKNode *, BOOL *))block {
  [self _traverseNodesWithOptions:0 block:block];
}

- (void)addCustomDataObject:(KPKPair *)pair {
  NSAssert(pair.key, @"Custom data key cannot be nil!");
  NSAssert(pair.value, @"Custom data value cannot be nil!");
  self.mutableCustomData[pair.key] = pair.value;
  [self touchModified];
}

- (void)removeCustomDataObject:(KPKPair *)pair {
  [self removeCustomData:[NSSet setWithObject:pair]];
}

- (void)removeCustomData:(NSSet *)setOfPairs {
  for(KPKPair *pair in setOfPairs) {
    NSAssert(pair.key, @"Custom data object key cannot be nil!");
    NSString *value = self.mutableCustomData[pair.key];
    if(![value isEqualToString:pair.value]) {
      NSLog(@"Warning. Expected value for key is %@, but actual value is: %@", pair.value, value);
    }
    self.mutableCustomData[pair.key] = nil;
    [self touchModified];
  }
}

@end
