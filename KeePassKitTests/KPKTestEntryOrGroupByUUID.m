//
//  KPKTestEntryOrGroupByUUID.m
//  KeePassKit
//
//  Created by Michael Starke on 13/12/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

@import XCTest;
#import <KeePassKit/KeePassKit.h>

@interface KPKTestEntryOrGroupByUUID : XCTestCase

@property (strong) KPKTree *tree;

@property (copy) NSUUID *rootEntryUUID;
@property (copy) NSUUID *rootGroupUUID;
@property (copy) NSUUID *nestedGroupUUID;
@property (copy) NSUUID *nestedEntryUUID;

@property (strong) KPKGroup *rootGroup;
@property (strong) KPKEntry *rootEntry;
@property (strong) KPKGroup *nestedGroup;
@property (strong) KPKEntry *nestedEntry;

@end

@implementation KPKTestEntryOrGroupByUUID

- (void)setUp {
  [super setUp];
  self.tree = [[KPKTree alloc] init];
  self.rootGroup = [[KPKGroup alloc] init];
  self.tree.root = self.rootGroup;
  
  self.rootEntry = [[KPKEntry alloc] init];
  [self.rootEntry addToGroup:self.tree.root];
  
  self.nestedGroup = [[KPKGroup alloc] init];
  self.nestedEntry = [[KPKEntry alloc] init];
  
  [self.nestedEntry addToGroup:self.nestedGroup];
  [self.nestedGroup addToGroup:self.tree.root];
  
  
  self.rootGroupUUID = self.tree.root.uuid;
  self.rootEntryUUID = self.rootEntry.uuid;
  self.nestedGroupUUID = self.nestedGroup.uuid;
  self.nestedEntryUUID = self.nestedEntry.uuid;
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void)testFindInvalidGroup {
  XCTAssertNil([self.tree.root groupForUUID:[NSUUID UUID]]);
}

- (void)testFindInvalidEntry {
  XCTAssertNil([self.tree.root entryForUUID:[NSUUID UUID]]);
}

- (void)testSearchRootGroup {
  XCTAssertEqualObjects(self.rootGroup, [self.tree.root groupForUUID:self.rootGroupUUID]);
}

- (void)testSearchRootEntries {
  XCTAssertEqualObjects(self.rootEntry, [self.tree.root entryForUUID:self.rootEntryUUID]);
}

- (void)testFindNestedGroup {
  XCTAssertEqualObjects(self.nestedEntry, [self.tree.root entryForUUID:self.nestedEntryUUID]);
}

- (void)testFindNestedEntry {
  XCTAssertEqualObjects(self.nestedGroup, [self.tree.root groupForUUID:self.nestedGroupUUID]);
}
@end
