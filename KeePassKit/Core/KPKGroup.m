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
#import "KPKGroup_Private.h"
#import "KPKNode_Private.h"

#import "KPKAutotype.h"
#import "KPKDeletedNode.h"
#import "KPKEntry.h"
#import "KPKEntry_Private.h"
#import "KPKIconTypes.h"
#import "KPKMetaData.h"
#import "KPKScopedSet.h"
#import "KPKTree.h"
#import "KPKTree_Private.h"
#import "KPKTimeInfo.h"
#import "KPKUTIs.h"
#import "KPKFormat.h"

#import "NSUUID+KPKAdditions.h"

NSString *const KPKEntriesArrayBinding = @"entriesArray";
NSString *const KPKGroupsArrayBinding = @"groupsArray";

@implementation KPKGroup

static NSSet *_observedKeyPathsSet;

@dynamic updateTiming;
@dynamic entries;
@dynamic groups;

@synthesize defaultAutoTypeSequence = _defaultAutoTypeSequence;
@synthesize title = _title;
@synthesize notes = _notes;

+ (BOOL)supportsSecureCoding {
  return YES;
}

+ (NSSet *)keyPathsForValuesAffectingChildren {
  return [NSSet setWithArray:@[NSStringFromSelector(@selector(mutableGroups)), NSStringFromSelector(@selector(mutableEntries)) ]];
}

+ (NSSet *)keyPathsForValuesAffectingChildEntries {
  return [NSSet setWithObject:NSStringFromSelector(@selector(mutableEntries))];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingGroups {
  return [NSSet setWithObject:NSStringFromSelector(@selector(mutableGroups))];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingEntries {
  return [NSSet setWithObject:NSStringFromSelector(@selector(mutableEntries))];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingGroupsArray {
  return [NSSet setWithObject:NSStringFromSelector(@selector(mutableGroups))];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingEntriesArray {
  return [NSSet setWithObject:NSStringFromSelector(@selector(mutableEntries))];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingIndex {
  return [NSSet setWithArray:@[NSStringFromSelector(@selector(parent)), [NSString stringWithFormat:@"%@.%@",NSStringFromSelector(@selector(parent)), NSStringFromSelector(@selector(mutableGroups))]]];
}


+ (NSUInteger)defaultIcon {
  return KPKIconFolder;
}

- (instancetype)init {
  self = [self _init];
  return self;
}

- (instancetype)_init {
  self = [self initWithUUID:nil];
  return self;
}

- (instancetype)initWithUUID:(NSUUID *)uuid {
  self = [self _initWithUUID:uuid];
  return self;
}

- (instancetype)_initWithUUID:(NSUUID *)uuid {
  self = [super _initWithUUID:uuid];
  if(self) {
    _mutableGroups = [@[] mutableCopy];
    _mutableEntries = [@[] mutableCopy];
    _isAutoTypeEnabled = KPKInherit;
    _isSearchEnabled = KPKInherit;
    _lastTopVisibleEntry = NSUUID.kpk_nullUUID;
    //self.updateTiming = YES;
    if(!_observedKeyPathsSet) {
      _observedKeyPathsSet = [NSSet setWithArray:@[NSStringFromSelector(@selector(children)), NSStringFromSelector(@selector(childEntries))]];
    }
  }
  return self;
}

#pragma mark NSCoding
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super _initWithCoder:aDecoder];
  if(self) {
    self.updateTiming = NO;
    self.title = [aDecoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(title))];
    self.notes = [aDecoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(notes))];
    _mutableGroups = [[aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[NSMutableArray.class, KPKGroup.class]]
                                               forKey:NSStringFromSelector(@selector(mutableGroups))] mutableCopy];
    _mutableEntries = [[aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[NSMutableArray.class, KPKEntry.class]]
                                                forKey:NSStringFromSelector(@selector(mutableEntries))] mutableCopy];
    self.isAutoTypeEnabled = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(isAutoTypeEnabled))];
    self.isSearchEnabled = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(isSearchEnabled))];
    self.isExpanded = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(isExpanded))];
    self.defaultAutoTypeSequence = [aDecoder decodeObjectOfClass:NSString.class forKey:NSStringFromSelector(@selector(defaultAutoTypeSequence))];
    self.lastTopVisibleEntry = [aDecoder decodeObjectOfClass:NSUUID.class forKey:NSStringFromSelector(@selector(lastTopVisibleEntry))];
    
    [self _updateGroupObserving];
    [self _updateParents];
    
    self.updateTiming = YES;
  }
  return self;
}

