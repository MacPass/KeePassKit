//
//  KPKTextUndoCustomIcons.m
//  KeePassKitTests
//
//  Created by Michael Starke on 22.09.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit.h"
#import "KeePassKit_Private.h"

@interface KPKTestUndoCustomIcons : XCTestCase <KPKTreeDelegate> {
  NSUndoManager *_undoManager;
  KPKTree *_tree;
}

@end

@implementation KPKTestUndoCustomIcons

- (NSUndoManager *)undoManagerForTree:(KPKTree *)tree {
  return _undoManager;
}

- (void)setUp {
  [super setUp];
  _undoManager = [[NSUndoManager alloc] init];
  _tree = [[KPKTree alloc] init];
  
  [_tree.metaData addCustomIcon:[[KPKIcon alloc] init]];
  [_tree.metaData addCustomIcon:[[KPKIcon alloc] init]];
  
  _tree.root = [[KPKGroup alloc] init];
  NSUInteger groupCount = 5;
  while(groupCount--) {
    [[[KPKEntry alloc] init] addToGroup:_tree.root.mutableGroups.lastObject];
    [[[KPKGroup alloc] init] addToGroup:_tree.root];
  }
  
  /* set delegate at last to suppy a vanilla undomanager */
  _tree.delegate = self;
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void)testSetCustomIcon {
  KPKEntry *entry = _tree.root.mutableGroups.firstObject.mutableEntries.firstObject;
  KPKIcon *icon = _tree.metaData.mutableCustomIcons.firstObject;
  
  XCTAssertNil(entry.iconUUID);
  
  entry.iconUUID = icon.uuid;
  XCTAssertTrue(_undoManager.canUndo);
  XCTAssertEqualObjects(entry.iconUUID, icon.uuid);
  
  [_undoManager undo];

  XCTAssertNil(entry.iconUUID);
  XCTAssertFalse(_undoManager.canUndo);
  XCTAssertTrue(_undoManager.canRedo);
  XCTAssertNil(entry.iconUUID);
}

- (void)testAddCustomIcon {
  XCTAssertEqual(_tree.metaData.mutableCustomIcons.count, 2);
  KPKIcon *icon = [[KPKIcon alloc] init];
  
  [_tree.metaData addCustomIcon:icon];
  XCTAssertEqual(_tree.metaData.mutableCustomIcons.count, 3);
  XCTAssertEqual([_tree.metaData.mutableCustomIcons indexOfObject:icon], 2);

  [_undoManager undo];

  XCTAssertEqual(_tree.metaData.mutableCustomIcons.count, 2);
  XCTAssertEqual([_tree.metaData.mutableCustomIcons indexOfObject:icon], NSNotFound);

  [_undoManager redo];
  XCTAssertEqual(_tree.metaData.mutableCustomIcons.count, 3);
  XCTAssertEqual([_tree.metaData.mutableCustomIcons indexOfObject:icon], 2);
}

- (void)testRemoveCustomIcon {
  XCTAssertEqual(_tree.metaData.mutableCustomIcons.count, 2);
  KPKIcon *icon = _tree.metaData.mutableCustomIcons.firstObject;
  
  [_tree.metaData removeCustomIcon:icon];
  XCTAssertEqual(_tree.metaData.mutableCustomIcons.count, 1);
  XCTAssertEqual([_tree.metaData.mutableCustomIcons indexOfObject:icon], NSNotFound);
  
  [_undoManager undo];
  
  XCTAssertEqual(_tree.metaData.mutableCustomIcons.count, 2);
  XCTAssertEqual([_tree.metaData.mutableCustomIcons indexOfObject:icon], 0);
  
  [_undoManager redo];
  XCTAssertEqual(_tree.metaData.mutableCustomIcons.count, 1);
  XCTAssertEqual([_tree.metaData.mutableCustomIcons indexOfObject:icon], NSNotFound);
}

//- (void)testClearRemovedIconUUID {
//  KPKEntry *entry = _tree.root.mutableGroups.firstObject.mutableEntries.firstObject;
//  KPKGroup *group = _tree.root.mutableGroups.lastObject;
//  KPKIcon *icon = _tree.metaData.mutableCustomIcons.firstObject;
//
//  XCTAssertNil(entry.iconUUID);
//  XCTAssertNil(group.iconUUID);
//
//  entry.iconUUID = icon.uuid;
//  group.iconUUID = icon.uuid;
//
//  XCTAssertEqualObjects(entry.iconUUID, icon.uuid);
//  XCTAssertEqualObjects(group.iconUUID, icon.uuid);
//
//  [_tree.metaData removeCustomIcon:icon];
//  XCTAssertNil(entry.iconUUID);
//  XCTAssertNil(group.iconUUID);
//
//  [_undoManager undo];
//  XCTAssertEqualObjects(entry.iconUUID, icon.uuid);
//  XCTAssertEqualObjects(group.iconUUID, icon.uuid);
//
//  [_undoManager redo];
//  XCTAssertNil(entry.iconUUID);
//  XCTAssertNil(group.iconUUID);
//}

@end
