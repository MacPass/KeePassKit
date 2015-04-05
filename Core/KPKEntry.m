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
#import "KPKGroup.h"
#import "KPKBinary.h"
#import "KPKAttribute.h"
#import "KPKAutotype.h"
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
  NSMutableArray *_customAttributes;
  NSMutableArray *_history;
}

@property (nonatomic, strong) KPKAttribute *titleAttribute;
@property (nonatomic, strong) KPKAttribute *passwordAttribute;
@property (nonatomic, strong) KPKAttribute *usernameAttribute;
@property (nonatomic, strong) KPKAttribute *urlAttribute;
@property (nonatomic, strong) KPKAttribute *notesAttribute;
@property (nonatomic, assign) BOOL isHistory;

@end


@implementation KPKEntry

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

+ (NSSet *)keyPathsForValuesAffectingProtectNotes {
  return _protectedKeyPathForAttribute(@selector(notesAttribute));
}

+ (NSSet *)keyPathsForValuesAffectingProtectPassword {
  return _protectedKeyPathForAttribute(@selector(passwordAttribute));
}

+ (NSSet *)keyPathsForValuesAffectingProtectTitle {
  return _protectedKeyPathForAttribute(@selector(titleAttribute));
}

+ (NSSet *)keyPathsForValuesAffectingProtectUrl {
  return _protectedKeyPathForAttribute(@selector(urlAttribute));
}

+ (NSSet *)keyPathsForValuesAffectingProtectUsername {
  return _protectedKeyPathForAttribute(@selector(usernameAttribute));
}

- (id)init {
  self = [super init];
  if (self) {
    _titleAttribute = [[KPKAttribute alloc] initWithKey:kKPKTitleKey value:@""];
    _passwordAttribute = [[KPKAttribute alloc] initWithKey:kKPKPasswordKey value:@""];
    _usernameAttribute = [[KPKAttribute alloc] initWithKey:kKPKUsernameKey value:@""];
    _urlAttribute = [[KPKAttribute alloc] initWithKey:kKPKURLKey value:@""];
    _notesAttribute = [[KPKAttribute alloc] initWithKey:kKPKNotesKey value:@""];
    _customAttributes = [[NSMutableArray alloc] initWithCapacity:2];
    _binaries = [[NSMutableArray alloc] initWithCapacity:2];
    _history = [[NSMutableArray alloc] initWithCapacity:5];
    _autotype = [[KPKAutotype alloc] init];
    
    _titleAttribute.entry = self;
    _passwordAttribute.entry = self;
    _usernameAttribute.entry = self;
    _urlAttribute.entry = self;
    _notesAttribute.entry = self;
    _autotype.entry = self;
    _isHistory = NO;
  }
  return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
  KPKEntry *entry = [[KPKEntry allocWithZone:zone] init];
  entry.iconId = self.iconId;
  entry.iconUUID = self.iconUUID;
  entry.tree = self.tree;
  entry.parent = self.parent;
  entry.uuid = [self.uuid copyWithZone:zone];
  entry.minimumVersion = self.minimumVersion;
  
  entry.password = self.password;
  entry.title = self.title;
  entry.username = self.username;
  entry.url = self.url;
  entry.notes = self.notes;
  entry->_binaries = [[NSMutableArray alloc] initWithArray:self.binaries copyItems:YES];
  entry->_customAttributes = [[NSMutableArray alloc] initWithArray:self.customAttributes copyItems:YES];
  entry->_tags = [self.tags copyWithZone:zone];
  entry->_autotype = [self.autotype copyWithZone:zone];
  entry->_history = [[NSMutableArray alloc] initWithArray:self.history copyItems:YES];
  entry->_isHistory = self->_isHistory;
  
  entry.timeInfo = [self.timeInfo copyWithZone:zone];
  
  /* fix entry references */
  entry.autotype.entry = entry;
  for(KPKAttribute *attribute in _customAttributes) {
    attribute.entry = entry;
  }
  return entry;
}

