//
//  KPKEntry.m
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

#import "KPKEntry.h"
#import "KPKEntry+Private.h"
#import "KPKNode+Private.h"
#import "KPKGroup.h"
#import "KPKBinary.h"
#import "KPKBinary+Private.h"
#import "KPKAttribute.h"
#import "KPKAttribute+Private.h"
#import "KPKAutotype.h"
#import "KPKAutotype+Private.h"
#import "KPKWindowAssociation.h"
#import "KPKFormat.h"
#import "KPKTimeInfo.h"
#import "KPKUTIs.h"

NSString *const KPKMetaEntryBinaryDescription   = @"bin-stream";
NSString *const KPKMetaEntryTitle               = @"Meta-Info";
NSString *const KPKMetaEntryUsername            = @"SYSTEM";
NSString *const KPKMetaEntryURL                 = @"$";

NSString *const KPKMetaEntryUIState                 = @"Simple UI State";
NSString *const KPKMetaEntryDefaultUsername         = @"Default User Name";
NSString *const KPKMetaEntrySearchHistoryItem       = @"Search History Item";
NSString *const KPKMetaEntryCustomKVP               = @"Custom KVP";
NSString *const KPKMetaEntryDatabaseColor           = @"Database Color";
NSString *const KPKMetaEntryKeePassXCustomIcon      = @"KPX_CUSTOM_ICONS_2";
NSString *const KPKMetaEntryKeePassXCustomIcon2     = @"KPX_CUSTOM_ICONS_4";
NSString *const KPKMetaEntryKeePassXGroupTreeState  = @"KPX_GROUP_TREE_STATE";


@interface KPKEntry () {
@private
  NSMutableArray *_binaries;
}

@property (nonatomic, strong) NSMutableArray<KPKAttribute *> *mutableAttributes;
@property (nonatomic, strong) NSMutableArray<KPKEntry *> *mutableHistory;
@property (nonatomic, strong) NSArray<KPKBinary *> *binaries;
@property (nonatomic) BOOL isHistory;

@end


@implementation KPKEntry

@dynamic title;
@dynamic notes;
@dynamic attributes;
@dynamic defaultAttributes;
@dynamic customAttributes;
@dynamic updateTiming;

NSSet *_protectedKeyPathForAttribute(SEL aSelector) {
  NSString *keyPath = [[NSString alloc] initWithFormat:@"%@.%@", NSStringFromSelector(aSelector), NSStringFromSelector(@selector(value))];
  return [[NSSet alloc] initWithObjects:keyPath, nil];
}

+ (BOOL)supportsSecureCoding {
  return YES;
}

+ (KPKEntry *)metaEntryWithData:(NSData *)data name:(NSString *)name {
  KPKEntry *metaEntry = [[KPKEntry alloc] init];
  metaEntry.title = KPKMetaEntryTitle;
  metaEntry.username = KPKMetaEntryUsername;
  metaEntry.url = KPKMetaEntryURL;
  /* Name is stored in the notes attribute of the entry */
  metaEntry.notes = name;
  KPKBinary *binary = [[KPKBinary alloc] init];
  binary.name = KPKMetaEntryBinaryDescription;
  binary.data = data;
  [metaEntry addBinary:binary];
  
  return metaEntry;
}

+ (NSSet *)keyPathsForValuesAffectingIsEditable {
  return [[NSSet alloc] initWithObjects:NSStringFromSelector(@selector(isHistory)), nil];
}

+ (NSSet *)keyPathsForValuesAffectingHistory {
  return [NSSet setWithObject:NSStringFromSelector(@selector(mutableHistory))];
}

/* The only storage for attributes is the mutableAttributes array, so all getter depend on it*/
+ (NSSet *)keyPathsForValuesAffectingAttributes {
  return [NSSet setWithObject:NSStringFromSelector(@selector(mutableAttributes))];
}

+ (NSSet *)keyPathsForValuesAffectingCustomAttributes {
  return [NSSet setWithObject:NSStringFromSelector(@selector(mutableAttributes))];
}