- (void)dealloc {
  for(KPKGroup *group in self.mutableGroups) {
    [self _endObservingGroup:group];
  }
  [self.undoManager removeAllActionsWithTarget:self];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super _encodeWithCoder:aCoder];
  [aCoder encodeObject:_title forKey:NSStringFromSelector(@selector(title))];
  [aCoder encodeObject:_notes forKey:NSStringFromSelector(@selector(notes))];
  [aCoder encodeObject:_mutableGroups forKey:NSStringFromSelector(@selector(mutableGroups))];
  [aCoder encodeObject:_mutableEntries forKey:NSStringFromSelector(@selector(mutableEntries))];
  [aCoder encodeInteger:_isAutoTypeEnabled forKey:NSStringFromSelector(@selector(isAutoTypeEnabled))];
  [aCoder encodeInteger:_isSearchEnabled forKey:NSStringFromSelector(@selector(isSearchEnabled))];
  [aCoder encodeBool:_isExpanded forKey:NSStringFromSelector(@selector(isExpanded))];
  [aCoder encodeObject:_defaultAutoTypeSequence forKey:NSStringFromSelector(@selector(defaultAutoTypeSequence))];
  [aCoder encodeObject:_lastTopVisibleEntry forKey:NSStringFromSelector(@selector(lastTopVisibleEntry))];
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
  return [self _copyWithUUID:self.uuid];
}

- (instancetype)_copyWithUUID:(NSUUID *)uuid {
  KPKGroup *copy = [super _copyWithUUID:uuid];
  KPK_SCOPED_NO_BEGIN(copy.updateTiming);
  copy.isAutoTypeEnabled = self.isAutoTypeEnabled;
  copy.defaultAutoTypeSequence = self->_defaultAutoTypeSequence; // direct access to member to prevent parent lookup!
  copy.isSearchEnabled = self.isSearchEnabled;
  copy.isExpanded = self.isExpanded;
  copy.lastTopVisibleEntry = self.lastTopVisibleEntry;
  copy.mutableEntries = [[[NSMutableArray alloc] initWithArray:self.mutableEntries copyItems:YES] mutableCopy];
  copy.mutableGroups = [[[NSMutableArray alloc] initWithArray:self.mutableGroups copyItems:YES] mutableCopy];
  
  [copy _updateGroupObserving];
  [copy _updateParents];
  
  /* defer parent update to disable undo/redo registration */
  copy.parent = self.parent;
  KPK_SCOPED_NO_END(copy.updateTiming);
  return copy;
}

- (instancetype)copyWithTitle:(NSString *)titleOrNil options:(KPKCopyOptions)options {
  /* We update the UUID */
  KPKGroup *copy = [self _copyWithUUID:nil];
  /* FIXME: pass options to entry forCopyWithTitle */
  [copy _regenerateUUIDs];
  
  if(nil == titleOrNil) {
    NSString *format = NSLocalizedStringFromTableInBundle(@"KPK_GROUP_COPY_%@", nil, [NSBundle bundleForClass:[self class]], "Title format for a copie of a group. Contains a %@ placeholder");
    titleOrNil = [[NSString alloc] initWithFormat:format, self.title];
  }
  copy.title = titleOrNil;
  [copy.timeInfo reset];
  return copy;
}

- (KPKComparsionResult)compareToGroup:(KPKGroup *)aGroup {
  /* normal compare does not ignroe anything */
  return [self _compareToNode:aGroup options:0];
}