#pragma mark NSCoding
- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if(self) {
    /* Disable timing since we init via coder */
    self.updateTiming = NO;
    _passwordAttribute = [aDecoder decodeObjectOfClass:[KPKAttribute class] forKey:NSStringFromSelector(@selector(passwordAttribute))];
    _titleAttribute= [aDecoder decodeObjectOfClass:[KPKAttribute class] forKey:NSStringFromSelector(@selector(titleAttribute))];
    _usernameAttribute = [aDecoder decodeObjectOfClass:[KPKAttribute class] forKey:NSStringFromSelector(@selector(usernameAttribute))];
    _urlAttribute = [aDecoder decodeObjectOfClass:[KPKAttribute class] forKey:NSStringFromSelector(@selector(urlAttribute))];
    _notesAttribute = [aDecoder decodeObjectOfClass:[KPKAttribute class] forKey:NSStringFromSelector(@selector(notesAttribute))];
    _binaries = [aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:NSStringFromSelector(@selector(binaries))];
    _customAttributes = [aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:NSStringFromSelector(@selector(customAttributes))];
    _tags = [aDecoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(tags))];
    _history = [aDecoder decodeObjectOfClass:[NSMutableArray class] forKey:NSStringFromSelector(@selector(history))];
    _autotype = [aDecoder decodeObjectOfClass:[KPKAutotype class] forKey:NSStringFromSelector(@selector(autotype))];
    _isHistory = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(isHistory))];
    
    _titleAttribute.entry = self;
    _passwordAttribute.entry = self;
    _usernameAttribute.entry = self;
    _urlAttribute.entry = self;
    _notesAttribute.entry = self;
    _autotype.entry = self;
    
    for(KPKAttribute *attribute in _customAttributes) {
      attribute.entry = self;
    }
    self.updateTiming = YES;
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:_passwordAttribute forKey:NSStringFromSelector(@selector(passwordAttribute))];
  [aCoder encodeObject:_titleAttribute forKey:NSStringFromSelector(@selector(titleAttribute))];
  [aCoder encodeObject:_usernameAttribute forKey:NSStringFromSelector(@selector(usernameAttribute))];
  [aCoder encodeObject:_urlAttribute forKey:NSStringFromSelector(@selector(urlAttribute))];
  [aCoder encodeObject:_notesAttribute forKey:NSStringFromSelector(@selector(notesAttribute))];
  [aCoder encodeObject:_binaries forKey:NSStringFromSelector(@selector(binaries))];
  [aCoder encodeObject:_customAttributes forKey:NSStringFromSelector(@selector(customAttributes))];
  [aCoder encodeObject:_tags forKey:NSStringFromSelector(@selector(tags))];
  [aCoder encodeObject:_history forKey:NSStringFromSelector(@selector(history))];
  [aCoder encodeObject:_autotype forKey:NSStringFromSelector(@selector(autotype))];
  [aCoder encodeBool:_isHistory forKey:NSStringFromSelector(@selector(isHistory))];
  return;
}

- (instancetype)copyWithTitle:(NSString *)title {
  KPKEntry *copy = [self copy];
  if(!title) {
    NSString *format = NSLocalizedStringFromTable(@"KPK_ENTRY_COPY_%@", @"KPKLocalizable", "");
    title = [[NSString alloc] initWithFormat:format, self.title];
  }
  /* Disbale the undomanager since we do not want the updated title to be registered */
  [copy.undoManager disableUndoRegistration];
  copy.title = title;
  [copy.undoManager enableUndoRegistration];
  //[copy.timeInfo reset];
  copy.uuid = [[NSUUID alloc] init];

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
  if([object isKindOfClass:[KPKEntry class]]) {
    return [self isEqualToEntry:object];
  }
  return NO;
}

- (BOOL)isEqualToEntry:(KPKEntry *)entry {
  NSAssert([entry isKindOfClass:[KPKEntry class]], @"Test onyl allowed with KPKEntry classes");
  
  if([self.customAttributes count] != [entry.customAttributes count]) {
    return NO;
  }
  
  NSArray *otherAttributes = [entry defaultAttributes];
  NSArray *defaultAttributes = [self defaultAttributes];
  NSAssert([otherAttributes count] == [defaultAttributes count], @"Defautl Attributes have to match size");
  for(NSUInteger index = 0; index < [defaultAttributes count]; index++) {
    KPKAttribute *attribute = defaultAttributes[index];
    KPKAttribute *other = otherAttributes[index];
    if(![other isEqualToAttribute:attribute]) {
      return NO;
    }
  }
  for(KPKAttribute *attribute in self.customAttributes) {
    KPKAttribute *otherAttribute = [entry customAttributeForKey:attribute.key];
    if(!otherAttributes) {
      return NO;
    }
    if(![otherAttribute isEqualToAttribute:attribute]) {
      return NO;
    }
  }
  return YES;
}