+ (NSSet *)keyPathsForValuesAffectingDefaultAttributes {
  return [NSSet setWithObject:NSStringFromSelector(@selector(mutableAttributes))];
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
  if (self) {
    /* !Note! - Title -> Name */
    _mutableAttributes = [[NSMutableArray alloc] init];
    /* create the default attributes */
    
    for(NSString *key in [KPKFormat sharedFormat].entryDefaultKeys) {
      KPKAttribute *attribute = [[KPKAttribute alloc] initWithKey:key value:@""];
      attribute.entry = self;
      [_mutableAttributes addObject:attribute];
    }
    _binaries = [[NSMutableArray alloc] init];
    _mutableHistory = [[NSMutableArray alloc] init];
    _autotype = [[[KPKAutotype alloc] init] copy];
    
    _autotype.entry = self;
    _isHistory = NO;
  }
  return self;
}

- (void)dealloc {
  /* Remove us from the undo stack */
  [self.undoManager removeAllActionsWithTarget:self];
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
  return [self _copyWithUUUD:self.uuid];
}

- (instancetype)_copyWithUUUD:(nullable NSUUID *)uuid {
  KPKEntry *copy = [super _copyWithUUUD:uuid];
  /* Default attributes */
  copy.overrideURL = self.overrideURL;
  
  copy.binaries = [[NSMutableArray alloc] initWithArray:self->_binaries copyItems:YES];
  copy.mutableAttributes = [[NSMutableArray alloc] initWithArray:self.mutableAttributes copyItems:YES];
  copy.tags = self.tags;
  copy.autotype = self.autotype;
  /* Shallow copy skipps history */
  copy.isHistory = NO;
  
  /* Color */
  copy.foregroundColor = self.foregroundColor;
  copy.backgroundColor = self.backgroundColor;
  
  /* History */
  copy.mutableHistory = [[NSMutableArray alloc] initWithArray:self.mutableHistory copyItems:YES];
  copy.isHistory = self.isHistory;
  /* parent at last, to prevent undo/redo registration */
  copy.parent = self.parent;
  return copy;
}

#pragma mark NSCoding
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super _initWithCoder:aDecoder];
  if(self) {
    /* Disable timing since we init via coder */
    self.updateTiming = NO;
    /* use setter for internal consistency */
    self.mutableAttributes = [aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:NSStringFromSelector(@selector(mutableAttributes))];
    self.mutableHistory = [aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:NSStringFromSelector(@selector(mutableHistory))];
    _binaries = [aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:NSStringFromSelector(@selector(binaries))];
    _tags = [[aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(tags))] copy];
    _foregroundColor = [[aDecoder decodeObjectOfClass:[NSColor class] forKey:NSStringFromSelector(@selector(foregroundColor))] copy];
    _backgroundColor = [[aDecoder decodeObjectOfClass:[NSColor class] forKey:NSStringFromSelector(@selector(backgroundColor))] copy];
    _overrideURL = [[aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(overrideURL))] copy];
    self.autotype = [aDecoder decodeObjectOfClass:[KPKAutotype class] forKey:NSStringFromSelector(@selector(autotype))];
    _isHistory = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(isHistory))];
    
    self.updateTiming = YES;
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super _encodeWithCoder:aCoder];
  [aCoder encodeObject:_mutableAttributes forKey:NSStringFromSelector(@selector(mutableAttributes))];
  [aCoder encodeObject:_binaries forKey:NSStringFromSelector(@selector(binaries))];
  [aCoder encodeObject:_tags forKey:NSStringFromSelector(@selector(tags))];
  [aCoder encodeObject:_foregroundColor forKey:NSStringFromSelector(@selector(foregroundColor))];
  [aCoder encodeObject:_backgroundColor forKey:NSStringFromSelector(@selector(backgroundColor))];
  [aCoder encodeObject:_overrideURL forKey:NSStringFromSelector(@selector(overrideURL))];
  [aCoder encodeObject:_mutableHistory forKey:NSStringFromSelector(@selector(mutableHistory))];
  [aCoder encodeObject:_autotype forKey:NSStringFromSelector(@selector(autotype))];
  [aCoder encodeBool:_isHistory forKey:NSStringFromSelector(@selector(isHistory))];
  return;
}