- (KPKComparsionResult)_compareToNode:(KPKNode *)aNode options:(KPKNodeCompareOptions)options {
  KPKGroup *aGroup = aNode.asGroup;
  NSAssert([aGroup isKindOfClass:KPKGroup.class], @"No valid object supplied!");
  if(![aGroup isKindOfClass:KPKGroup.class]) {
    return KPKComparsionDifferent;
  }
  
  if(KPKComparsionDifferent == [super _compareToNode:aGroup options:options]) {
    return KPKComparsionDifferent;
  }
  
  if((_isAutoTypeEnabled != aGroup->_isAutoTypeEnabled) || (_isSearchEnabled != aGroup->_isSearchEnabled)) {
    return KPKComparsionDifferent;
  };
  
  __block BOOL isEqual = YES;
  if(!(KPKNodeCompareOptionIgnoreGroups & options)) {
    if( self.mutableGroups.count != aGroup.mutableGroups.count) {
      return KPKComparsionDifferent;
    }
    /* Indexes in groups matter, so we need to compare them */
    [self.mutableGroups enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      KPKGroup *otherGroup = obj;
      KPKGroup *myGroup = self.mutableGroups[idx];
      isEqual &= (KPKComparsionEqual == [myGroup _compareToNode:otherGroup options:options]);
      *stop = !isEqual;
    }];
    
    if(!isEqual) {
      return KPKComparsionDifferent;
    }
  }
  
  if(!(KPKNodeCompareOptionIgnoreEntries & options)) {
    if( self.mutableEntries.count != aGroup.mutableEntries.count ) {
      return KPKComparsionDifferent;
    }
    for(KPKEntry *entry in self.mutableEntries) {
      KPKComparsionResult foundEntry = KPKComparsionDifferent;
      for(KPKEntry *otherEntry in aGroup.mutableEntries) {
        foundEntry = [entry _compareToNode:otherEntry options:options];
        if(foundEntry == KPKComparsionEqual) {
          break;
        }
      }
      if(KPKComparsionDifferent == foundEntry) {
        return KPKComparsionDifferent; // no matching entry found
      }
    }
  }
  return KPKComparsionEqual;
}

- (BOOL)_updateFromNode:(KPKNode *)node options:(KPKUpdateOptions)options {
  BOOL didChange = [super _updateFromNode:node options:options];
  
  NSComparisonResult result = [self.timeInfo.modificationDate compare:node.timeInfo.modificationDate];
  if(NSOrderedAscending == result || (options & KPKUpdateOptionIgnoreModificationTime)) {
    KPKGroup *group = node.asGroup;
    if(!group) {
      return didChange;
    }
    
    self.isAutoTypeEnabled = group.isAutoTypeEnabled;
    self.defaultAutoTypeSequence = group.defaultAutoTypeSequence;
    self.isSearchEnabled = group.isSearchEnabled;
    self.lastTopVisibleEntry = group.lastTopVisibleEntry;
    
    NSDate *movedTime = self.timeInfo.locationChanged;
    self.timeInfo = group.timeInfo;
    if(!(options & KPKUpdateOptionIncludeMovedTime)) {
      self.timeInfo.locationChanged = movedTime;
    }
    return YES;
  }
  return didChange;
}

- (void)_traverseNodesWithOptions:(KPKNodeTraversalOptions)options block:(void (^)(KPKNode *, BOOL *))block {
  BOOL stop = NO;
  if(block && !(options & KPKNodeTraversalOptionSkipGroups)) {
    block(self, &stop);
    if(stop) {
      return; // stop travsersal as requested
    }
  }
  for(KPKGroup *group in self.mutableGroups) {
    [group _traverseNodesWithOptions:options block:block];
  }
  if(!(options & KPKNodeTraversalOptionSkipEntries)) {
    for(KPKEntry *entry in self.mutableEntries) {
      if(block) {
        block(entry, &stop);
        if(stop) {
          return; // stop travsersal as requested
        }
      }
    }
  }
}