#pragma mark -

- (NSArray *)defaultAttributes {
  return @[ self.titleAttribute,
            self.usernameAttribute,
            self.passwordAttribute,
            self.urlAttribute,
            self.notesAttribute
            ];
}

- (BOOL)isMeta {
  /* Meta entries always contain data */
  KPKBinary *binary = [self.binaries lastObject];
  if(!binary) {
    return NO;
  }
  if([binary.data length] == 0) {
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
  if([self.notes length] == 0) {
    return NO;
  }
  return YES;
}

#pragma mark Properties
- (BOOL )protectNotes {
  return self.notesAttribute.isProtected;
}

- (BOOL)protectPassword {
  return self.passwordAttribute.isProtected;
}

- (BOOL)protectTitle {
  return self.titleAttribute.isProtected;
}

- (BOOL)protectUrl {
  return self.urlAttribute.isProtected;
}

- (BOOL)protectUsername {
  return self.usernameAttribute.isProtected;
}

- (BOOL)isEditable {
  return !self.isHistory;
}

- (NSArray *)binaries {
  return [_binaries copy];
}

- (NSArray *)customAttributes {
  return [_customAttributes copy];
}

- (NSArray *)history {
  return  [_history copy];
}

- (NSString *)title {
  return self.titleAttribute.value;
}

- (NSString *)username {
  return self.usernameAttribute.value;
}

- (NSString *)password {
  return self.passwordAttribute.value;
}

- (NSString *)notes {
  return self.notesAttribute.value;
}

- (NSString *)url {
  return self.urlAttribute.value;
}

- (void)setProtectNotes:(BOOL)protectNotes {
  self.notesAttribute.isProtected = protectNotes;
}

- (void)setProtectPassword:(BOOL)protectPassword {
  self.passwordAttribute.isProtected = protectPassword;
}

- (void)setProtectTitle:(BOOL)protectTitle {
  self.titleAttribute.isProtected = protectTitle;
}

- (void)setProtectUrl:(BOOL)protectUrl {
  self.urlAttribute.isProtected = protectUrl;
}

- (void)setProtectUsername:(BOOL)protectUsername {
  self.usernameAttribute.isProtected = protectUsername;
}

- (void)setParent:(KPKGroup *)parent {
  [super setParent:parent];
  if(self.isHistory) {
    return; // History entries should not propagate set parent;
  }
  for(KPKEntry *historyEntry in self.history) {
    historyEntry.parent = self.parent;
  }
}

- (void)setTitle:(NSString *)title {
  [self.undoManager registerUndoWithTarget:self selector:@selector(setTitle:) object:self.title];
  [self.titleAttribute setValueWithoutUndoRegistration:title];
}

- (void)setUsername:(NSString *)username {
  [self.undoManager registerUndoWithTarget:self selector:@selector(setUsername:) object:self.username];
  [self.usernameAttribute setValueWithoutUndoRegistration:username];
}

- (void)setPassword:(NSString *)password {
  [self.undoManager registerUndoWithTarget:self selector:@selector(setPassword:) object:self.password];
  [self.passwordAttribute setValueWithoutUndoRegistration:password];
}

- (void)setNotes:(NSString *)notes {
  [self.undoManager registerUndoWithTarget:self selector:@selector(setNotes:) object:self.notes];
  [self.notesAttribute setValueWithoutUndoRegistration:notes];
}

- (void)setUrl:(NSString *)url {
  [self.undoManager registerUndoWithTarget:self selector:@selector(setUrl:) object:self.url];
  [self.urlAttribute setValueWithoutUndoRegistration:url];
}

- (void)setTags:(NSString *)tags {
  if([tags isKindOfClass:[NSArray class]]) {
    tags = [(NSArray *)tags componentsJoinedByString:@","];
  }
  if([self.tags isEqualToString:tags]) {
    return; // Nothing to change
  }
  [self.undoManager registerUndoWithTarget:self selector:@selector(setTags:) object:self.tags];
  _tags = [tags copy];
}

- (KPKEntry *)asEntry {
  return self;
}

#pragma mark move/remove/copy
- (void)remove {
  /*
   Undo is handelded in the groups implementation of entry removal
   */
  [self.parent removeEntry:self];
}

- (void)moveToGroup:(KPKGroup *)group atIndex:(NSUInteger)index {
  [self.parent moveEntry:self toGroup:group atIndex:index];
}

#pragma mark CustomAttributes
- (KPKAttribute *)customAttributeForKey:(NSString *)key {
  // test for default keys;
  NSPredicate *filter = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
    return [[evaluatedObject key] isEqualToString:key];
  }];
  NSArray *filterdAttributes = [self.customAttributes filteredArrayUsingPredicate:filter];
  return [filterdAttributes lastObject];
}