- (instancetype)copyWithTitle:(NSString *)titleOrNil options:(KPKCopyOptions)options {
  /* Copy sets a new UUID */
  KPKEntry *copy = [self _copyWithUUUD:nil];
  if(!titleOrNil) {
    NSString *format = NSLocalizedStringFromTable(@"KPK_ENTRY_COPY_%@", @"KPKLocalizable", "");
    titleOrNil = [[NSString alloc] initWithFormat:format, self.title];
  }
  copy.title = titleOrNil;
  [copy.timeInfo reset];
  return copy;
}

#pragma mark NSPasteBoardWriting/Readin

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
  NSAssert([type isEqualToString:KPKEntryUTI], @"Only KPKEntryUTI type is supported");
  return NSPasteboardReadingAsKeyedArchive;
}

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
  return @[KPKEntryUTI];
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
  return @[KPKEntryUTI];
}

- (id)pasteboardPropertyListForType:(NSString *)type {
  if([type isEqualToString:KPKEntryUTI]) {
    return [NSKeyedArchiver archivedDataWithRootObject:self];
  }
  return nil;
}

#pragma mark Equality

- (BOOL)isEqual:(id)object {
  if(![super isEqual:object]) {
    return NO;
  }
  if([object isKindOfClass:self.class]) {
    return [self isEqualToEntry:object];
  }
  return NO;
}

- (BOOL)isEqualToEntry:(KPKEntry *)entry {
  NSAssert([entry isKindOfClass:[KPKEntry class]], @"Test only allowed with KPKEntry classes");
  
  if(![self isEqualToNode:entry]) {
    return NO;
  }
  
  if(self.mutableAttributes.count != entry.mutableAttributes.count) {
    return NO;
  }
  
  for(KPKAttribute *attribute in self.mutableAttributes) {
    KPKAttribute *otherAttribute = [entry attributeWithKey:attribute.key];
    if(!otherAttribute) {
      return NO;
    }
    if(![otherAttribute isEqualToAttribute:attribute]) {
      return NO;
    }
  }
  return [self.autotype isEqualToAutotype:entry.autotype];
}

#pragma mark -
#pragma mark Attribute accessors
- (NSArray *)defaultAttributes {
  return [self.mutableAttributes subarrayWithRange:NSMakeRange(0, kKPKDefaultEntryKeysCount)];
}

- (NSArray *)customAttributes {
  return [self.mutableAttributes subarrayWithRange:NSMakeRange(kKPKDefaultEntryKeysCount, self.mutableAttributes.count - kKPKDefaultEntryKeysCount)];
}

- (NSArray *)attributes {
  return [self.mutableAttributes copy];
}

- (KPKAttribute *)attributeWithKey:(NSString *)key {
  if(!key) {
    return nil;
  }
  for(KPKAttribute *attribute in self.mutableAttributes) {
    if([attribute.key isEqualToString:key]) {
      return attribute;
    }
  }
  return nil;
}

- (BOOL)hasAttributeWithKey:(NSString *)key {
  return (nil != [self attributeWithKey:key]);
}

- (BOOL)_protectValueForKey:(NSString *)key {
  return [self attributeWithKey:key].isProtected;
}

- (void)_setProtect:(BOOL)protect valueForkey:(NSString *)key {
  [self attributeWithKey:key].isProtected = protect;
}

- (NSString *)valueForAttributeWithKey:(NSString *)key {
  return [self attributeWithKey:key].value;
}

- (void)_setValue:(NSString *)value forAttributeWithKey:(NSString *)key {
  [self attributeWithKey:key].value = value;
}

#pragma mark -
#pragma mark Properties
- (BOOL )protectNotes {
  return [self _protectValueForKey:kKPKNotesKey];
}

- (BOOL)protectPassword {
  return  [self _protectValueForKey:kKPKPasswordKey];
}

- (BOOL)protectTitle {
  return [self _protectValueForKey:kKPKTitleKey];
}

- (BOOL)protectUrl {
  return [self _protectValueForKey:kKPKURLKey];
}

