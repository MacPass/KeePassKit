//
//  KPKTestNodeForUUID.m
//  KeePassKit
//
//  Created by Michael Starke on 10/01/2017.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit.h"

@interface KPKTestNodeForUUID : XCTestCase
@property (strong) KPKTree *tree;
@end

@implementation KPKTestNodeForUUID

- (void)setUp {
  [super setUp];
  
  self.tree = [[KPKTree alloc] init];
  self.tree.root = [[KPKGroup alloc] init];
  for(NSUInteger i = 0; i < 3; i++) {
    KPKGroup *group = [self _createGroup];
    [group addToGroup:self.tree.root];
    for(NSUInteger j = 0; j < 3; j++) {
      KPKGroup *subGroup = [self _createGroup];
      [subGroup addToGroup:group];
    }
  }
}

- (void)tearDown {
  [super tearDown];
  self.tree = nil;
}

- (void)testInvalidGroupSearch {
  XCTAssertNil([self.tree.root groupForUUID:[NSUUID UUID]]);
}
- (void)testGroupSearch {
  XCTAssertEqualObjects(self.tree.root, [self.tree.root groupForUUID:self.tree.root.uuid]);
  
  KPKGroup *group = self.tree.root.groups[2];
  XCTAssertEqualObjects(group, [self.tree.root groupForUUID:group.uuid]);
  
  KPKGroup *nestedGroup = self.tree.root.groups[2].groups[2];
  XCTAssertEqualObjects(nestedGroup, [self.tree.root groupForUUID:nestedGroup.uuid]);
}

- (void)testInvalidEntrySearch {
  XCTAssertNil([self.tree.root entryForUUID:[NSUUID UUID]]);
}

- (void)testEntrySearch {
  KPKEntry *entry = self.tree.root.groups[1].entries[2];
  XCTAssertEqualObjects(entry, [self.tree.root entryForUUID:entry.uuid]);
  
  KPKEntry *nestedEntry = self.tree.root.groups[2].groups[1].entries[2];
  XCTAssertEqualObjects(nestedEntry, [self.tree.root entryForUUID:nestedEntry.uuid]);
}

- (KPKGroup *)_createGroup {
  KPKGroup *group = [[KPKGroup alloc] init];
  group.title = group.uuid.UUIDString;
  for(NSUInteger k = 0; k < 3; k++) {
    KPKEntry *entry = [[KPKEntry alloc] init];
    entry.title = entry.uuid.UUIDString;
    [entry addToGroup:group];
  }
  return group;
}

@end
