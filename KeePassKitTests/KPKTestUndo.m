//
//  KPKUndo.m
//  MacPass
//
//  Created by Michael Starke on 04/08/15.
//  Copyright (c) 2015 HicknHack Software GmbH. All rights reserved.
//

@import XCTest;

#import "KeePassKit.h"
#import "KeePassKit_Private.h"

@interface KPKTestUndo : XCTestCase <KPKTreeDelegate> {
  NSUndoManager *_undoManager;
  KPKTree *_tree;
  KPKGroup *_root, *_groupA, *_groupB;
  KPKEntry *_entryA, *_entryB;
}
@end

@implementation KPKTestUndo

- (NSUndoManager *)undoManagerForTree:(KPKTree *)tree {
  return _undoManager;
}

- (void)setUp {
  [super setUp];
  _undoManager = [[NSUndoManager alloc] init];
  _tree = [[KPKTree alloc] init];
  _tree.delegate = self;
  
  /*
   
   root
    +- Group A
    |   +- Entry A
    +- Group B
        +- Entry B
   
   */
  
  
  /* Disable undo registration in the setup to have a clean test environment */
  KPK_SCOPED_DISABLE_UNDO_BEGIN(_undoManager)
  
  _root = [[KPKGroup alloc] init];
  
  _tree.root = _root;
  
  _groupA = [[KPKGroup alloc] init];
  _groupA.title = @"Group A";
  _groupB = [[KPKGroup alloc] init];
  _groupB.title = @"Group B";
  
  [_groupA addToGroup:_root];
  [_groupB addToGroup:_root];
  
  _entryA = [[KPKEntry alloc] init];
  _entryA.title = @"Entry A";
  _entryA.username = @"Username A";
  _entryA.url = @"http://www.a.com";
  
  [_entryA addToGroup:_groupA];
  
  _entryB = [[KPKEntry alloc] init];
  _entryB.title = @"Entry B";
  _entryB.username = @"Username B";
  _entryB.url = @"http://www.b.com";
  
  [_entryB addToGroup:_groupB];
  
  KPK_SCOPED_DISABLE_UNDO_END
}

- (void)tearDown {
  _entryA = nil;
  _entryB = nil;
  _groupB = nil;
  _groupA = nil;
  _tree = nil;
  _undoManager = nil;
  [super tearDown];
}

- (void)testUndoRedoCreateEntry {
  
  XCTAssertFalse(_undoManager.canUndo, @"Undo stack is empty");
  XCTAssertFalse(_undoManager.canRedo, @"Redo stack is empty");
  XCTAssertEqual(_tree.deletedObjects.count, 0, @"There are no deleted objects in the database");
  
  KPKEntry *entry = [_tree createEntry:_groupA];
  KPKEntry *copy = [entry copy];
  [entry addToGroup:_groupA];
  
  XCTAssertTrue(_undoManager.canUndo, @"Undomanager can undo");
  
  XCTAssertEqual(_groupA.entries.count, 2, @"Group A has two entries");
  XCTAssertTrue([_groupA.entries containsObject:entry], @"Created entry is in group A");
  
  XCTAssertEqual(_groupB.entries.count, 1, @"Group B has one entry");
  XCTAssertFalse([_groupB.entries containsObject:entry], @"Created entry is not in group B");
  
  XCTAssertEqual(_root.entries.count, 0, @"Root has no entries");
  XCTAssertFalse([_root.entries containsObject:entry], @"Created entry is not in root group");
  
  XCTAssertEqual(_tree.deletedObjects.count, 0, @"There are no deleted objects in the database");
  
  [_undoManager undo];
  
  XCTAssertFalse(_undoManager.canUndo, @"Undomanager cannot undo anymore");
  XCTAssertTrue(_undoManager.canRedo, @"Undomanger can redo executed undo");
  
  XCTAssertEqual(_groupA.entries.count, 1, @"Group A has one entry after undo");
  XCTAssertFalse([_groupA.entries containsObject:entry], @"Created enty is not in group A");
  
  XCTAssertEqual(_groupB.entries.count, 1, @"Group B has one entry");
  XCTAssertFalse([_groupB.entries containsObject:entry], @"Created enty is not in group A");
  
  XCTAssertEqual(_root.entries.count, 0, @"Root has no entries");
  XCTAssertFalse([_root.entries containsObject:entry], @"Created enty is not in group A");
  
  XCTAssertEqual(_tree.mutableDeletedObjects.count, 1, @"There are no deleted objects in the database");
  XCTAssertEqual(_tree.mutableDeletedNodes.count, 1, @"There are no deleted objects in the database");
  XCTAssertEqual(_tree.mutableDeletedNodes[entry.uuid], entry, @"Entry is stored in deletedNodes for tree!");
  XCTAssertNotNil(_tree.mutableDeletedObjects[entry.uuid], @"DeletedObjects has record of deleted Entry");
  
  [_undoManager redo];
  
  XCTAssertTrue(_undoManager.canUndo, @"Undomanager can undo again after redo");
  XCTAssertFalse(_undoManager.canRedo, @"Undomanger cannot redo after redo");
  
  XCTAssertEqual(_groupA.entries.count, 2, @"Group A has two entries");
  XCTAssertTrue([_groupA.entries containsObject:entry], @"Created entry is in group A");
  
  XCTAssertEqual(_groupB.entries.count, 1, @"Group B has one entry");
  XCTAssertFalse([_groupB.entries containsObject:entry], @"Created entry is not in group B");
  
  XCTAssertEqual(_root.entries.count, 0, @"Root has no entries");
  XCTAssertFalse([_root.entries containsObject:entry], @"Created entry is not in root group");
  
  XCTAssertEqual(_tree.deletedObjects.count, 0, @"There are no deleted objects in the database");

  XCTAssertEqual(KPKComparsionEqual, [entry compareToEntry:copy], @"Entries has not changed fater undo/redo");
  
}