- (BOOL)protectUsername {
  return [self _protectValueForKey:kKPKUsernameKey];
}

- (BOOL)isEditable {
  
  if(super.isEditable) {
    return !self.isHistory;
  }
  return NO;
}

- (NSArray *)binaries {
  return [_binaries copy];
}

- (NSArray *)history {
  return [self.mutableHistory copy];
}

- (NSString *)title {
  return [self valueForAttributeWithKey:kKPKTitleKey];
}

- (NSString *)username {
  return [self valueForAttributeWithKey:kKPKUsernameKey];
}

- (NSString *)password {
  return [self valueForAttributeWithKey:kKPKPasswordKey];
}

- (NSString *)notes {
  return [self valueForAttributeWithKey:kKPKNotesKey];
}

- (NSString *)url {
  return [self valueForAttributeWithKey:kKPKURLKey];
}

- (BOOL)isMeta {
  /* Meta entries always contain data */
  KPKBinary *binary = self.binaries.lastObject;
  if(!binary) {
    return NO;
  }
  if(binary.data.length == 0) {
    return NO;
  }
  if(![binary.name isEqualToString:KPKMetaEntryBinaryDescription]) {
    return NO;
  }
  if(![self.title isEqualToString:KPKMetaEntryTitle]) {
    return NO;
  }
  if(![self.username isEqualToString:KPKMetaEntryUsername]) {
    return NO;
  }
  if(![self.url isEqualToString:KPKMetaEntryURL]) {
    return NO;
  }
  /* The Name of the type is stored as the note attribute */
  if(self.notes.length == 0) {
    return NO;
  }
  return YES;
}

- (KPKVersion)minimumVersion {
  if(self.binaries.count > 1 ||
     self.customAttributes.count > 0 ||
     self.history.count > 0 ) {
    return KPKXmlVersion;
  }
  return KPKLegacyVersion;
}

- (void)setMutableAttributes:(NSMutableArray<KPKAttribute *> *)mutableAttributes {
  _mutableAttributes = mutableAttributes;
  for(KPKAttribute *attribute in self.mutableAttributes) {
    attribute.entry = self;
  }
}

- (void)setMutableHistory:(NSMutableArray<KPKEntry *> *)mutableHistory {
  _mutableHistory = mutableHistory;
  for(KPKEntry *entry in self.mutableHistory) {
    entry.parent = self.parent;
  }
}

- (void)setParent:(KPKGroup *)parent {
  super.parent = parent;
  if(self.isHistory) {
    return;
  }
  for(KPKEntry *entry in self.mutableHistory) {
    entry.parent = parent;
  }
}

- (void)setProtectNotes:(BOOL)protectNotes {
  [self _setProtect:protectNotes valueForkey:kKPKNotesKey];
}

- (void)setProtectPassword:(BOOL)protectPassword {
  [self _setProtect:protectPassword valueForkey:kKPKPasswordKey];
}

- (void)setProtectTitle:(BOOL)protectTitle {
  [self _setProtect:protectTitle valueForkey:kKPKTitleKey];
}

- (void)setProtectUrl:(BOOL)protectUrl {
  [self _setProtect:protectUrl valueForkey:kKPKURLKey];
}

- (void)setProtectUsername:(BOOL)protectUsername {
  [self _setProtect:protectUsername valueForkey:kKPKUsernameKey];
}

- (void)setAutotype:(KPKAutotype *)autotype {
  if(autotype == _autotype) {
    return;
  }
  _autotype = [autotype copy];
  _autotype.entry = self;
}

- (void)setTitle:(NSString *)title {
  [[self.undoManager prepareWithInvocationTarget:self] setTitle:self.title];
  [self _setValue:title forAttributeWithKey:kKPKTitleKey];
}

- (void)setUsername:(NSString *)username {
  [[self.undoManager prepareWithInvocationTarget:self] setUsername:self.username];
  [self _setValue:username forAttributeWithKey:kKPKUsernameKey];
}

