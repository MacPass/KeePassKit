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
#import "KPKFormat.h"


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

@end

@implementation KPKEntry

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

- (id)init {
  self = [super init];
  if (self) {
    _titleAttribute = [[KPKAttribute alloc] initWithKey:KPKTitleKey value:@""];
    _passwordAttribute = [[KPKAttribute alloc] initWithKey:KPKPasswordKey value:@""];
    _usernameAttribute = [[KPKAttribute alloc] initWithKey:KPKUsernameKey value:@""];
    _urlAttribute = [[KPKAttribute alloc] initWithKey:KPKURLKey value:@""];
    _notesAttribute = [[KPKAttribute alloc] initWithKey:KPKNotesKey value:@""];
    _customAttributes = [[NSMutableArray alloc] initWithCapacity:2];
    _binaries = [[NSMutableArray alloc] initWithCapacity:2];
    _history = [[NSMutableArray alloc] initWithCapacity:5];
    _autotype = [[KPKAutotype alloc] init];
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  KPKEntry *entry = [[KPKEntry allocWithZone:zone] init];
  entry.title = self.title;
  entry.username = self.username;
  entry.url = self.url;
  entry.notes = self.notes;
  entry->_binaries = [self.binaries copyWithZone:zone];
  entry->_customAttributes = [self.customAttributes copyWithZone:zone];
  entry->_tags = [self.tags copyWithZone:zone];
  entry->_autotype = [self.autotype copyWithZone:zone];
  return entry;
}

#pragma mark NSCoding
- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if(self) {
    _titleAttribute= [aDecoder decodeObjectForKey:@"titleAttribute"];
    _usernameAttribute = [aDecoder decodeObjectForKey:@"usernameAttribute"];
    _urlAttribute = [aDecoder decodeObjectForKey:@"urlAttribute"];
    _notesAttribute = [aDecoder decodeObjectForKey:@"notesAttribute"];
    _binaries = [aDecoder decodeObjectForKey:@"binaries"];
    _customAttributes = [aDecoder decodeObjectForKey:@"customAttributes"];
    _tags = [aDecoder decodeObjectForKey:@"tags"];
    _history = [aDecoder decodeObjectForKey:@"history"];
    _autotype = [aDecoder decodeObjectForKey:@"autotype"];
    
    _titleAttribute.entry = self;
    _usernameAttribute.entry = self;
    _urlAttribute.entry = self;
    _notesAttribute.entry = self;
    _autotype.entry = self;
    
    for(KPKAttribute *attribute in _customAttributes) {
      attribute.entry = self;
    }
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [super encodeWithCoder:aCoder];
  [aCoder encodeObject:self.titleAttribute forKey:@"titleAttribute"];
  [aCoder encodeObject:self.usernameAttribute forKey:@"usernameAttribute"];
  [aCoder encodeObject:self.urlAttribute forKey:@"urlAttribute"];
  [aCoder encodeObject:self.notesAttribute forKey:@"notesAttribute"];
  [aCoder encodeObject:self.binaries forKey:@"binaries"];
  [aCoder encodeObject:self.customAttributes forKey:@"customAttributes"];
  [aCoder encodeObject:self.tags forKey:@"tags"];
  [aCoder encodeObject:self.history forKey:@"history"];
  [aCoder encodeObject:self.autotype forKey:@"autotype"];
  return;
}

- (NSArray *)defaultAttributes {
  return @[ self.titleAttribute,
            self.usernameAttribute,
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

#pragma mark Default Attributes
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

- (void)setTitle:(NSString *)title {
  [self.undoManager registerUndoWithTarget:self selector:@selector(setTitle:) object:self.title];
  self.titleAttribute.value = title;
}

- (void)setUsername:(NSString *)username {
  [self.undoManager registerUndoWithTarget:self selector:@selector(setUsername:) object:self.username];
  self.usernameAttribute.value = username;
}

- (void)setPassword:(NSString *)password {
  [self.undoManager registerUndoWithTarget:self selector:@selector(setPassword:) object:self.password];
  self.passwordAttribute.value = password;
}

- (void)setNotes:(NSString *)notes {
  [self.undoManager registerUndoWithTarget:self selector:@selector(setNotes) object:self.notes];
  self.notesAttribute.value = notes;
}

- (void)setUrl:(NSString *)url {
  [self.undoManager registerUndoWithTarget:self selector:@selector(setUrl:) object:self.url];
  self.urlAttribute.value = url;
}

- (void)remove {
  /*
   Undo is handelded in the groups implementation of entry removal
   */
  [self.parent removeEntry:self];
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
   FIXME: Introduce some cachin behaviour. We iterate over after every single edit
   */
  NSMutableSet *keys = [[NSMutableSet alloc] initWithCapacity:[_customAttributes count]];
  for(KPKAttribute *attribute in _customAttributes) {
    [keys addObject:_customAttributes.key];
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
  index = MIN([_binaries count], index);
  [self.undoManager registerUndoWithTarget:self selector:@selector(removeAttachment:) object:binary];
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
  NSSet *set = [NSSet setWithArray:_history];
  [self removeHistory:set];
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
  [_history insertObject:entry atIndex:index];
}

- (void)removeObjectFromHistoryAtIndex:(NSUInteger)index {
  if(index < [_history count]) {
    [_history removeObjectAtIndex:index];
  }
}

- (void)removeHistory:(NSSet *)objects {
  [_history removeObjectsInArray:[objects allObjects]];
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