- (void)testUndoRedoCreateGroup {
  XCTAssertFalse(_undoManager.canUndo, @"Undo stack is empty");
  XCTAssertFalse(_undoManager.canRedo, @"Redo stack is empty");
  
  XCTAssertEqual(_tree.deletedObjects.count, 0, @"There are no deleted objects in the database");
  KPKGroup *group = [_tree createGroup:_tree.root];
  /* insert group between group A and B */
  [group addToGroup:_tree.root atIndex:1];
  
  XCTAssertTrue(_undoManager.canUndo, @"Undomanager can undo");
  XCTAssertFalse(_undoManager.canRedo, @"Undomanager cannot redo");
  
  XCTAssertEqual(_groupA.groups.count, 0, @"Group A has no child groups");
  XCTAssertEqual(_groupB.groups.count, 0, @"Group B has no child groups");
  
  XCTAssertEqual(_tree.root.groups.count, 3, @"Root has 3 child groups");
  XCTAssertTrue([_tree.root.groups containsObject:group], @"Created group is in root group");
  XCTAssertEqual([_tree.root.groups indexOfObject:group], 1, @"Created group is at index 1");
  
  XCTAssertEqual(_tree.deletedObjects.count, 0, @"There are no deleted objects in the database");
  
  [_undoManager undo];
  
  XCTAssertFalse(_undoManager.canUndo, @"No undo after undo");
  XCTAssertTrue(_undoManager.canRedo, @"Redo is available after undo");
  
  XCTAssertEqual(_groupA.groups.count, 0, @"Group A has no child groups");
  XCTAssertEqual(_groupB.groups.count, 0, @"Group B has no child groups");
  
  XCTAssertEqual(_tree.root.groups.count, 2, @"Root has 2 child groups");
  XCTAssertFalse([_tree.root.groups containsObject:group], @"Created group is not in root after undo");
  
  XCTAssertEqual(_tree.mutableDeletedObjects.count, 1, @"1 deleten object in tree");
  XCTAssertEqual(_tree.mutableDeletedNodes.count, 1, @"One deleted node in tree");
  XCTAssertEqual(_tree.mutableDeletedNodes[group.uuid], group, @"Group is stored in deletedNodes for tree!");
  XCTAssertNotNil(_tree.mutableDeletedObjects[group.uuid], @"DeletedObjects has record of deleted Group");
  
  [_undoManager redo];
  
  XCTAssertTrue(_undoManager.canUndo, @"Undomanager can undo after redo");
  XCTAssertFalse(_undoManager.canRedo, @"Undomanager cannot redo after redo");
  
  XCTAssertEqual(_groupA.groups.count, 0, @"Group A has no child groups after redo");
  XCTAssertEqual(_groupB.groups.count, 0, @"Group B has no child groups after redo");
  
  XCTAssertEqual(_tree.root.groups.count, 3, @"Root has 3 child groups after redo");
  XCTAssertTrue([_tree.root.groups containsObject:group], @"Created group is in root group after redo");
  XCTAssertEqual([_tree.root.groups indexOfObject:group], 1, @"Created group is at index 1 after redo");
  
  XCTAssertEqual(_tree.deletedObjects.count, 0, @"There are no deleted objects in the database");
  XCTAssertEqual(_tree.mutableDeletedNodes.count, 0, @"No deleted node in tree after redo of add");
}

