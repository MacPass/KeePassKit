//
//  KPKTestSynchronization.m
//  KeePassKit
//
//  Created by Michael Starke on 05/01/2017.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit.h"

@interface KPKTestSynchronization : XCTestCase
@property (strong) KPKTree *treeA;
@property (strong) KPKTree *treeB;
@end

@implementation KPKTestSynchronization

- (void)setUp {
    [super setUp];
  self.treeA = [[KPKTree alloc] init];
  self.treeA.root = [[KPKGroup alloc] init];
  [[[KPKGroup alloc] init] addToGroup:self.treeA.root];
  [[[KPKEntry alloc] init] addToGroup:self.treeA.root];
  
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"1234" key:nil];
  NSData *data = [self.treeA encryptWithKey:key format:KPKDatabaseFormatKdbx error:nil];
  self.treeB = [[KPKTree alloc] initWithData:data key:key error:nil];
}


- (void)testAddedGroup {
  KPKGroup *newGroup = [[KPKGroup alloc] init];
  [newGroup addToGroup:self.treeB.root];
  
  [self.treeA syncronizeWithTree:self.treeB options:KPKSynchronizationSynchronizeOption];
  
  KPKGroup *synchronizedGroup = [self.treeA.root groupForUUID:newGroup.uuid];
  XCTAssertNotNil(synchronizedGroup);
  XCTAssertEqualObjects(newGroup, synchronizedGroup);
}

- (void)testChangedExternalGroup {
  KPKGroup *group = self.treeB.root.groups.firstObject;
  NSUUID *uuid = group.uuid;
  group.title = @"TheTitleHasChanged";

  [self.treeA syncronizeWithTree:self.treeB options:KPKSynchronizationSynchronizeOption];
  
  KPKGroup *changedGroup = [self.treeA.root groupForUUID:uuid];
  XCTAssertNotNil(changedGroup);
  XCTAssertEqualObjects(changedGroup.title, @"TheTitleHasChanged");
}

- (void)testChangedLocalGroup {
  KPKGroup *groupB = self.treeB.root.groups.firstObject;
  NSUUID *uuid = groupB.uuid;
  groupB.title = @"TheTitleHasChanged";
  
  KPKGroup *groupA = [self.treeA.root groupForUUID:uuid];
  groupA.title = @"ThisChangeWasLaterSoItStays";
  
  [self.treeA syncronizeWithTree:self.treeB options:KPKSynchronizationSynchronizeOption];
  
  KPKGroup *changedGroup = [self.treeA.root groupForUUID:uuid];
  XCTAssertNotNil(changedGroup);
  XCTAssertEqualObjects(changedGroup.title, @"ThisChangeWasLaterSoItStays");
}



@end
