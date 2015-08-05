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
#import "KPKEntry.h"
#import "KPKGroup.h"
#import "KPKIconTypes.h"
#import "KPKMetaData.h"
#import "KPKTimeInfo.h"

@interface KPKTree () {
  NSMutableDictionary *_tagsMap;
}

@end

@class KPKIcon;

@implementation KPKTree

+ (NSSet *)keyPathsForValuesAffectingGroups {
  return [NSSet setWithObjects:@"root", nil];
}

- (instancetype)init {
  self = [super init];
  if(self) {
    _metaData = [[KPKMetaData alloc] init];
    _deletedObjects = [[NSMutableDictionary alloc] init];
    _tagsMap = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (instancetype)initWithTemplateContents {
  self = [self init];
  if (self) {
  }
  KPKGroup *parentGroup = [self createGroup:nil];
  
  parentGroup.title = NSLocalizedString(@"GENERAL", "General");
  parentGroup.iconId = KPKIconFolder;
  self.root = parentGroup;
  
  KPKGroup *group = [self createGroup:parentGroup];
  group.title = NSLocalizedString(@"WINDOWS", "Windows");
  group.iconId = KPKIconSambaUnmount;
  [parentGroup addGroup:group];
  
  group = [self createGroup:parentGroup];
  group.title = NSLocalizedString(@"NETWORK", "Network");
  group.iconId = KPKIconServer;
  [parentGroup addGroup:group];
  
  group = [self createGroup:parentGroup];
  group.title = NSLocalizedString(@"INTERNET", "Internet");
  group.iconId = KPKIconPackageNetwork;
  [parentGroup addGroup:group];
  
  group = [self createGroup:parentGroup];
  group.title = NSLocalizedString(@"EMAIL", "EMail");
  group.iconId = KPKIconEmail;
  [parentGroup addGroup:group];
  
  group = [self createGroup:parentGroup];
  group.title = NSLocalizedString(@"HOMEBANKING", "Homebanking");
  group.iconId = KPKIconPercentage;
  [parentGroup addGroup:group];
  
  return self;
}


- (void)dealloc {
  self.metaData = nil;
  _deletedObjects = nil;
  self.root = nil;
}

- (id)parent {
  return nil;
}

- (KPKGroup *)createGroup:(KPKGroup *)parent {
  KPKGroup *group = [[KPKGroup alloc] init];
  group.tree = self;
  group.parent = parent;
  return group;
}

- (KPKEntry *)createEntry:(KPKGroup *)parent {
  KPKEntry *entry = [[KPKEntry alloc] init];
  entry.parent = parent;
  entry.tree = self;
  if(!parent.hasDefaultIcon) {
    entry.iconUUID = parent.iconUUID;
    entry.iconId = parent.iconId;
  }
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
  trash.title = NSLocalizedString(@"TRASH", @"Name for the trash group");
  [self.root addGroup:trash];
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
    return  [self.delegate shouldEditTree:self];
  }
  return YES;
}

- (KPKGroup *)trash {
  /* Caching is dangerous, as we might have deleted the trashcan */
  if(self.metaData.useTrash) {
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

- (NSArray *)allGroups {
  return [self.root childGroups];
}

- (NSArray *)allEntries {
  return [self.root childEntries];
}

- (NSArray *)allHistoryEntries {
  NSArray *allEntries = [self allEntries];
  if([allEntries count] == 0) {
    return nil;
  }
  NSMutableArray *historyEntries = [[NSMutableArray alloc] init];
  for(KPKEntry *entry in allEntries) {
    NSAssert(entry.history != nil, @"History object cannot be nil");
    [historyEntries addObjectsFromArray:entry.history];
  }
  return historyEntries;
}

- (KPKVersion)minimumVersion {
  KPKVersion minimumVersion = KPKUnknownVersion;
  if([self.root.entries count] > 0) {
    return KPKXmlVersion;
  }
  for (KPKNode *node in self.allEntries) {
    minimumVersion = MAX(node.minimumVersion, minimumVersion);
  }
  for(KPKNode *node in self.allGroups) {
    minimumVersion = MAX(node.minimumVersion, minimumVersion);
  }
  return minimumVersion;
}

- (NSString *)defaultAutotypeSequence {
  if([self.delegate respondsToSelector:@selector(defaultAutotypeSequenceForTree:)]) {
    return [self.delegate defaultAutotypeSequenceForTree:self];
  }
  return nil;
}

- (void)registerTags:(NSString *)tags forEntry:(KPKEntry *)entry {
  NSAssert(NO, @"registerTags:forEntry: not implemented");
}

- (void)deregisterTags:(NSString *)tags forEntry:(KPKEntry *)entry {
  NSAssert(NO, @"deregisterTags:forEntry: not implemented");
}

@end
