//
//  KPKTestDeletedObjects.m
//  KeePassKit
//
//  Created by Michael Starke on 31.08.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <KeePassKit/KeePassKit.h>
#import "KeePassKit_Private.h"

@interface KPKTestDeletedObjects : XCTestCase
@property (strong) KPKTree *tree;
@property (weak) KPKGroup *groupA;
@property (weak) KPKGroup *groupB;
@property (weak) KPKGroup *subgroup;
@property (weak) KPKEntry *entry;
@property (weak) KPKEntry *subentry;
@property (weak) KPKEntry *subsubentry;

@end

@implementation KPKTestDeletedObjects

- (void)setUp {

  // root
  //   - groupA
  //     - subgroup
  //       - subsubentry
  //     - subentry
  //   - groupB
  //   - entry
 
  [super setUp];
  self.tree = [[KPKTree alloc] init];
  self.tree.root = [[KPKGroup alloc] init];
  
  
  [[[KPKGroup alloc] init] addToGroup:self.tree.root];
  self.groupA = self.tree.root.mutableGroups.lastObject;
  [[[KPKGroup alloc] init] addToGroup:self.tree.root];
  self.groupB = self.tree.root.mutableGroups.lastObject;
  [[[KPKEntry alloc] init] addToGroup:self.tree.root];
  self.entry = self.tree.root.mutableEntries.lastObject;
  
  [[[KPKGroup alloc] init] addToGroup:self.groupA];
  self.subgroup = self.groupA.mutableGroups.lastObject;
  [[[KPKEntry alloc] init] addToGroup:self.groupA];
  self.subentry = self.groupA.mutableEntries.lastObject;
  [[[KPKEntry alloc] init] addToGroup:self.subgroup];
  self.subsubentry = self.subgroup.mutableEntries.lastObject;
}

- (void)tearDown {
  self.tree = nil;
  self.groupA = nil;
  self.groupB = nil;
  self.entry = nil;
  self.subgroup = nil;
  self.subentry = nil;
  self.subsubentry = nil;
  [super tearDown];
}

- (void)testDeletedEntry {
  NSUUID *entryUUID = self.entry.uuid;
  [self.entry remove];
  XCTAssertNil([self.tree.root entryForUUID:entryUUID]);
  XCTAssertNotNil(self.tree.mutableDeletedObjects[entryUUID]);
  XCTAssertNotNil(self.tree.mutableDeletedNodes[entryUUID]);
}

- (void)testDeletedEmptyGroup {
  NSUUID *groupUUID = self.groupB.uuid;
  [self.groupB remove];
  XCTAssertNil([self.tree.root groupForUUID:groupUUID]);
  XCTAssertNotNil(self.tree.mutableDeletedObjects[groupUUID]);
  XCTAssertNotNil(self.tree.mutableDeletedNodes[groupUUID]);
}

- (void)testDeletedNonEmptyGroup {
  NSUUID *groupAUUID = self.groupA.uuid;
  NSUUID *subgroupUUID = self.subgroup.uuid;
  NSUUID *subentryUUID = self.subentry.uuid;
  NSUUID *subsubentryUUID = self.subsubentry.uuid;
  
  [self.groupA remove];
  XCTAssertNil([self.tree.root groupForUUID:groupAUUID]);
  XCTAssertNil([self.tree.root groupForUUID:subgroupUUID]);
  XCTAssertNil([self.tree.root groupForUUID:subentryUUID]);
  XCTAssertNil([self.tree.root groupForUUID:subsubentryUUID]);
  
  XCTAssertEqual(self.tree.mutableDeletedObjects.count, 4);
  XCTAssertNotNil(self.tree.mutableDeletedObjects[groupAUUID]);
  XCTAssertEqualObjects(groupAUUID,self.tree.mutableDeletedObjects[groupAUUID].uuid);
  XCTAssertNotNil(self.tree.mutableDeletedObjects[subgroupUUID]);
  XCTAssertEqualObjects(subgroupUUID,self.tree.mutableDeletedObjects[subgroupUUID].uuid);
  XCTAssertNotNil(self.tree.mutableDeletedObjects[subentryUUID]);
  XCTAssertEqualObjects(subentryUUID,self.tree.mutableDeletedObjects[subentryUUID].uuid);
  XCTAssertNotNil(self.tree.mutableDeletedObjects[subsubentryUUID]);
  XCTAssertEqualObjects(subgroupUUID,self.tree.mutableDeletedObjects[subgroupUUID].uuid);
  
  XCTAssertEqual(self.tree.mutableDeletedNodes.count, 4);
  XCTAssertNotNil(self.tree.mutableDeletedNodes[groupAUUID]);
  XCTAssertNotNil(self.tree.mutableDeletedNodes[subgroupUUID]);
  XCTAssertNotNil(self.tree.mutableDeletedNodes[subentryUUID]);
  XCTAssertNotNil(self.tree.mutableDeletedNodes[subsubentryUUID]);
}


@end