- (void)testUndoRedoMoveEntry {
  
  XCTAssertFalse(_undoManager.canUndo, @"Undo stack is empty");
  XCTAssertFalse(_undoManager.canRedo, @"Redo stack is empty");
  
  XCTAssertEqual(_tree.deletedObjects.count, 0, @"There are no deleted objects in the database");
  
  XCTAssertEqual(_groupA.entries.count, 1, @"Group A has one entry");
  XCTAssertTrue([_groupA.entries containsObject:_entryA], @"Entry A is in group A");
  
  XCTAssertEqual(_groupB.entries.count, 1, @"Group B has one entry");
  XCTAssertTrue([_groupB.entries containsObject:_entryB], @"Entry B is in group B");
  
  XCTAssertEqual(_root.entries.count, 0, @"Root has no entries");
  XCTAssertFalse([_root.entries containsObject:_entryB], @"Entry A is not in root group");
  XCTAssertFalse([_root.entries containsObject:_entryA], @"Entry A is not in root group");
  
  [_entryA moveToGroup:_groupB];
  
  /*
   
   root
   +- Group A
   +- Group B
       +- Entry B
       +- Entry A
   */
  
  XCTAssertEqual(_groupA.entries.count, 0, @"Group A has no entries");
  
  XCTAssertEqual(_groupB.entries.count, 2, @"Group B has two entries");
  XCTAssertTrue([_groupB.entries containsObject:_entryA], @"Entry A is moved to group B");
  XCTAssertTrue([_groupB.entries containsObject:_entryB], @"Entry B is in group B");
  
  XCTAssertEqual(_root.entries.count, 0, @"Root has no entries");
  XCTAssertFalse([_root.entries containsObject:_entryB], @"Entry A is not in root group");
  XCTAssertFalse([_root.entries containsObject:_entryA], @"Entry A is not in root group");
  
  XCTAssertEqual(_tree.deletedObjects.count, 0, @"There are no deleted objects in the database");
  
  XCTAssertTrue(_undoManager.canUndo, @"Undomanager can undo");
  XCTAssertFalse(_undoManager.canRedo, @"Undomanager still cannot redo");
  
  [_undoManager undo];

  /*
   
   root
   +- Group A
   |   +- Entry A
   +- Group B
       +- Entry B
   
   */
  
  XCTAssertEqual(_groupA.entries.count, 1, @"Group A has one entry after undo");
  XCTAssertTrue([_groupA.entries containsObject:_entryA], @"Entry A is in group A after undo");
  
  XCTAssertEqual(_groupB.entries.count, 1, @"Group B has one entry after undo");
  XCTAssertTrue([_groupB.entries containsObject:_entryB], @"Entry B is in group B after undo");
  
  XCTAssertEqual(_root.entries.count, 0, @"Root has no entries");
  XCTAssertFalse([_root.entries containsObject:_entryA], @"Entry A is not in root group after undo");
  XCTAssertFalse([_root.entries containsObject:_entryB], @"Entry B is not in root group after undo");
  
  XCTAssertEqual(_tree.deletedObjects.count, 0, @"There are no deleted objects in the database");
  
  XCTAssertFalse(_undoManager.canUndo, @"Undomanager cannot undo anymore");
  XCTAssertTrue(_undoManager.canRedo, @"Undomanger can redo executed undo");
  
  [_undoManager redo];
  
  /*
   
   root
   +- Group A
   +- Group B
       +- Entry B
       +- Entry A
   */
  
  XCTAssertEqual(_groupA.entries.count, 0, @"Group A has no entries after redo");
  
  XCTAssertEqual(_groupB.entries.count, 2, @"Group B has two entries");
  XCTAssertTrue([_groupB.entries containsObject:_entryA], @"Entry A is moved to group B after redo");
  XCTAssertTrue([_groupB.entries containsObject:_entryB], @"Entry B is in group B");
  
  XCTAssertEqual(_root.entries.count, 0, @"Root has no entries");
  XCTAssertFalse([_root.entries containsObject:_entryA], @"Entry A is not in root group after redo");
  XCTAssertFalse([_root.entries containsObject:_entryB], @"Entry B is not in root group after redo");
  
  XCTAssertEqual(_tree.deletedObjects.count, 0, @"There are no deleted objects in the database");
  
  XCTAssertTrue(_undoManager.canUndo, @"Undomanager can undo again after redo");
  XCTAssertFalse(_undoManager.canRedo, @"Undomanager cannot redo anymore after redo");
}