- (NSString *)valueForCustomAttributeWithKey:(NSString *)key {
  KPKAttribute *attribute = [self customAttributeForKey:key];
  return attribute.value;
}

- (BOOL)hasAttributeWithKey:(NSString *)key {
  // test for default keys;
  NSPredicate *filter = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
    return [[evaluatedObject key] isEqualToString:key];
  }];
  NSArray *filterdAttributes = [self.customAttributes filteredArrayUsingPredicate:filter];
  return [filterdAttributes count] > 0;
}

-(NSString *)proposedKeyForAttributeKey:(NSString *)key {
  /*
   FIXME: Introduce some caching behaviour. We iterate over after every single edit
   */
  NSMutableSet *keys = [[NSMutableSet alloc] initWithCapacity:MAX(1,[_customAttributes count])];
  for(KPKAttribute *attribute in _customAttributes) {
    [keys addObject:attribute.key];
  }
  NSUInteger counter = 1;
  NSString *base = key;
  while([keys containsObject:key]) {
    key = [NSString stringWithFormat:@"%@-%ld", base, counter++];
  }
  return key;
}

- (void)addCustomAttribute:(KPKAttribute *)attribute {
  [self addCustomAttribute:attribute atIndex:[_customAttributes count]];
}

- (void)addCustomAttribute:(KPKAttribute *)attribute atIndex:(NSUInteger)index {
  /* TODO: sanity check if attribute has unique key */
  index = MIN([_customAttributes count], index);
  [self.undoManager registerUndoWithTarget:self selector:@selector(removeCustomAttribute:) object:attribute];
  [self insertObject:attribute inCustomAttributesAtIndex:index];
  attribute.entry = self;
  [self wasModified];
  self.minimumVersion = [self _minimumVersionForCurrentAttributes];
}

- (void)removeCustomAttribute:(KPKAttribute *)attribute {
  NSUInteger index = [_customAttributes indexOfObject:attribute];
  if(NSNotFound != index) {
    [[self.undoManager prepareWithInvocationTarget:self] addCustomAttribute:attribute atIndex:index];
    attribute.entry = nil;
    [self removeObjectFromCustomAttributesAtIndex:index];
    [self wasModified];
    self.minimumVersion = [self _minimumVersionForCurrentAttributes];
  }
}
#pragma mark Attachments

- (void)addBinary:(KPKBinary *)binary {
  [self addBinary:binary atIndex:[_binaries count]];
}

- (void)addBinary:(KPKBinary *)binary atIndex:(NSUInteger)index {
  if(nil == binary) {
    return; // nil not allowed
  }
  index = MIN([_binaries count], index);
  [self.undoManager registerUndoWithTarget:self selector:@selector(removeBinary:) object:binary];
  [self insertObject:binary inBinariesAtIndex:index];
  [self wasModified];
  self.minimumVersion = [self _minimumVersionForCurrentAttachments];
}

- (void)removeBinary:(KPKBinary *)attachment {
  /*
   Attachments are stored on entries.
   Only on load the binaries are stored ad meta entries to the tree
   So we do not need to take care of cleanup after we did
   delete an attachment
   */
  NSUInteger index = [_binaries indexOfObject:attachment];
  if(index != NSNotFound) {
    [[self.undoManager prepareWithInvocationTarget:self] addBinary:attachment atIndex:index];
    [self removeObjectFromBinariesAtIndex:index];
    [self wasModified];
    self.minimumVersion = [self _minimumVersionForCurrentAttachments];
  }
}

#pragma mark History