- (void)setPassword:(NSString *)password {
  [[self.undoManager prepareWithInvocationTarget:self] setPassword:self.password];
  [self _setValue:password forAttributeWithKey:kKPKPasswordKey];
}

- (void)setNotes:(NSString *)notes {
  [[self.undoManager prepareWithInvocationTarget:self] setNotes:self.notes];
  [self _setValue:notes forAttributeWithKey:kKPKNotesKey];
}

- (void)setUrl:(NSString *)url {
  [[self.undoManager prepareWithInvocationTarget:self] setUrl:self.url];
  [self _setValue:url forAttributeWithKey:kKPKURLKey];
}

- (KPKEntry *)asEntry {
  return self;
}

#pragma mark Editing
/*
 - (void)commitChangesFromEntry:(KPKEntry *)entry {
  entry = entry.asEntry;
  NSAssert(entry, @"KPKEntry nodes can only update to KPKEntry nodes!");
  if(nil == entry) {
    return; // only KPKEntry can be used
  }
  
  [self _addHistoryEntry:entry];
  
  // updates icon, iconID, note, title
  self.iconId = entry.iconId;
  self.iconUUID = entry.iconUUID;
  self.title = entry.title;
  self.notes = entry.notes;
  
  self.tags = entry.tags;
  self.foregroundColor = entry.foregroundColor;
  self.backgroundColor = entry.backgroundColor;
  self.overrideURL = entry.overrideURL;
  self.autotype = entry.autotype;
  self.binaries = [[NSMutableArray alloc] initWithArray:entry->_binaries copyItems:YES];
  self.mutableAttributes = [[NSMutableArray alloc] initWithArray:self.mutableAttributes copyItems:YES];
  
  [self touchModified];
}
*/

#pragma mark CustomAttributes
- (KPKAttribute *)customAttributeForKey:(NSString *)key {
  KPKAttribute *attribute = [self attributeWithKey:key];
  if(!attribute.isDefault) {
    return attribute;
  }
  return nil;
}

-(NSString *)proposedKeyForAttributeKey:(NSString *)key {
  NSUInteger counter = 1;
  NSString *base = key;
  while(nil != [self attributeWithKey:key]) {
    key = [NSString stringWithFormat:@"%@-%ld", base, counter++];
  }
  return key;
}

- (void)addCustomAttribute:(KPKAttribute *)attribute {
  [self _addCustomAttribute:attribute atIndex:self.mutableAttributes.count];
}

- (void)_addCustomAttribute:(KPKAttribute *)attribute atIndex:(NSUInteger)index {
  if(nil == attribute) {
    return; // no attribute
  }
  if(index > self.mutableAttributes.count) {
    return; // index out of bounds
  }
  [[self.undoManager prepareWithInvocationTarget:self] removeCustomAttribute:attribute];
  [self touchModified];
  [self insertObject:attribute inMutableAttributesAtIndex:index];
  attribute.entry = self;
}

- (void)removeCustomAttribute:(KPKAttribute *)attribute {
  NSUInteger index = [self.mutableAttributes indexOfObject:attribute];
  if(NSNotFound != index) {
    [[self.undoManager prepareWithInvocationTarget:self] _addCustomAttribute:attribute atIndex:index];
    [self touchModified];
    attribute.entry = nil;
    [self removeObjectFromMutableAttributesAtIndex:index];
  }
}
#pragma mark Attachments

- (void)addBinary:(KPKBinary *)binary {
  [self _addBinary:binary atIndex:_binaries.count];
}

- (void)_addBinary:(KPKBinary *)binary atIndex:(NSUInteger)index {
  if(nil == binary) {
    return; // nil not allowed
  }
  if(index > _binaries.count) {
    return; // index out of bounds!
  }
  [[self.undoManager prepareWithInvocationTarget:self] removeBinary:binary];
  [self touchModified];
  [self insertObject:binary inBinariesAtIndex:index];

}

- (void)removeBinary:(KPKBinary *)binary {
  /*
   Attachments are stored on entries.
   Only on load the binaries are stored ad meta entries to the tree
   So we do not need to take care of cleanup after we did
   delete an attachment
   */
  NSUInteger index = [_binaries indexOfObject:binary];
  if(index != NSNotFound) {
    [self touchModified];
    [self removeObjectFromBinariesAtIndex:index];
  }
}