#pragma mark Strucural Helper
- (void)_updateParents {
  for(KPKGroup *childGroup in self.mutableGroups) {
    childGroup.parent = self;
    [childGroup _updateParents];
  }
  for(KPKEntry *childEntry in self.mutableEntries) {
    childEntry.parent = self;
  }
}

- (void)_updateGroupObserving {
  for(KPKGroup *group in self.mutableGroups) {
    [self _beginObservingGroup:group];
  }
}

- (void)_regenerateUUIDs {
  [super _regenerateUUIDs];
  for(KPKEntry *entry in self.mutableEntries) {
    [entry _regenerateUUIDs];
  }
  for(KPKGroup *group  in self.mutableGroups) {
    [group _regenerateUUIDs];
  }
}

#if KPK_MAC

#pragma mark NSPasteboardWriting/Reading
- (NSArray<NSString *> *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
  /* UUID gets put it by default, group only as promise to reduce unnecessary archiving */
  return @[KPKGroupUUIDUTI, KPKGroupUTI];
}
+ (NSArray<NSString *> *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
  return @[KPKGroupUTI];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
  NSAssert([type isEqualToString:KPKGroupUTI] || [type isEqualToString:KPKGroupUUIDUTI], @"Type needs to be KPKGroupUTI");
  return NSPasteboardReadingAsKeyedArchive;
}

- (id)pasteboardPropertyListForType:(NSString *)type {
  if([type isEqualToString:KPKGroupUTI]) {
    return [NSKeyedArchiver archivedDataWithRootObject:self];
  }
  if([type isEqualToString:KPKGroupUUIDUTI]) {
    return [NSKeyedArchiver archivedDataWithRootObject:self.uuid];
  }
  return nil;
}

#endif

#pragma mark -
#pragma mark Properties
- (NSUInteger)childIndex {
  return [self.parent.mutableGroups indexOfObjectIdenticalTo:self];
}

- (NSArray<KPKGroup *> *)groups {
  return [self.mutableGroups copy];
}

- (NSArray<KPKEntry *> *)entries {
  return [self.mutableEntries copy];
}

- (NSArray<KPKNode *> *)children {
  NSMutableArray *children = [[NSMutableArray alloc] init];
  [self _collectChildren:children];
  return [children copy];
}

- (void)setNotes:(NSString *)notes {
  if(![_notes isEqualToString:notes]) {
    [[self.undoManager prepareWithInvocationTarget:self] setNotes:self.notes];
    [self touchModified];
    _notes = [notes copy];
  }
}

- (void)setTitle:(NSString *)title {
  if(![_title isEqualToString:title]) {
    [[self.undoManager prepareWithInvocationTarget:self] setTitle:self.title];
    [self touchModified];
    _title = [title copy];
  }
}

- (NSString *)defaultAutoTypeSequence {
  if(!self.hasDefaultAutotypeSequence) {
    return _defaultAutoTypeSequence;
  }
  if(self.parent) {
    return self.parent.defaultAutoTypeSequence;
  }
  NSString *defaultSequence = [self.tree defaultAutotypeSequence];
  BOOL hasDefault = defaultSequence.length > 0;
  return hasDefault ? defaultSequence : @"{USERNAME}{TAB}{PASSWORD}{ENTER}";
}

- (void)setDefaultAutoTypeSequence:(NSString *)defaultAutoTypeSequence {
  [[self.undoManager prepareWithInvocationTarget:self] setDefaultAutoTypeSequence:_defaultAutoTypeSequence];
  [self touchModified];
  _defaultAutoTypeSequence = [defaultAutoTypeSequence copy];
}

- (BOOL)hasDefaultAutotypeSequence {
  return !(_defaultAutoTypeSequence.length > 0);
}

- (void)setIsAutoTypeEnabled:(KPKInheritBool)isAutoTypeEnabled {
  [[self.undoManager prepareWithInvocationTarget:self] setIsAutoTypeEnabled:_isAutoTypeEnabled];
  [self touchModified];
  _isAutoTypeEnabled = isAutoTypeEnabled;
}

