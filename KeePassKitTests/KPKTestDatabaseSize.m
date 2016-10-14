//
//  KPKTestDatabaseSize.m
//  KeePassKit
//
//  Created by Michael Starke on 22/02/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit.h"
#import "KeePassKit_Private.h"

@interface KPKTestDatabaseSize : XCTestCase <KPKTreeDelegate> {
  NSUndoManager *_undoManager;
  KPKTree *_tree;
}
@end

@implementation KPKTestDatabaseSize

- (NSUndoManager *)undoManagerForTree:(KPKTree *)tree {
  if(tree == _tree) {
    return _undoManager;
  }
  return nil;
}

- (void)setUp {
  [super setUp];
  _undoManager = [[NSUndoManager alloc] init];
  _tree = [[KPKTree alloc] init];
  _tree.root = [[KPKGroup alloc] init];
  [[[KPKEntry alloc] init] addToGroup:_tree.root];
  _tree.delegate = self;
}

- (void)tearDown {
  [super tearDown];
}

- (void)testStorageSize {
  NSUInteger rounds = 1000;
  for(NSUInteger count = rounds; count > 0; count--) {
    [[[KPKEntry alloc] init] addToGroup:_tree.root];
    [_tree.undoManager undo];
  }
  XCTAssertEqual(_tree.root.childEntries.count, 1, @"No actual entries where added!");
  XCTAssertEqual(_tree.mutableDeletedObjects.count, rounds, @"Deleted objecst contains all removed entries via undo!");
  XCTAssertEqual(_tree.mutableDeletedNodes.count, rounds, "Deleted nodes are still references for undo!");
}


@end
