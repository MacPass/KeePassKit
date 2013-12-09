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

@class KPKIcon;

@implementation KPKTree

+ (KPKTree *)templateTree {

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

/*
 Kdb3Tree *tree = [[Kdb3Tree alloc] init];
 
 Kdb3Group *rootGroup = [[Kdb3Group alloc] init];
 rootGroup.name = @"%ROOT%";
 tree.root = rootGroup;
 
 KdbGroup *parentGroup = [tree createGroup:rootGroup];
 parentGroup.name = NSLocalizedString(@"GENERAL", "General");
 parentGroup.image = 48;
 [rootGroup addGroup:parentGroup];
 
 KdbGroup *group = [tree createGroup:parentGroup];
 group.name = NSLocalizedString(@"WINDOWS", "Windows");
 group.image = 38;
 [parentGroup addGroup:group];
 
 group = [tree createGroup:parentGroup];
 group.name = NSLocalizedString(@"NETWORK", "Network");
 group.image = 3;
 [parentGroup addGroup:group];
 
 group = [tree createGroup:parentGroup];
 group.name = NSLocalizedString(@"INTERNET", "Internet");
 group.image = 1;
 [parentGroup addGroup:group];
 
 group = [tree createGroup:parentGroup];
 group.name = NSLocalizedString(@"EMAIL", "EMail");
 group.image = 19;
 [parentGroup addGroup:group];
 
 group = [tree createGroup:parentGroup];
 group.name = NSLocalizedString(@"HOMEBANKING", "Homebanking");
 group.image = 37;
 [parentGroup addGroup:group];
 */


- (instancetype)init {
  self = [super init];
  if(self) {
    _metaData = [[KPKMetaData alloc] init];
    _deletedObjects = [[NSMutableDictionary alloc] init];
    _metaData.tree = self;
  }
  return self;
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
  return entry;
}

- (void)setRoot:(KPKGroup *)root {
  root.parent = nil;
  if(!_groups || [_groups count] == 0) {
    _groups = @[root];
    return;
  }
  id group = _groups[0];
  if(group != root) {
    _groups = @[root];
  }
}

- (KPKGroup *)root {
  if(_groups) {
    return _groups[0];
  }
  return nil;
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
  NSMutableArray *historyEntries = [[NSMutableArray alloc] initWithCapacity:[allEntries count] * self.metaData.historyMaxItems];
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

@end