- (void)setIsSearchEnabled:(KPKInheritBool)isSearchEnabled {
  [[self.undoManager prepareWithInvocationTarget:self] setIsSearchEnabled:_isSearchEnabled];
  [self touchModified];
  _isSearchEnabled = isSearchEnabled;
}

- (KPKFileVersion)minimumVersion {
  KPKFileVersion minimum = { KPKDatabaseFormatKdb, kKPKKdbFileVersion };
  
  BOOL requiresKDBX = (self.customData.count > 0 ||
                       self.isSearchEnabled != KPKInherit ||
                       self.isAutoTypeEnabled != KPKInherit ||
                       self.tags.count > 0);
  
  if(requiresKDBX) {
    minimum.format = KPKDatabaseFormatKdbx;
    minimum.version = kKPKKdbxFileVersion3;
    
    if(self.customData.count > 0) {
      KPKFileVersion required = {KPKDatabaseFormatKdbx, kKPKKdbxFileVersion4 };
      minimum = KPKFileVersionMax(minimum, required);
    }
    
    if(self.tags.count > 0) {
      KPKFileVersion required = { KPKDatabaseFormatKdbx, kKPKKdbxFileVersion4_1 };
      minimum = KPKFileVersionMax(minimum, required);
    }
  }
  
  for(KPKGroup *group in self.mutableGroups) {
    minimum = KPKFileVersionMax(minimum, group.minimumVersion);
  }
  for(KPKEntry *entry in self.mutableEntries) {
    minimum = KPKFileVersionMax(minimum, entry.minimumVersion);
  }
  
  return minimum;
}

#pragma mark -
#pragma mark Accessors
- (NSArray *)childEntries {
  NSMutableArray *entries = [[NSMutableArray alloc] init];
  [self _collectChildEntries:entries];
  return entries;
}

- (void)_collectChildEntries:(NSMutableArray *)entries {
  [entries addObjectsFromArray:self.mutableEntries];
  for(KPKGroup *group in self.mutableGroups) {
    [group _collectChildEntries:entries];
  }
}

- (NSArray *)childGroups {
  NSMutableArray *groups = [[NSMutableArray alloc] init];
  [self _collectChildGroups:groups];
  return groups;
}

- (void)_collectChildGroups:(NSMutableArray *)groups {
  [groups addObjectsFromArray:self.mutableGroups];
  for(KPKGroup *group in self.mutableGroups) {
    [group _collectChildGroups:groups];
  }
}

- (KPKGroup *)asGroup {
  return self;
}

#pragma mark -
#pragma mark Group/Entry editing

- (void)_addChild:(KPKNode *)node atIndex:(NSUInteger)index {
  KPKEntry *entry = node.asEntry;
  KPKGroup *group = node.asGroup;
  
  if(group) {
    [[NSNotificationCenter defaultCenter] postNotificationName:KPKTreeWillAddGroupNotification object:self.tree userInfo:@{ KPKParentGroupKey: self, KPKGroupKey: group }];
    index = MAX(0, MIN(self.mutableGroups.count, index));
    [self insertObject:group inMutableGroupsAtIndex:index];
    [[NSNotificationCenter defaultCenter] postNotificationName:KPKTreeDidAddGroupNotification object:self.tree userInfo:@{ KPKParentGroupKey: self, KPKGroupKey: group }];
  }
  else if(entry) {
    index = MAX(0, MIN(self.mutableEntries.count, index));
    [[NSNotificationCenter defaultCenter] postNotificationName:KPKTreeWillAddEntryNotification object:self.tree userInfo:@{ KPKParentGroupKey: self, KPKEntryKey: entry }];
    [self insertObject:entry inMutableEntriesAtIndex:index];
    [[NSNotificationCenter defaultCenter] postNotificationName:KPKTreeDidAddEntryNotification object:self.tree userInfo:@{ KPKParentGroupKey: self, KPKEntryKey: entry }];
  }
  node.parent = self;
}

