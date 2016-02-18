//
//  KPKTestEntry.m
//  KeePassKit
//
//  Created by Michael Starke on 14/12/15.
//  Copyright © 2015 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"

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
  XCTAssertEqualObjects(root, root.rootGroup, @"Root group of root is root group itself!");
  XCTAssertEqualObjects(root, group.rootGroup, @"Root group of leaf group is root itself!");
}

@end
