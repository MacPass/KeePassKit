//
//  KPKTestEntry.m
//  KeePassKit
//
//  Created by Michael Starke on 14/12/15.
//  Copyright © 2015 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"
#import "KeePassKit_Private.h"

@interface KPKTestNode : XCTestCase

@end

@implementation KPKTestNode

- (void)testMoveEntry {
  KPKGroup *rootGroup = [[KPKGroup alloc] init];
  KPKGroup *subGroupA = [[KPKGroup alloc] init];
  [subGroupA addToGroup:rootGroup];
  
  NSUInteger entryCount = 5;
  while(entryCount--) {
    [[[KPKEntry alloc] init] addToGroup:subGroupA];
  }
  
  KPKGroup *subGroupB = [[KPKGroup alloc] init];
  [subGroupB addToGroup:rootGroup];
  
  KPKEntry *entry = subGroupA.mutableEntries.lastObject;
  XCTAssertEqual(entry.index, subGroupA.mutableEntries.count - 1);
  [entry moveToGroup:subGroupA atIndex:0];
  XCTAssertEqual(entry.parent, subGroupA);
  XCTAssertEqual(entry.index, 0);
  
  [entry moveToGroup:subGroupB];
  XCTAssertNil([subGroupA entryForUUID:entry.uuid]);
  XCTAssertEqual(entry.index, 0);
  XCTAssertEqual(entry.parent, subGroupB);
}

- (void)testMoveGroup {
  KPKGroup *rootGroup = [[KPKGroup alloc] init];
  KPKGroup *subGroupA = [[KPKGroup alloc] init];
  [subGroupA addToGroup:rootGroup];

  NSUInteger groupCount = 5;
  while(groupCount--) {
    [[[KPKGroup alloc] init] addToGroup:subGroupA];
  }
  
  KPKGroup *subGroupB = [[KPKGroup alloc] init];
  [subGroupB addToGroup:rootGroup];
  
  KPKGroup *group = subGroupA.mutableGroups.lastObject;
  XCTAssertEqual(group.index, subGroupA.mutableGroups.count - 1);
  [group moveToGroup:subGroupA atIndex:0];
  XCTAssertEqual(group.parent, subGroupA);
  XCTAssertEqual(group.index, 0);
  
  [group moveToGroup:subGroupB];
  XCTAssertNil([subGroupA groupForUUID:group.uuid]);
  XCTAssertEqual(group.index, 0);
  XCTAssertEqual(group.parent, subGroupB);
}

- (void)testRootGroup {
  NSUInteger depth = 10;
  KPKGroup *root = [[KPKGroup alloc] init];
  KPKGroup *group = root;
  while(depth-- != 0) {
    
    [[[KPKGroup alloc] init] addToGroup:group];
    group = group.groups.firstObject;
  }
  /* Pointer have to match, not just equality! */
  XCTAssertEqual(root, root.rootGroup, @"Root group of root is root group itself!");
  XCTAssertEqual(root, group.rootGroup, @"Root group of leaf group is root itself!");
}

- (void)testNodeTraversal {
  KPKTree *tree = [[KPKTree alloc] init];
  tree.root = [[KPKGroup alloc] init];
  for(NSUInteger groupCount = 0; groupCount < 10; groupCount++ ) {
    KPKGroup *group = [[KPKGroup alloc] init];
    group.title = [NSString stringWithFormat:@"Group %ld", groupCount];
    [group addToGroup:tree.root];
    
    for(NSUInteger entryCount = 0; entryCount < 10; entryCount++) {
      KPKEntry *entry = [[KPKEntry alloc] init];
      entry.title = [NSString stringWithFormat:@"Entry %ld.%ld", groupCount, entryCount];
      [entry addToGroup:group];
    }
    
    for(NSUInteger subgGroupCount = 0; subgGroupCount < 10; subgGroupCount++ ) {
      KPKGroup *subGroup = [[KPKGroup alloc] init];
      subGroup.title = [NSString stringWithFormat:@"Group %ld.%ld", groupCount, subgGroupCount];
      [subGroup addToGroup:group];
     
      for(NSUInteger subEntryCount = 0; subEntryCount < 10; subEntryCount++) {
        KPKEntry *entry = [[KPKEntry alloc] init];
        entry.title = [NSString stringWithFormat:@"Entry %ld.%ld.%ld", groupCount, subgGroupCount, subEntryCount];
        [entry addToGroup:subGroup];
      }
    }
  }
  __block NSUInteger groupCount = 0;
  __block NSUInteger entryCount = 0;
  __block NSMutableSet <NSUUID *> *uuids = [[NSMutableSet alloc] init];
  [tree.root _traverseNodesWithOptions:0 block:^(KPKNode *node, BOOL *stop) {
    XCTAssertFalse([uuids containsObject:node.uuid]);
    if(node.asGroup) {
      groupCount++;
    }
    if(node.asEntry) {
      entryCount++;
    }
    [uuids addObject:node.uuid];
  }];
  
  XCTAssertEqual(groupCount, 10*10 + 10 + 1); /* 10*10 subgroups, 10 groups, 1 root */
  XCTAssertEqual(entryCount, 10*10 + 10*10*10); /* 10*10 entries, 10*10*10 subEntries */
  
  /* Reset */
  groupCount = 0;
  entryCount = 0;
  [uuids removeAllObjects];
  [tree.root _traverseNodesWithOptions:KPKNodeTraversalOptionSkipEntries
   block:^(KPKNode *node, BOOL *stop) {
    XCTAssertFalse([uuids containsObject:node.uuid]);
    if(node.asGroup) {
      groupCount++;
    }
    if(node.asEntry) {
      entryCount++;
    }
    [uuids addObject:node.uuid];
  }];
  
  XCTAssertEqual(groupCount, 10*10 + 10 + 1); /* 10*10 subgroups, 10 groups, 1 root */
  XCTAssertEqual(entryCount, 0);
  
  /* Reset */
  groupCount = 0;
  entryCount = 0;
  [uuids removeAllObjects];
  [tree.root _traverseNodesWithOptions:KPKNodeTraversalOptionSkipGroups
   block:^(KPKNode *node, BOOL *stop) {
    XCTAssertFalse([uuids containsObject:node.uuid]);
    if(node.asGroup) {
      groupCount++;
    }
    if(node.asEntry) {
      entryCount++;
    }
    [uuids addObject:node.uuid];
  }];
  
  XCTAssertEqual(groupCount, 0);
  XCTAssertEqual(entryCount, 10*10 + 10*10*10);
}

- (void)testCompareOptions {
  KPKGroup *group = [[KPKGroup alloc] init];
  group.title = @"A Title";
  group.iconId = KPKIconHome;
  KPKGroup *groupCopy = [group copy];
  XCTAssertEqual(KPKComparsionEqual, [group compareToGroup:groupCopy]);
  [groupCopy _regenerateUUIDs];
  XCTAssertNotEqualObjects(group.uuid, groupCopy.uuid);
  XCTAssertEqual(KPKComparsionDifferent, [group compareToGroup:groupCopy]);
  XCTAssertEqual(KPKComparsionEqual, [group _compareToNode:groupCopy options:KPKNodeCompareOptionIgnoreUUID]);
}

@end
