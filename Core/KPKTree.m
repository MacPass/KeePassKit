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
#import "KPKGroup.h"
#import "KPKEntry.h"
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

+  (KPKTree *)allocTemplateTree {

  KPKTree *tree = [[KPKTree alloc] init];
  KPKGroup *parentGroup = [tree createGroup:nil];
  
  parentGroup.name = NSLocalizedString(@"GENERAL", "General");
  parentGroup.iconId = 48;
  tree.root = parentGroup;

  KPKGroup *group = [tree createGroup:parentGroup];
  group.name = NSLocalizedString(@"WINDOWS", "Windows");
  group.iconId = 38;
  [parentGroup addGroup:group];
  
  group = [tree createGroup:parentGroup];
  group.name = NSLocalizedString(@"NETWORK", "Network");
  group.iconId = 3;
  [parentGroup addGroup:group];
  
  group = [tree createGroup:parentGroup];
  group.name = NSLocalizedString(@"INTERNET", "Internet");
  group.iconId = 1;
  [parentGroup addGroup:group];
  
  group = [tree createGroup:parentGroup];
  group.name = NSLocalizedString(@"EMAIL", "EMail");
  group.iconId = 19;
  [parentGroup addGroup:group];
  
  group = [tree createGroup:parentGroup];
  group.name = NSLocalizedString(@"HOMEBANKING", "Homebanking");
  group.iconId = 37;
  [parentGroup addGroup:group];
  
  return tree;
}

- (instancetype)init {
  self = [super init];
  if(self) {
    _metaData = [[KPKMetaData alloc] init];
    _deletedObjects = [[NSMutableDictionary alloc] init];
    _metaData.tree = self;
    _tagsMap = [[NSMutableDictionary alloc] init];
  }
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

#pragma mark -
#pragma mark Properties
- (BOOL)isEditable {
  if([self.delegate respondsToSelector:@selector(shouldEditTree:)]) {
    return  [self.delegate shouldEditTree:self];
  }
  return YES;
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
