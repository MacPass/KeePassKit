//
//  KPKTestTrash.m
//  KeePassKit
//
//  Created by Michael Starke on 13.09.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit.h"

@interface KPKTestTrash : XCTestCase
@property (strong) KPKTree *tree;
@end

@implementation KPKTestTrash

- (void)setUp {
  [super setUp];
  self.tree = [[KPKTree alloc] init];
  self.tree.root = [[KPKGroup alloc] init];
  
  [[[KPKGroup alloc] init] addToGroup:self.tree.root];
  [[[KPKGroup alloc] init] addToGroup:self.tree.root];
  [[[KPKGroup alloc] init] addToGroup:self.tree.root];
  [[[KPKGroup alloc] init] addToGroup:self.tree.root];
  
  [[[KPKEntry alloc] init] addToGroup:self.tree.root];
  [[[KPKEntry alloc] init] addToGroup:self.tree.root];
  [[[KPKEntry alloc] init] addToGroup:self.tree.root];
  [[[KPKEntry alloc] init] addToGroup:self.tree.root];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void)testGroupClearing {
  [self.tree.root clear];
}

@end