- (void)testUndoRedoMoveGroup {
  XCTAssertFalse(_undoManager.canUndo, @"Undo stack is empty");
  XCTAssertFalse(_undoManager.canRedo, @"Redo stack is empty");
  
  XCTAssertEqual(_groupA.groups.count, 0, @"Group A has no child groups");
  XCTAssertEqual(_groupB.groups.count, 0, @"Group B has no child groups");
  XCTAssertEqual(_root.groups.count, 2, @"Root has two child groups");
  
  XCTAssertTrue([_root.groups containsObject:_groupA], @"Group A is in root group");
  XCTAssertTrue([_root.groups containsObject:_groupB], @"Group B is in root group");
  
  XCTAssertEqual(_tree.deletedObjects.count, 0, @"There are no deleted objects in the database");
  
  [_groupA moveToGroup:_groupB];
  
  XCTAssertTrue(_undoManager.canUndo, @"Undomanager can undo after move");
  XCTAssertFalse(_undoManager.canRedo, @"Redo stack is still empty");
  
  XCTAssertEqual(_groupA.groups.count, 0, @"Group A has no child groups");
  XCTAssertEqual(_groupB.groups.count, 1, @"Group B has one child group");
  XCTAssertTrue([_groupB.groups containsObject:_groupA], @"Group A is child group of Group B");
  XCTAssertEqual(_groupB, _groupA.parent, @"Group B is parent of Group A");
  XCTAssertEqual(_root.groups.count, 1, @"Root has one child group");
  
  XCTAssertFalse([_root.groups containsObject:_groupA], @"Group A is not root group");
  XCTAssertTrue([_root.groups containsObject:_groupB], @"Group B is in root group");
  
  XCTAssertEqual(_tree.deletedObjects.count, 0, @"There are no deleted objects in the database");
  
  [_undoManager undo];
  
  XCTAssertFalse(_undoManager.canUndo, @"Undo stack is empty after undo");
  XCTAssertTrue(_undoManager.canRedo, @"Undomanager can redo after undo");
  
  XCTAssertEqual(_groupA.groups.count, 0, @"Group A has no child groups after undo");
  XCTAssertEqual(_groupB.groups.count, 0, @"Group B has no child groups after undo");
  XCTAssertEqual(_root, _groupA.parent, @"Root is parent of Group A after undo");
  XCTAssertEqual(_root, _groupB.parent, @"Root is parent of Group B after undo");
  XCTAssertEqual(_root.groups.count, 2, @"Root has two child groups after undo");
  
  XCTAssertTrue([_root.groups containsObject:_groupA], @"Group A is in root group after undo");
  XCTAssertTrue([_root.groups containsObject:_groupB], @"Group B is in root group after undo");
  
  XCTAssertEqual(_tree.deletedObjects.count, 0, @"There are no deleted objects in the database");
  
  [_undoManager redo];
  
  XCTAssertTrue(_undoManager.canUndo, @"Undomanager can undo again after redo");
  XCTAssertFalse(_undoManager.canRedo, @"Redo stack is empty after redo");
  
  XCTAssertEqual(_groupA.groups.count, 0, @"Group A has no child groups after redo");
  XCTAssertEqual(_groupB.groups.count, 1, @"Group B has one child group after redo");
  XCTAssertTrue([_groupB.groups containsObject:_groupA], @"Group A is child group of Group B after redo");
  XCTAssertEqual(_groupB, _groupA.parent, @"Group B is parent of Group A after redo");
  XCTAssertEqual(_root.groups.count, 1, @"Root has one child group after redo");
  
  XCTAssertFalse([_root.groups containsObject:_groupA], @"Group A is not root group after redo");
  XCTAssertTrue([_root.groups containsObject:_groupB], @"Group B is in root group after redo");
  
  XCTAssertEqual(_tree.deletedObjects.count, 0, @"There are no deleted objects in the database");
}

