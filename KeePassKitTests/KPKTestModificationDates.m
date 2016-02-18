//
//  KPKTestModificationDates.m
//  MacPass
//
//  Created by Michael Starke on 26/10/15.
//  Copyright © 2015 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"
#import "KeePassKit+Private.h"

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
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
  self.group = nil,
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
  NSComparisonResult compare = [before compare:self.entry.timeInfo.modificationDate];
  XCTAssertTrue(compare == NSOrderedAscending, @"Modification date has to be updated after changing node iconID");
}

- (void)testNodeIconUUIDModifcationDate {
  XCTAssertTrue(self.entry.updateTiming, @"updateTiming is enabled");
  NSDate *before = self.entry.timeInfo.modificationDate;
  self.entry.iconUUID = [NSUUID UUID];
  NSComparisonResult compare = [before compare:self.entry.timeInfo.modificationDate];
  XCTAssertTrue(compare == NSOrderedAscending, @"Modification date has to be updated after changing node iconUUID");
}

- (void)testNodeTitleModificationDate {
  XCTAssertTrue(self.entry.updateTiming, @"updateTiming is enabled");
  NSDate *before = self.entry.timeInfo.modificationDate;
  self.entry.title = @"NewTitle";
  NSComparisonResult compare = [before compare:self.entry.timeInfo.modificationDate];
  XCTAssertTrue(compare == NSOrderedAscending, @"Modification date has to be updated after changing node title");
}

- (void)testGroupeNotesModificationDate {
  XCTAssertTrue(self.group.updateTiming, @"updateTiming is enabled");
  NSDate *before = self.group.timeInfo.modificationDate;
  self.group.notes = @"NewTitle";
  NSComparisonResult compare = [before compare:self.group.timeInfo.modificationDate];
  XCTAssertTrue(compare == NSOrderedAscending, @"Modification date has to be updated after changing group notes");
}


- (void)testGroupEntryModificationDate {
  XCTAssertTrue(self.group.updateTiming, @"updateTiming is enabled");
  NSDate *before = self.group.timeInfo.modificationDate;
  KPKEntry *entry = [[KPKEntry alloc] init];
  [entry addToGroup:self.group];
  NSComparisonResult compare = [before compare:self.group.timeInfo.modificationDate];
  XCTAssertTrue(compare == NSOrderedSame, @"Modification of a group does not change when entry is added");

  before = self.group.timeInfo.modificationDate;
  [entry remove];
  compare = [before compare:self.group.timeInfo.modificationDate];
  XCTAssertTrue(compare == NSOrderedSame, @"Modification of a group does not change when entry is removed");

}

- (void)testEntryDefaultAttributesModifiationDate {
  static NSString *const _kUpdatedString = @"Updated";

  for(NSString *key in [KPKFormat sharedFormat].entryDefaultKeys) {
    NSDate *before = [self.entry.timeInfo.modificationDate copy];
    [self.entry _setValue:_kUpdatedString forAttributeWithKey:key];
    NSComparisonResult compare = [before compare:self.entry.timeInfo.modificationDate];
    XCTAssertTrue(compare == NSOrderedAscending, @"Modification date has to be updated after modification");
  }
}
@end
