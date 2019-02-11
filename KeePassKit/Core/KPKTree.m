//
//  KPKTree.m
//  KeePassKit
//
//  Created by Michael Starke on 11.07.13.
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

#import "KPKTree.h"
#import "KPKTree_Private.h"
#import "KPKAttribute.h"
#import "KPKEntry.h"
#import "KPKEntry_Private.h"
#import "KPKFormat.h"
#import "KPKGroup.h"
#import "KPKIconTypes.h"
#import "KPKMetaData.h"
#import "KPKMetaData_Private.h"
#import "KPKNode_Private.h"
#import "KPKTimeInfo.h"
#import "KPKKeyDerivation.h"
#import "KPKAESKeyDerivation.h"

#import "NSUUID+KPKAdditions.h"

NSString *const KPKTreeWillAddGroupNotification     = @"com.hicknhack.macpass.KPKTreeWillAddGroupNotification";
NSString *const KPKTreeDidAddGroupNotification      = @"com.hicknhack.macpass.KPKTreeDidAddGroupNotification";
NSString *const KPKTreeWillRemoveGroupNotification  = @"com.hicknhack.macpass.KPKTreeWillRemoveGroupNotification";
NSString *const KPKTreeDidRemoveGroupNotification   = @"com.hicknhack.macpass.KPKTreeDidRemoveGroupNotification";

NSString *const KPKTreeWillAddEntryNotification     = @"com.hicknhack.macpass.KPKTreeWillAddEntryNotification";
NSString *const KPKTreeDidAddEntryNotification      = @"com.hicknhack.macpass.KPKTreeDidAddEntryNotification";
NSString *const KPKTreeWillRemoveEntryNotification  = @"com.hicknhack.macpass.KPKTreeWillRemoveEntryNotification";
NSString *const KPKTreeDidRemoveEntryNotification   = @"com.hicknhack.macpass.KPKTreeDidRemoveEntryNotification";

NSString *const KPKParentGroupKey = @"KPKParentGroupKey";
NSString *const KPKGroupKey       = @"KPKGroupKey";
NSString *const KPKEntryKey       = @"KPKEntryKey";


@interface KPKTree () {
  NSCountedSet *_tags;
}
@property(nonatomic, strong) KPKMetaData *metaData;

@end

@class KPKIcon;

@implementation KPKTree

@dynamic availableTags;

+ (NSSet *)keyPathsForValuesAffectingGroups {
  return [NSSet setWithObject:NSStringFromSelector(@selector(root))];
}

+ (NSSet *)keyPathsForValuesAffectingChildren {
  return [NSSet setWithObject:NSStringFromSelector(@selector(root))];
}

- (instancetype)init {
  self = [super init];
  if(self) {
    _mutableDeletedObjects = [[NSMutableDictionary alloc] init];
    _mutableDeletedNodes = [[NSMutableDictionary alloc] init];
    _tags = [[NSCountedSet alloc] init];
    self.metaData = [[KPKMetaData alloc] init]; // use setter!
  }
  return self;
}

- (instancetype)initWithTemplateContents {
  self = [self init];
  if (self) {
  }
  KPKGroup *parentGroup = [self createGroup:nil];
  NSBundle *kpkBundle = [NSBundle bundleForClass:[self class]];
  parentGroup.title = NSLocalizedStringFromTableInBundle(@"GENERAL", nil, kpkBundle, "General");
  parentGroup.iconId = KPKIconFolder;
  self.root = parentGroup;
  
  KPKGroup *group = [self createGroup:parentGroup];
  group.title = NSLocalizedStringFromTableInBundle(@"WINDOWS", nil, kpkBundle, "Windows");
  group.iconId = KPKIconSambaUnmount;
  [group addToGroup:parentGroup];
  
  group = [self createGroup:parentGroup];
  group.title = NSLocalizedStringFromTableInBundle(@"NETWORK", nil, kpkBundle, "Network");
  group.iconId = KPKIconServer;
  [group addToGroup:parentGroup];
  
  group = [self createGroup:parentGroup];
  group.title = NSLocalizedStringFromTableInBundle(@"INTERNET", nil, kpkBundle, "Internet");
  group.iconId = KPKIconPackageNetwork;
  [group addToGroup:parentGroup];
  
  group = [self createGroup:parentGroup];
  group.title = NSLocalizedStringFromTableInBundle(@"EMAIL", nil, kpkBundle, "EMail");
  group.iconId = KPKIconEmail;
  [group addToGroup:parentGroup];
  
  group = [self createGroup:parentGroup];
  group.title = NSLocalizedStringFromTableInBundle(@"HOMEBANKING", nil, kpkBundle, "Homebanking");
  group.iconId = KPKIconPercentage;
  [group addToGroup:parentGroup];
  
  return self;
}


- (void)dealloc {
  self.metaData = nil;
  self.root = nil;
}

- (NSString *)description {
  NSMutableString *description = [[NSMutableString alloc] init];
  [description appendString:@"{\r"];
  [self.root _traverseNodesWithBlock:^(KPKNode *node, BOOL *stop) {
    [description appendFormat:@"\t%@\r", node.description];
  }];
  [description appendString:@"}"];
  return [description copy];
}


- (KPKGroup *)createGroup:(KPKGroup *)parent {
  KPKGroup *group = [[KPKGroup alloc] init];
  group.parent = parent;
  return group;
}

