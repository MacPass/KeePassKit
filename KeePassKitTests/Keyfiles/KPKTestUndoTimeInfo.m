//
//  KPKTestUndoTimeInfo.m
//  KeePassKit
//
//  Created by Michael Starke on 01/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit.h"
#import "KeePassKit_Private.h"

@interface KPKTestUndoTimeInfo : XCTestCase <KPKTreeDelegate>
@property (strong) NSUndoManager *undoManager;
@property (strong) KPKTree *tree;
@property (strong) KPKEntry *entry;
@end

@implementation KPKTestUndoTimeInfo

- (NSUndoManager *)undoManagerForTree:(KPKTree *)tree {
  return self.undoManager;
}

- (void)setUp {
  [super setUp];
  self.undoManager = [[NSUndoManager alloc] init];
  self.tree = [[KPKTree alloc] init];
  self.tree.root = [[KPKGroup alloc] init];
  self.entry = [[KPKEntry alloc] init];
  [self.entry addToGroup:self.tree.root];
  self.tree.delegate = self;}

- (void)testUndoRedoGroupExpires {
  XCTAssertFalse(self.tree.root.timeInfo.expires, @"Entry does not expire by default!");
  XCTAssertFalse(self.undoManager.canRedo, @"Undomanager has nothing to redo at first!");
  XCTAssertFalse(self.undoManager.canUndo, @"Undomanager has nothing to undo at first!");
  self.tree.root.timeInfo.expires = YES;
  XCTAssertTrue(self.tree.root.timeInfo.expires, @"Expire is set to YES!");
  XCTAssertTrue(self.undoManager.canUndo, @"Undomanger can undo!");
  XCTAssertFalse(self.undoManager.canRedo, @"Undomanger cannot redo!");
  [self.undoManager undo];
  XCTAssertFalse(self.tree.root.timeInfo.expires, @"Expire is set to NO after Undo!");
  XCTAssertFalse(self.undoManager.canUndo, @"Undomanger cannot undo!");
  XCTAssertTrue(self.undoManager.canRedo, @"Undomanger can redo!");
  [self.undoManager redo];
  XCTAssertTrue(self.tree.root.timeInfo.expires, @"Expire is set to YES after redo!");
  XCTAssertTrue(self.undoManager.canUndo, @"Undomanger is able to undo expiration change!");
  XCTAssertFalse(self.undoManager.canRedo, @"Undomanger cannot redo!");
}

- (void)testUndoRedoEntryExpires {
  XCTAssertFalse(self.entry.timeInfo.expires, @"Entry does not expire by default!");
  XCTAssertFalse(self.undoManager.canRedo, @"Undomanager has nothing to redo at first!");
  XCTAssertFalse(self.undoManager.canUndo, @"Undomanager has nothing to undo at first!");
  self.entry.timeInfo.expires = YES;
  XCTAssertTrue(self.entry.timeInfo.expires, @"Expire is set to YES!");
  XCTAssertTrue(self.undoManager.canUndo, @"Undomanger can undo!");
  XCTAssertFalse(self.undoManager.canRedo, @"Undomanger cannot redo!");
  [self.undoManager undo];
  XCTAssertFalse(self.entry.timeInfo.expires, @"Expire is set to NO after Undo!");
  XCTAssertFalse(self.undoManager.canUndo, @"Undomanger cannot undo!");
  XCTAssertTrue(self.undoManager.canRedo, @"Undomanger can redo!");
  [self.undoManager redo];
  XCTAssertTrue(self.entry.timeInfo.expires, @"Expire is set to YES after redo!");
  XCTAssertTrue(self.undoManager.canUndo, @"Undomanger is able to undo expiration change!");
  XCTAssertFalse(self.undoManager.canRedo, @"Undomanger cannot redo!");
}

- (void)testUndoRedoEntryExpirationDate {
  NSDate *oldDate = [self.entry.timeInfo.expirationDate copy];
  NSDate *now = [NSDate date];
  XCTAssertFalse(self.undoManager.canRedo, @"Undomanager has nothing to redo at first!");
  XCTAssertFalse(self.undoManager.canUndo, @"Undomanager has nothing to undo at first!");
  self.entry.timeInfo.expirationDate = now;
  XCTAssertEqualObjects(self.entry.timeInfo.expirationDate, now, @"Expiration date is set to now!");
  XCTAssertTrue(self.undoManager.canUndo, @"Undomanger can undo!");
  XCTAssertFalse(self.undoManager.canRedo, @"Undomanger cannot redo!");
  [self.undoManager undo];
  XCTAssertEqualObjects(self.entry.timeInfo.expirationDate, oldDate, @"Expiration date is set to oldDate after undo");
  XCTAssertFalse(self.undoManager.canUndo, @"Undomanger cannot undo!");
  XCTAssertTrue(self.undoManager.canRedo, @"Undomanger can redo!");
  [self.undoManager redo];
  XCTAssertEqualObjects(self.entry.timeInfo.expirationDate, now, @"Expiration date is set back to now after redo");
  XCTAssertTrue(self.undoManager.canUndo, @"Undomanger is able to undo expiration change!");
  XCTAssertFalse(self.undoManager.canRedo, @"Undomanger cannot redo!");
}

- (void)testUndoRedoGroupExpirationDate {
  NSDate *oldDate = [self.tree.root.timeInfo.expirationDate copy];
  NSDate *now = [NSDate date];
  XCTAssertFalse(self.undoManager.canRedo, @"Undomanager has nothing to redo at first!");
  XCTAssertFalse(self.undoManager.canUndo, @"Undomanager has nothing to undo at first!");
  self.tree.root.timeInfo.expirationDate = now;
  XCTAssertEqualObjects(self.tree.root.timeInfo.expirationDate, now, @"Expiration date is set to now!");
  XCTAssertTrue(self.undoManager.canUndo, @"Undomanger can undo!");
  XCTAssertFalse(self.undoManager.canRedo, @"Undomanger cannot redo!");
  [self.undoManager undo];
  XCTAssertEqualObjects(self.tree.root.timeInfo.expirationDate, oldDate, @"Expiration date is set to oldDate after undo");
  XCTAssertFalse(self.undoManager.canUndo, @"Undomanger cannot undo!");
  XCTAssertTrue(self.undoManager.canRedo, @"Undomanger can redo!");
  [self.undoManager redo];
  XCTAssertEqualObjects(self.tree.root.timeInfo.expirationDate, now, @"Expiration date is set back to now after redo");
  XCTAssertTrue(self.undoManager.canUndo, @"Undomanger is able to undo expiration change!");
  XCTAssertFalse(self.undoManager.canRedo, @"Undomanger cannot redo!");
}


@end
