//
//  KPKTestUndoAutotype.m
//  KeePassKit
//
//  Created by Michael Starke on 27/06/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit.h"

@interface KPKTestUndoAutotype : XCTestCase <KPKTreeDelegate>
@property (strong) KPKTree *tree;
@property (strong) NSUndoManager *undoManager;
@property (strong) KPKEntry *entry;

@end

@implementation KPKTestUndoAutotype

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
  self.tree.delegate = self;
}

- (void)tearDown {
  [super tearDown];
}

- (void)testUndoRedoAutotypeKeystrokeSequence {
  XCTAssertFalse(self.undoManager.canUndo, @"Undomanager has nothing to undo!");
  XCTAssertFalse(self.undoManager.canRedo, @"Undomanager has nothing to redo!");
  
  XCTAssertTrue(self.entry.autotype.hasDefaultKeystrokeSequence, @"Initial autotype has default keystroke sequence!");
  
  self.entry.autotype.defaultKeystrokeSequence = @"NewDefaultKeyStrokeSequence";
  
  XCTAssertEqualObjects(self.entry.autotype.defaultKeystrokeSequence , @"NewDefaultKeyStrokeSequence", @"Keystroke sequence matches after setting it!");
  XCTAssertFalse(self.entry.autotype.hasDefaultKeystrokeSequence, @"Custom Keystroke-sequence is not default!");
  
  XCTAssertTrue(self.undoManager.canUndo, @"Changing the keystroke sequence is undoable!");
  XCTAssertFalse(self.undoManager.canRedo, @"Undomanager has nothing to redo after chaning the keystroke sequence!");
  
  [self.undoManager undo];
  
  XCTAssertFalse(self.undoManager.canUndo, @"No undoable operation left after undoing single undoable command!");
  XCTAssertTrue(self.undoManager.canRedo, @"Undomanager can redo after undo!");
  
  
  XCTAssertTrue(self.entry.autotype.hasDefaultKeystrokeSequence, @"Autotype has default keystroke sequence after undo!");
}


- (void)testUndoRedoAutotypeEnabled {

}


- (void)_assertUndoRedoEmpty {}

@end