- (void)_removeChild:(KPKNode *)node {
  KPKEntry *entry = node.asEntry;
  KPKGroup *group = node.asGroup;
  
  if(group) {
    [NSNotificationCenter.defaultCenter postNotificationName:KPKTreeWillRemoveGroupNotification object:self.tree userInfo:@{ KPKParentGroupKey: self, KPKEntryKey: group }];
    /* deleted objects should be registred, no undo registration */
    [self removeObjectFromMutableGroupsAtIndex:[self.mutableGroups indexOfObjectIdenticalTo:group]];
    [NSNotificationCenter.defaultCenter postNotificationName:KPKTreeDidRemoveGroupNotification object:self.tree userInfo:@{ KPKParentGroupKey: self, KPKEntryKey: group }];
  }
  else if(entry) {
    [NSNotificationCenter.defaultCenter postNotificationName:KPKTreeWillRemoveEntryNotification object:self.tree userInfo:@{ KPKParentGroupKey: self, KPKEntryKey: entry }];
    [self removeObjectFromMutableEntriesAtIndex:[self.mutableEntries indexOfObjectIdenticalTo:entry]];
    [NSNotificationCenter.defaultCenter postNotificationName:KPKTreeDidRemoveEntryNotification object:self.tree userInfo:@{ KPKParentGroupKey: self, KPKEntryKey: entry }];
  }
  node.parent = nil;
}

- (NSUInteger)_indexForNode:(KPKNode *)node {
  if(node.asGroup) {
    return [self.mutableGroups indexOfObjectIdenticalTo:node.asGroup];
  }
  return [self.mutableEntries indexOfObjectIdenticalTo:node.asEntry];
}

#pragma mark Seaching
- (KPKEntry *)entryForUUID:(NSUUID *)uuid {
  if(!uuid) {
    return nil;
  }
  for(KPKEntry *entry in self.mutableEntries) {
    if([entry.uuid isEqual:uuid]) {
      return entry;
    }
  }
  for(KPKGroup *group in self.mutableGroups) {
    KPKEntry *match = [group entryForUUID:uuid];
    if(match) {
      return match;
    }
  }
  return nil;
}

- (KPKGroup *)groupForUUID:(NSUUID *)uuid {
  if(!uuid) {
    return nil;
  }
  if([self.uuid isEqual:uuid]) {
    return self;
  }
  for(KPKGroup *group in self.mutableGroups) {
    KPKGroup *match = [group groupForUUID:uuid];
    if(match) {
      return match;
    }
  }
  return nil;
}

- (NSArray<KPKEntry *> *)searchableChildEntries {
  NSMutableArray<KPKEntry *> *searchableEntries;
  if([self _isSearchable]) {
    searchableEntries = [NSMutableArray arrayWithArray:self.mutableEntries];
  }
  else {
    searchableEntries = [[NSMutableArray alloc] init];
  }
  for(KPKGroup *group in self.mutableGroups) {
    [searchableEntries addObjectsFromArray:group.searchableChildEntries];
  }
  return searchableEntries;
}

- (BOOL)_isSearchable {
  if(self.isTrash || self.isTrashed) {
    return NO;
  }
  switch(self.isSearchEnabled) {
    case KPKInherit:
      return self.parent ? [self.parent _isSearchable] : YES;
      
    case KPKInheritNO:
      return NO;
      
    case KPKInheritYES:
      return YES;
  }
}

#pragma mark Autotype
- (NSArray<KPKEntry *> *)autotypeableChildEntries {
  NSMutableArray<KPKEntry *> *autotypeEntries;
  if(self.isAutotypeable) {
    /* KPKEntries have their own autotype settings, hence we need to filter them as well */
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
      NSAssert([evaluatedObject isKindOfClass:KPKEntry.class], @"entry array should contain only KPKEntry objects");
      KPKEntry *entry = evaluatedObject;
      return entry.autotype.enabled;
    }];
    autotypeEntries = [NSMutableArray arrayWithArray:[self.mutableEntries filteredArrayUsingPredicate:predicate]];
  }
  else {
    autotypeEntries = [[NSMutableArray alloc] init];
  }
  for(KPKGroup *group in self.mutableGroups) {
    [autotypeEntries addObjectsFromArray:[group autotypeableChildEntries]];
  }
  return autotypeEntries;
}