- (void)addHistoryEntry:(KPKEntry *)entry {
  [self addHistoryEntry:entry atIndex:[_history count]];
}

- (void)addHistoryEntry:(KPKEntry *)entry atIndex:(NSUInteger)index {
  [self insertObject:entry inHistoryAtIndex:[_history count]];
  // Update Minimum Version?
}

- (void)removeHistoryEntry:(KPKEntry *)entry {
  NSUInteger index = [self.history indexOfObject:entry];
  if(index != NSNotFound) {
    [self removeObjectFromHistoryAtIndex:index];
  }
}

- (void)clearHistory {
  for(KPKEntry *historyEntry in self.history) {
    [self removeHistoryEntry:historyEntry];
  }
}

- (NSUInteger)calculateByteSize {
  
  NSUInteger __block size = 128; // KeePass suggest this as the inital size
  
  void (^attributeBlock)(id obj, NSUInteger idx, BOOL *stop) = ^(id obj, NSUInteger idx, BOOL *stop) {
    KPKAttribute *attribute = obj;
    size += [attribute.value length];
    size += [attribute.key length];
  };
  
  /* Default attributes */
  [[self defaultAttributes] enumerateObjectsUsingBlock:attributeBlock];
  
  /* Custom attributes */
  [[self customAttributes] enumerateObjectsUsingBlock:attributeBlock];
  
  /* Binaries */
  [[self binaries] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    KPKBinary *binary = obj;
    size += [binary.key length];
    size += [binary.data length];
  }];
  
  /* Autotype */
  size += [self.autotype.defaultKeystrokeSequence length];
  [self.autotype.associations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    KPKWindowAssociation *association = obj;
    size += [association.windowTitle length];
    size += [association.keystrokeSequence length];
  }];
  
  /* Misc */
  size += [self.overrideURL length];
  size += [self.tags length];
  
  /* History */
  [[self history] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    KPKEntry *entry = obj;
    size += [entry calculateByteSize];
  }];
  
  /* Color? */
  return size;
}

#pragma mark -
#pragma mark KVO

/* CustomAttributes */
- (NSUInteger)countOfCustomAttributes {
  return [_customAttributes count];
}

- (void)insertObject:(KPKAttribute *)object inCustomAttributesAtIndex:(NSUInteger)index {
  index = MIN([_customAttributes count], index);
  [_customAttributes insertObject:object atIndex:index];
}

- (void)removeObjectFromCustomAttributesAtIndex:(NSUInteger)index {
  if(index < [_customAttributes count]) {
    [_customAttributes removeObjectAtIndex:index];
  }
}

/* Binaries */
- (NSUInteger)countOfBinaries {
  return [_binaries count];
}

- (void)insertObject:(KPKBinary *)binary inBinariesAtIndex:(NSUInteger)index {
  /* Clamp the index to make sure we do not add at wrong places */
  index = MIN([_binaries count], index);
  [_binaries insertObject:binary atIndex:index];
}

- (void)removeObjectFromBinariesAtIndex:(NSUInteger)index {
  if(index < [_binaries count]) {
    [_binaries removeObjectAtIndex:index];
  }
}

/* History */
- (NSUInteger)countOfHistory {
  return [_history count];
}

- (void)insertObject:(KPKEntry *)entry inHistoryAtIndex:(NSUInteger)index {
  index = MIN([_history count], index);
  entry.isHistory = YES;
  entry.parent = self.parent;
  NSAssert([entry.history count] == 0, @"History entries cannot hold a history of their own!");
  [_history insertObject:entry atIndex:index];
}

- (void)removeObjectFromHistoryAtIndex:(NSUInteger)index {
  if(index < [_history count]) {
    KPKEntry *historyEntry = self.history[index];
    NSAssert(historyEntry != nil, @"");
    historyEntry.isHistory = NO;
    [_history removeObjectAtIndex:index];
  }
}

#pragma mark -
#pragma mark Private Helper

- (KPKVersion)_minimumVersionForCurrentAttachments {
  return ([_binaries count] > 1 ? KPKXmlVersion : KPKLegacyVersion);
}

- (KPKVersion)_minimumVersionForCurrentAttributes {
  return ([_customAttributes count] > 0 ? KPKXmlVersion : KPKLegacyVersion);
}

@end
