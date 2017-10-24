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

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  
  [super tearDown];
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
  [tree.root _traverseNodesWithOptions:0 block:^(KPKNode *node) {
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
   block:^(KPKNode *node) {
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
   block:^(KPKNode *node) {
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

@end