- (KPKEntry *)createEntry:(KPKGroup *)parent {
  KPKEntry *entry = [[KPKEntry alloc] init];
  //entry.tree = self;
  if(!parent.hasDefaultIcon) {
    entry.iconUUID = parent.iconUUID;
    entry.iconId = parent.iconId;
  }
  /* ensure default protection settings when creating a new entry */
  for(KPKAttribute *attribute in entry.mutableAttributes) {
    attribute.protect |= [self.metaData protectAttributeWithKey:attribute.key];
  }
  /* set parent at the end to prefent undo registration */
  entry.parent = parent;
  return entry;
}

- (KPKGroup *)createTrash {
  if(!self.metaData.useTrash) {
    return nil;
  }
  KPKGroup *trash = self.trash;
  if(nil != trash) {
    return trash;
  }
  trash = [self createGroup:self.root];
  trash.iconId = KPKIconTrash;
  trash.title = NSLocalizedStringFromTableInBundle(@"TRASH", nil, [NSBundle bundleForClass:[self class]], @"Name for the trash group");
  trash.isSearchEnabled = KPKInheritNO; // disable search for trash by default
  trash.isAutoTypeEnabled = KPKInheritNO; // disable autotype for trash by default
  [trash addToGroup:self.root];
  self.metaData.trashUuid = trash.uuid;
  return trash;
}

#pragma mark -
#pragma mark Properties
- (NSUndoManager *)undoManager {
  if([self.delegate respondsToSelector:@selector(undoManagerForTree:)]) {
    return [self.delegate undoManagerForTree:self];
  }
  return nil;
}

- (BOOL)isEditable {
  if([self.delegate respondsToSelector:@selector(shouldEditTree:)]) {
    return [self.delegate shouldEditTree:self];
  }
  return YES;
}

- (void)setMetaData:(KPKMetaData *)metaData {
  _metaData = metaData;
  self.metaData.tree = self;
}

- (KPKGroup *)trash {
  /* Caching is dangerous, as we might have deleted the trashcan */
  if(self.metaData.useTrash) {
    if(self.metaData.trashUuid.kpk_isNullUUID) {
      return nil;
    }
    return [self.root groupForUUID:self.metaData.trashUuid];
  }
  return nil;
}

- (void)setTrash:(KPKGroup *)trash {
  if(self.metaData.useTrash) {
    if(![self.metaData.trashUuid isEqual:trash.uuid]) {
      self.metaData.trashUuid = trash.uuid;
    }
  }
}

- (KPKGroup *)templates {
  return [self.root groupForUUID:self.metaData.entryTemplatesGroupUuid];
}

- (void)setTemplates:(KPKGroup *)templates {
  self.metaData.entryTemplatesGroupUuid = templates.uuid;
}

- (void)setRoot:(KPKGroup *)root {
  if(_root != root) {
    _root = root;
    _root.tree = self;
  }
}

- (NSArray *)groups {
  if(self.root) {
    return @[self.root];
  }
  return @[];
}

- (NSArray<KPKNode *> *)children {
  return self.root.children;
}

- (NSDictionary<NSUUID *,KPKDeletedNode *> *)deletedObjects {
  return [self.mutableDeletedObjects copy];
}

- (NSArray *)allGroups {
  return (self.root).childGroups;
}

- (NSArray *)allEntries {
  return (self.root).childEntries;
}

- (NSArray *)allHistoryEntries {
  NSArray *allEntries = self.allEntries;
  if(allEntries.count == 0) {
    return @[];
  }
  NSMutableArray *historyEntries = [[NSMutableArray alloc] init];
  for(KPKEntry *entry in allEntries) {
    NSAssert(entry.mutableHistory != nil, @"History object cannot be nil");
    [historyEntries addObjectsFromArray:entry.mutableHistory];
  }
  return historyEntries;
}

- (KPKFileVersion)minimumVersion {
  KPKFileVersion minimum = { KPKDatabaseFormatKdb, kKPKKdbFileVersion };
  BOOL aesKdf = [self.metaData.keyDerivationParameters[KPKKeyDerivationOptionUUID] isEqual:[KPKAESKeyDerivation uuid].kpk_uuidData];
  BOOL entriesInRoot = self.root.entries.count > 0;
  BOOL publicData = self.metaData.mutableCustomPublicData.count > 0;
  if( !aesKdf || entriesInRoot || publicData ) {
    minimum.format = KPKDatabaseFormatKdbx;
    minimum.version = (publicData || !aesKdf) ? kKPKKdbxFileVersion4 : kKPKKdbxFileVersion3;
  }
  if(!self.root) {
    return minimum;
  }
  return KPKFileVersionMax(minimum, self.root.minimumVersion);
}

- (NSString *)defaultAutotypeSequence {
  if([self.delegate respondsToSelector:@selector(defaultAutotypeSequenceForTree:)]) {
    return [self.delegate defaultAutotypeSequenceForTree:self];
  }
  return nil;
}

- (NSArray<NSString *> *)availableTags {
  
  return _tags.allObjects;
}


- (void)_registerTags:(NSArray<NSString *> *)tags {
  for(NSString *tag in tags) {
    [_tags addObject:tag];
  }
}

- (void)_unregisterTags:(NSArray<NSString *> *)tags  {
  for(NSString *tag in tags) {
    [_tags removeObject:tag];
  }
}


@end
