//
//  KPKTestEntryLookup.m
//  MacPass
//
//  Created by Michael Starke on 21/07/15.
//  Copyright (c) 2015 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"

@interface KPKTestEntryLookup : XCTestCase
@property (strong) KPKTree *tree;
@property (weak) KPKEntry *includedInSearch;
@property (weak) KPKEntry *excludedFromSearch;
@end

@implementation KPKTestEntryLookup

- (void)setUp {
  [super setUp];
  
  KPKTree *tree = [[KPKTree alloc] init];
  KPKGroup *root = [tree createGroup:nil];
  tree.root = root;
  KPKGroup *searchableGroup = [tree createGroup:tree.root];
  KPKGroup *unsearchableGroup = [tree createGroup:tree.root];
  [searchableGroup addToGroup:tree.root];
  [unsearchableGroup addToGroup:tree.root];
  searchableGroup.isSearchEnabled = KPKInheritYES;
  unsearchableGroup.isSearchEnabled = KPKInheritNO;
  KPKEntry *entryA = [tree createEntry:searchableGroup];
  KPKEntry *entryB = [tree createEntry:unsearchableGroup];
  [entryA addToGroup:searchableGroup];
  [entryB addToGroup:unsearchableGroup];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

@end