- (BOOL)isAutotypeable {
  if(self.isTrash || self.isTrashed){
    return NO;
  }
  switch(self.isAutoTypeEnabled) {
    case KPKInherit:
      /* Default is YES, so fall back to YES if no parent is set, aplies to root node as well */
      return self.parent ? self.parent.isAutoTypeEnabled : YES;
      
    case KPKInheritNO:
      return NO;
      
    case KPKInheritYES:
      return YES;
  }
}

#pragma mark Hierarchy

- (void)_collectChildren:(NSMutableArray *)children {
  /* TODO optimize using non-retained data structure? */
  if(!children) {
    children = [[NSMutableArray alloc] init];
  }
  [children addObjectsFromArray:self.mutableEntries];
  for(KPKGroup *group in self.mutableGroups) {
    [children addObject:group];
    [group _collectChildren:children];
  }
}

#pragma mark Delete

- (void)clear {
  KPK_SCOPED_DISABLE_UNDO_BEGIN(self.undoManager);
  [self _clear:YES];
  KPK_SCOPED_DISABLE_UNDO_END;
}

- (void)_clear:(BOOL)keepGroup {
  /* enumarte backwards to be able to mutate array */
  for(KPKGroup *group in self.mutableGroups.reverseObjectEnumerator) {
    [group _clear:NO];
  }
  for(KPKEntry *entry in self.entries) {
    [entry remove];
  }
  if(!keepGroup) {
    [self remove];
  }
}
#pragma mark -
#pragma mark KVC
- (NSUInteger)countOfGroupsArray {
  return self.mutableGroups.count;
}

- (KPKGroup *)objectInGroupsArrayAtIndex:(NSUInteger)index {
  return self.mutableGroups[index];
}

- (void)getGroupsArray:(KPKGroup *__unsafe_unretained  _Nonnull * _Nonnull)buffer range:(NSRange)inRange {
  [self.mutableGroups getObjects:buffer range:inRange];
}

- (NSUInteger)countOfEntriesArray {
  return self.mutableEntries.count;
}

- (KPKEntry *)objectInEntriesArrayAtIndex:(NSUInteger)index {
  return self.mutableEntries[index];
}
- (void)getEntriesArray:(KPKEntry *__unsafe_unretained  _Nonnull * _Nonnull)buffer range:(NSRange)inRange {
  [self.mutableEntries getObjects:(KPKEntry *__unsafe_unretained  _Nonnull * _Nonnull)buffer range:inRange];
}

- (void)insertObject:(KPKEntry *)entry inMutableEntriesAtIndex:(NSUInteger)index {
  [_mutableEntries insertObject:entry atIndex:index];
}

- (void)removeObjectFromMutableEntriesAtIndex:(NSUInteger)index {
  [_mutableEntries removeObjectAtIndex:index];
}

- (void)insertObject:(KPKGroup *)group inMutableGroupsAtIndex:(NSUInteger)index {
  [_mutableGroups insertObject:group atIndex:index];
  [self _beginObservingGroup:group];
}

- (void)removeObjectFromMutableGroupsAtIndex:(NSUInteger)index {
  KPKGroup *group = _mutableGroups[index];
  [_mutableGroups removeObjectAtIndex:index];
  [self _endObservingGroup:group];
}


- (void)_beginObservingGroup:(KPKGroup *)group {
  [group addObserver:self forKeyPath:NSStringFromSelector(@selector(children)) options:0 context:NULL];
}

- (void)_endObservingGroup:(KPKGroup *)group {
  [group removeObserver:self forKeyPath:NSStringFromSelector(@selector(children))];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
  if(!object) {
    return;
  }
  if([_observedKeyPathsSet containsObject:keyPath]) {
    /* just trigger a update to the children property */
    [self willChangeValueForKey:keyPath];
    [self didChangeValueForKey:keyPath];
  }
}

@end