- (void)testUndoRedoReorderGroups {
}

- (void)testUndoRedoDeleteGroupWithoutTrash {
}

- (void)testUndoRedoDeleteEntryWithoutTrash {
  XCTAssertFalse(_undoManager.canUndo, @"Undo stack is empty");
  XCTAssertFalse(_undoManager.canRedo, @"Redo stack is empty");
  
  XCTAssertEqual(_tree.deletedObjects.count, 0, @"There are no deleted objects in the database");
  
  XCTAssertEqual(_groupA.entries.count, 1, @"Group A has one entry");
  XCTAssertTrue([_groupA.entries containsObject:_entryA], @"Entry A is in group A");
  
  XCTAssertEqual(_groupB.entries.count, 1, @"Group B has one entry");
  XCTAssertTrue([_groupB.entries containsObject:_entryB], @"Entry B is in group B");
  
  XCTAssertEqual(_root.entries.count, 0, @"Root has no entries");
  XCTAssertFalse([_root.entries containsObject:_entryB], @"Entry A is not in root group");
  XCTAssertFalse([_root.entries containsObject:_entryA], @"Entry A is not in root group");
  
  KPKEntry *copy = [_entryA copy];
  [_entryA remove];
  
  XCTAssertTrue(_undoManager.canUndo, @"Deleting adds an item to the undo stack");
  XCTAssertFalse(_undoManager.canRedo, @"Redo stack is empty");
  
  XCTAssertNotNil(_tree.mutableDeletedObjects[_entryA.uuid], @"Deleted Entry is registred in deleted nodes");
  XCTAssertEqual(_tree.mutableDeletedNodes.count, 1, @"Deleted Entry node is stored in tree");
  XCTAssertEqual(_tree.mutableDeletedNodes[_entryA.uuid], _entryA, @"Deleted entry node is stored in the tree");
  
  [_undoManager undo];

  XCTAssertFalse(_undoManager.canUndo, @"Undo stack is empty after undo");
  XCTAssertTrue(_undoManager.canRedo, @"Undomanager can redo after undo");
  
  XCTAssertEqual(_tree.mutableDeletedObjects.count, 0, @"Deleted Entry node is not stored in tree");
  XCTAssertEqual(_tree.mutableDeletedNodes.count, 0, @"Deleted Entry node is not stored in tree");
  
  XCTAssertEqual(KPKComparsionEqual, [_entryA compareToEntry:copy], @"Entries has not changed fater undo/redo");
}

- (void)testUndoRedoDeleteGroupWithTrash {
}

- (void)testUndoRedoDeleteEntryWithTrash {
}

- (void)testUndoRedoEditEntry {
  XCTAssertFalse(_undoManager.canUndo, @"Undo stack is empty");
  XCTAssertFalse(_undoManager.canRedo, @"Redo stack is empty");
  
  KPKEntry *copy = [_entryA copy];
  copy.title = @"New Title";
  copy.url = @"New URL";
}

- (void)testUndoRedoEditGroup {
}



@end