#pragma mark History
- (void)_addHistoryEntry:(KPKEntry *)entry {
  [self insertObject:entry inHistoryAtIndex:self.mutableHistory.count];
}

- (void)_removeHistoryEntry:(KPKEntry *)entry {
  NSUInteger index = [self.mutableHistory indexOfObject:entry];
  if(index != NSNotFound) {
    [self removeObjectFromHistoryAtIndex:index];
  }
}
- (void)pushHistory {
  [self _addHistoryEntry:[self _copyWithUUUD:self.uuid]];
}

- (void)clearHistory {
  NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.mutableHistory.count)];
  [self removeHistoryAtIndexes:indexes];
}

- (NSUInteger)estimatedByteSize {
  
  NSUInteger __block size = 128; // KeePass suggest this as the inital size
  
  /* Attributes */
  for(KPKAttribute *attribute in self.mutableAttributes) {
    size += attribute.value.length;
    size += attribute.key.length;
  }
  
  /* Binaries */
  for(KPKBinary *binary in self.binaries) {
    size += binary.name.length;
    size += binary.data.length;
  }
  
  /* Autotype */
  size += self.autotype.defaultKeystrokeSequence.length;
  for(KPKWindowAssociation *association in self.autotype.associations ) {
    size += association.windowTitle.length;
    size += association.keystrokeSequence.length;
  }
  
  /* Misc */
  size += self.overrideURL.length;
  
  /* Tags */
  for(NSString *tag in self.tags) {
    size +=tag.length;
  }
  
  /* History */
  for(KPKEntry *entry in self.mutableHistory) {
    size += entry.estimatedByteSize;
  }
  
  /* Color? */
  return size;
}

#pragma mark -
#pragma mark KVO


- (NSUInteger)countOfAttributes {
  return self.mutableAttributes.count;
}

- (void)insertObject:(KPKAttribute *)object inMutableAttributesAtIndex:(NSUInteger)index {
  index = MIN(self.mutableAttributes.count, index);
  [self.mutableAttributes insertObject:object atIndex:index];
}

- (void)removeObjectFromMutableAttributesAtIndex:(NSUInteger)index {
  if(index < self.mutableAttributes.count) {
    [self.mutableAttributes removeObjectAtIndex:index];
  }
}

/* Binaries */
- (NSUInteger)countOfBinaries {
  return _binaries.count;
}

- (void)insertObject:(KPKBinary *)binary inBinariesAtIndex:(NSUInteger)index {
  /* Clamp the index to make sure we do not add at wrong places */
  index = MIN([_binaries count], index);
  [_binaries insertObject:binary atIndex:index];
}

- (void)removeObjectFromBinariesAtIndex:(NSUInteger)index {
  if(index < _binaries.count) {
    [_binaries removeObjectAtIndex:index];
  }
}

/* History */
- (NSUInteger)countOfHistory {
  return self.mutableHistory.count;
}

- (void)insertObject:(KPKEntry *)entry inHistoryAtIndex:(NSUInteger)index {
  index = MIN(self.mutableHistory.count, index);
  /* Entries in history should not have a history of their own */
  [entry clearHistory];
  NSAssert(entry.history.count == 0, @"History entries cannot hold a history of their own!");
  entry.isHistory = YES;
  entry.parent = self.parent;
  [self.mutableHistory insertObject:entry atIndex:index];
}

- (void)removeObjectFromHistoryAtIndex:(NSUInteger)index {
  [self removeHistoryAtIndexes:[NSIndexSet indexSetWithIndex:index]];
}

- (void)removeHistoryAtIndexes:(NSIndexSet *)indexes {
  [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    KPKEntry *historyEntry = self.mutableHistory[idx];
    NSAssert(historyEntry != nil, @"History indexes need to be valid!");
    historyEntry.isHistory = NO;
  }];
  [self.mutableHistory removeObjectsAtIndexes:indexes];
}

#pragma mark -
#pragma mark Private Helper



@end
