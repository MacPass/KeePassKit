//
//  KPKTestModificationDates.m
//  MacPass
//
//  Created by Michael Starke on 26/10/15.
//  Copyright © 2015 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"
#import "KeePassKit_Private.h"

@interface KPKTestModificationDates : XCTestCase

@property (strong) KPKTree *tree;
@property (strong) KPKGroup *group;
@property (strong) KPKEntry *entry;

@end

@implementation KPKTestModificationDates

- (void)setUp {
  [super setUp];
  self.tree = [[KPKTree alloc] init];
  self.tree.root = [[KPKGroup alloc] init];
  self.group = self.tree.root;
  [[[KPKEntry alloc] init] addToGroup:self.group];
  self.entry = self.group.entries.firstObject;
}

- (void)tearDown {
  [super tearDown];
  self.group = nil;
  self.entry = nil;
  self.tree = nil;
}

- (void)testEnableDisableModificationRecording {
  XCTAssertTrue(self.group.updateTiming, @"updateTiming is enabled for newly created groups!");
  XCTAssertTrue(self.entry.updateTiming, @"updateTiming is enabled for newly created entries!");
  self.group.updateTiming = NO;
  self.entry.updateTiming = NO;
  XCTAssertFalse(self.group.updateTiming, @"updateTiming is disabled!");
  XCTAssertFalse(self.entry.updateTiming, @"updateTiming is disabled!");
  self.group.updateTiming = YES;
  self.entry.updateTiming = YES;
  XCTAssertTrue(self.group.updateTiming, @"updateTiming is enabled!");
  XCTAssertTrue(self.entry.updateTiming, @"updateTiming is enabled!");
}

- (void)testNodeIconIdModifcationDate {
  XCTAssertTrue(self.entry.updateTiming, @"updateTiming is enabled");
  NSDate *before = self.entry.timeInfo.modificationDate;
  self.entry.iconId = self.entry.iconId = KPKIconBattery;
  XCTAssertEqual(NSOrderedAscending, [before compare:self.entry.timeInfo.modificationDate], @"Modification date has to be updated after changing node iconID");
}

- (void)testNodeIconUUIDModifcationDate {
  XCTAssertTrue(self.entry.updateTiming, @"updateTiming is enabled");
  NSDate *before = self.entry.timeInfo.modificationDate;
  self.entry.iconUUID = [NSUUID UUID];
  XCTAssertEqual(NSOrderedAscending, [before compare:self.entry.timeInfo.modificationDate], @"Modification date has to be updated after changing node iconUUID");
}

- (void)testEntryTitleModificationDate {
  XCTAssertTrue(self.entry.updateTiming, @"updateTiming is enabled");
  NSDate *before = self.entry.timeInfo.modificationDate;
  self.entry.title = @"NewTitle";
  XCTAssertEqual(NSOrderedAscending, [before compare:self.entry.timeInfo.modificationDate], @"Modification date has to be updated after changing node title");
}

- (void)testGroupTitleModificationDate {
  XCTAssertTrue(self.group.updateTiming, @"updateTiming is enabled");
  NSDate *before = self.group.timeInfo.modificationDate;
  self.group.title = @"NewTitle";
  XCTAssertEqual(NSOrderedAscending, [before compare:self.group.timeInfo.modificationDate], @"Modification date has to be updated after changing node title");
}

- (void)testEntryNotesModificationDate {
  XCTAssertTrue(self.entry.updateTiming, @"updateTiming is enabled");
  NSDate *before = self.entry.timeInfo.modificationDate;
  self.entry.notes = @"NewTitle";
  XCTAssertEqual(NSOrderedAscending, [before compare:self.entry.timeInfo.modificationDate], @"Modification date has to be updated after changing group notes");
}

- (void)testGroupNotesModificationDate {
  XCTAssertTrue(self.group.updateTiming, @"updateTiming is enabled");
  NSDate *before = self.group.timeInfo.modificationDate;
  self.group.notes = @"NewTitle";
  XCTAssertEqual(NSOrderedAscending, [before compare:self.group.timeInfo.modificationDate], @"Modification date has to be updated after changing group notes");
}

- (void)testGroupEntryRemoveAddModificationDateInvariance {
  XCTAssertTrue(self.group.updateTiming, @"updateTiming is enabled");
  NSDate *before = self.group.timeInfo.modificationDate;
  KPKEntry *entry = [[KPKEntry alloc] init];
  [entry addToGroup:self.group];
  XCTAssertEqual(NSOrderedSame, [before compare:self.group.timeInfo.modificationDate], @"Modification of a group does not change when entry is added");

  before = self.group.timeInfo.modificationDate;
  [entry remove];
  XCTAssertEqual(NSOrderedSame, [before compare:self.group.timeInfo.modificationDate], @"Modification of a group does not change when entry is removed");
}

- (void)testEntryDefaultAttributesModifiationDate {
  static NSString *const _kUpdatedString = @"Updated";

  for(NSString *key in KPKFormat.sharedFormat.entryDefaultKeys) {
    NSDate *before = [self.entry.timeInfo.modificationDate copy];
    [self.entry _setValue:_kUpdatedString forAttributeWithKey:key];
    XCTAssertEqual(NSOrderedAscending, [before compare:self.entry.timeInfo.modificationDate], @"Modification date has to be updated after modification");
  }
}

- (void)testEntryCustomAttributeModificationDate {
  /* add custom attribute */
  NSDate *before = [self.entry.timeInfo.modificationDate copy];
  KPKAttribute *attribute = [[KPKAttribute alloc] initWithKey:@"key" value:@"value"];
  [self.entry addCustomAttribute:attribute];
  XCTAssertEqual(NSOrderedAscending, [before compare:self.entry.timeInfo.modificationDate], @"Modification date has to be updated after adding custom attribute");
  
  /* change value of custom attribute */
  before = [self.entry.timeInfo.modificationDate copy];
  attribute.value = @"newValue";
  XCTAssertEqual(NSOrderedAscending, [before compare:self.entry.timeInfo.modificationDate], @"Modification date has to be updated after change in value of custom attribute");
  
  /* change key of custom attribute */
  before = [self.entry.timeInfo.modificationDate copy];
  attribute.key = @"newKey";
  XCTAssertEqual(NSOrderedAscending, [before compare:self.entry.timeInfo.modificationDate], @"Modification date has to be updated after change in key of custom attribute");
  
  /* remove custom attribute */
  before = [self.entry.timeInfo.modificationDate copy];
  [self.entry removeCustomAttribute:attribute];
  XCTAssertEqual(NSOrderedAscending, [before compare:self.entry.timeInfo.modificationDate], @"Modification date has to be updated after custom attribute was removed");
}

- (void)testEntryAutotypeModificationDate {
  NSDate *before = [self.entry.timeInfo.modificationDate copy];
  self.entry.autotype.defaultKeystrokeSequence = @"newKeyStrokeSequence";
  KPKWindowAssociation *association = [[KPKWindowAssociation  alloc] initWithWindowTitle:@"windowTitle" keystrokeSequence:@"keys"];
  [self.entry.autotype addAssociation:association];
  XCTAssertEqual(NSOrderedAscending, [before compare:self.entry.timeInfo.modificationDate], @"Modification date has to be updated after adding a keystroke sequence");
}

@end
