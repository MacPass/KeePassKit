//
//  KPKTestSynchronization.m
//  KeePassKit
//
//  Created by Michael Starke on 05/01/2017.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit.h"
#import "KeePassKit_Private.h"

@interface KPKTestSynchronization : XCTestCase
@property (strong) KPKTree *treeA;
@property (strong) KPKTree *treeB;
@property (copy) NSUUID *rootGroupUUID;
@property (copy) NSUUID *groupUUID;
@property (copy) NSUUID *subGroupUUID;
@property (copy) NSUUID *entryUUID;
@property (copy) NSUUID *subEntryUUID;

@end

@implementation KPKTestSynchronization

- (void)setUp {
  
  //
  //  rootgroup
  //    - group
  //      - subgroup
  //      - subentry
  //    - entry
  
  [super setUp];
  self.treeA = [[KPKTree alloc] init];
  
  self.treeA.root = [[KPKGroup alloc] init];
  KPKGroup *group = [[KPKGroup alloc] init];
  [group addToGroup:self.treeA.root];
  [[[KPKGroup alloc] init] addToGroup:group];
  [[[KPKEntry alloc] init] addToGroup:group];
  [[[KPKEntry alloc] init] addToGroup:self.treeA.root];
  
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"1234" key:nil];
  NSData *data = [self.treeA encryptWithKey:key format:KPKDatabaseFormatKdbx error:nil];
  /* load both trees to ensure dates are seconds precision */
  self.treeB = [[KPKTree alloc] initWithData:data key:key error:nil];
  self.treeA = [[KPKTree alloc] initWithData:data key:key error:nil];
  
  self.rootGroupUUID = self.treeA.root.uuid;
  self.groupUUID = self.treeA.root.groups.firstObject.uuid;
  self.subGroupUUID = self.treeA.root.groups.firstObject.groups.firstObject.uuid;
  self.entryUUID = self.treeA.root.entries.firstObject.uuid;
  self.subEntryUUID = self.treeA.root.groups.firstObject.entries.firstObject.uuid;
}

- (void)tearDown {
  self.treeB = nil;
  self.treeA = nil;
  
  self.rootGroupUUID = nil;
  self.groupUUID = nil;
  self.subGroupUUID = nil;
  self.entryUUID = nil;
  self.subEntryUUID = nil;
  
  [super tearDown];
}

- (void)testLocalModifiedEntry {
  KPKEntry *entryA = [self.treeA.root entryForUUID:self.entryUUID];
  
  usleep(10);
  
  /* merge will create a history entry, so supply a appropriate one */
  [entryA _pushHistoryAndMaintain:NO];
  
  entryA.title = @"TitleChanged";
  entryA.username = @"ChangedUserName";
  entryA.url = @"ChangedURL";
  
  KPKEntry *entryACopy = [entryA copy];
  [self.treeA synchronizeWithTree:self.treeB options:KPKSynchronizationSynchronizeOption];
  
  /* make sure deletion was carried over */
  KPKEntry *synchronizedEntry = [self.treeA.root entryForUUID:self.entryUUID];
  XCTAssertEqual(KPKComparsionEqual, [entryACopy compareToEntry:synchronizedEntry]);
  XCTAssertEqualObjects(@"TitleChanged", synchronizedEntry.title);
  XCTAssertEqualObjects(@"ChangedUserName", synchronizedEntry.username);
  XCTAssertEqualObjects(@"ChangedURL", synchronizedEntry.url);
}

- (void)testAddedEntry {
  KPKEntry *newEntry = [[KPKEntry alloc] init];
  [newEntry addToGroup:self.treeB.root];
  
  [self.treeA synchronizeWithTree:self.treeB options:KPKSynchronizationSynchronizeOption];
  
  KPKEntry *synchronizedEntry = [self.treeA.root entryForUUID:newEntry.uuid];
  XCTAssertNotNil(synchronizedEntry);
  XCTAssertEqual(KPKComparsionEqual, [newEntry compareToEntry:synchronizedEntry]);
}

- (void)testExternalDeletedEntry {
  KPKEntry *entry = [self.treeB.root entryForUUID:self.entryUUID];
  XCTAssertNotNil(entry);
  [entry remove];
  
  /* make sure entry is actually deleted */
  XCTAssertNil([self.treeB.root entryForUUID:self.entryUUID]);
  
  [self.treeA synchronizeWithTree:self.treeB options:KPKSynchronizationSynchronizeOption];
  
  /* make sure deletion was carried over */
  XCTAssertNil([self.treeA.root entryForUUID:self.entryUUID]);
}

- (void)testLocalDeletedEntry {
  KPKEntry *entry = [self.treeA.root entryForUUID:self.entryUUID];
  XCTAssertNotNil(entry);
  [entry remove];
  
  /* make sure entry is actually deleted */
  XCTAssertNil([self.treeA.root entryForUUID:self.entryUUID]);
  
  [self.treeA synchronizeWithTree:self.treeB options:KPKSynchronizationSynchronizeOption];
  
  /* make sure deletion was carried over */
  XCTAssertNil([self.treeA.root entryForUUID:self.entryUUID]);
  XCTAssertNotNil(self.treeA.mutableDeletedObjects[self.entryUUID]);
}

- (void)testLocalModifiedExternalDeletedEntry {
  KPKEntry *entry = [self.treeB.root entryForUUID:self.entryUUID];
  XCTAssertNotNil(entry);
  [entry remove];
  
  /* make sure entry is actually deleted */
  XCTAssertNil([self.treeB.root entryForUUID:self.entryUUID]);
  
  usleep(10);
  
  KPKEntry *entryA = [self.treeA.root entryForUUID:self.entryUUID];
  entryA.title = @"TitleChangeAfterDeletion";
  
  [self.treeA synchronizeWithTree:self.treeB options:KPKSynchronizationSynchronizeOption];
  
  /* make sure deletion was carried over */
  KPKEntry *synchronizedEntry = [self.treeA.root entryForUUID:self.entryUUID];
  XCTAssertNotNil(synchronizedEntry);
  XCTAssertNil(self.treeA.mutableDeletedObjects[self.entryUUID]);
  XCTAssertEqualObjects(synchronizedEntry, entryA);
  XCTAssertEqualObjects(synchronizedEntry.title, @"TitleChangeAfterDeletion");
}

- (void)testLocalDeletedExternalModifiedEntry {
  KPKEntry *entry = [self.treeA.root entryForUUID:self.entryUUID];
  XCTAssertNotNil(entry);
  [entry remove];
  
  /* make sure entry is actually deleted */
  XCTAssertNil([self.treeA.root entryForUUID:self.entryUUID]);
  
  usleep(10);
  
  KPKEntry *entryB = [self.treeB.root entryForUUID:self.entryUUID];
  entryB.title = @"TitleChangeAfterDeletion";
  
  [self.treeA synchronizeWithTree:self.treeB options:KPKSynchronizationSynchronizeOption];
  
  /* make sure deletion was carried over */
  KPKEntry *synchronizedEntry = [self.treeA.root entryForUUID:self.entryUUID];
  XCTAssertNotNil(synchronizedEntry);
  XCTAssertNil(self.treeA.mutableDeletedObjects[self.entryUUID]);
  XCTAssertNotEqualObjects(synchronizedEntry, entryB, @"Entries have to be different objects!");
  XCTAssertEqual(KPKComparsionEqual, [synchronizedEntry compareToEntry:entryB]);
  XCTAssertEqualObjects(synchronizedEntry.title, @"TitleChangeAfterDeletion");
}


- (void)testExternalAddedGroup {
  KPKGroup *newGroup = [[KPKGroup alloc] init];
  [newGroup addToGroup:self.treeB.root];
  
  [self.treeA synchronizeWithTree:self.treeB options:KPKSynchronizationSynchronizeOption];
  
  KPKGroup *synchronizedGroup = [self.treeA.root groupForUUID:newGroup.uuid];
  XCTAssertNotNil(synchronizedGroup);
  XCTAssertEqual(KPKComparsionEqual, [newGroup compareToGroup:synchronizedGroup]);
}

- (void)testLocalDeletedGroup {
  KPKGroup *group = [self.treeA.root groupForUUID:self.groupUUID];
  XCTAssertNotNil(group);
  [group remove];
  
  /* make sure group is actually deleted */
  XCTAssertNil([self.treeA.root groupForUUID:self.groupUUID]);
  XCTAssertNil([self.treeA.root groupForUUID:self.subGroupUUID]);
  XCTAssertNil([self.treeA.root entryForUUID:self.subEntryUUID]);
  
  [self.treeA synchronizeWithTree:self.treeB options:KPKSynchronizationSynchronizeOption];
  
  /* make sure deletion was carried over */
  XCTAssertNil([self.treeA.root groupForUUID:self.groupUUID]);
  XCTAssertNil([self.treeA.root groupForUUID:self.subGroupUUID]);
  XCTAssertNil([self.treeA.root entryForUUID:self.subEntryUUID]);
  XCTAssertNotNil(self.treeA.mutableDeletedObjects[self.groupUUID]);
  XCTAssertNotNil(self.treeA.mutableDeletedObjects[self.subGroupUUID]);
  XCTAssertNotNil(self.treeA.mutableDeletedObjects[self.subEntryUUID]);
}

- (void)testExternalDeletedGroup {
  KPKGroup *group = [self.treeB.root groupForUUID:self.groupUUID];
  XCTAssertNotNil(group);
  [group remove];
  
  /* make sure group is actually deleted */
  XCTAssertNil([self.treeB.root groupForUUID:self.groupUUID]);
  XCTAssertNil([self.treeB.root groupForUUID:self.subGroupUUID]);
  XCTAssertNil([self.treeB.root entryForUUID:self.subEntryUUID]);
  
  [self.treeA synchronizeWithTree:self.treeB options:KPKSynchronizationSynchronizeOption];
  
  /* make sure deletion was carried over */
  XCTAssertNil([self.treeA.root groupForUUID:self.groupUUID]);
  XCTAssertNil([self.treeA.root groupForUUID:self.subGroupUUID]);
  XCTAssertNil([self.treeA.root entryForUUID:self.subEntryUUID]);
  XCTAssertNotNil(self.treeA.mutableDeletedObjects[self.groupUUID]);
  XCTAssertNotNil(self.treeA.mutableDeletedObjects[self.subGroupUUID]);
  XCTAssertNotNil(self.treeA.mutableDeletedObjects[self.subEntryUUID]);
}

- (void)testChangedExternalGroup {
  KPKGroup *group = self.treeB.root.groups.firstObject;
  NSUUID *uuid = group.uuid;
  group.title = @"TheTitleHasChanged";
  
  [self.treeA synchronizeWithTree:self.treeB options:KPKSynchronizationSynchronizeOption];
  
  KPKGroup *changedGroup = [self.treeA.root groupForUUID:uuid];
  XCTAssertNotNil(changedGroup);
  XCTAssertEqual(KPKComparsionEqual, [group compareToGroup:changedGroup]);
  XCTAssertEqualObjects(changedGroup.title, @"TheTitleHasChanged");
}

- (void)testLocalModifiedExternalDeletedGroup {
  KPKGroup *group = [self.treeB.root groupForUUID:self.groupUUID];
  XCTAssertNotNil(group);
  [group remove];
  
  /* make sure group and subcontent is actually deleted */
  XCTAssertNil([self.treeB.root groupForUUID:self.groupUUID]);
  XCTAssertNil([self.treeB.root groupForUUID:self.subGroupUUID]);
  XCTAssertNil([self.treeB.root entryForUUID:self.subEntryUUID]);
  
  usleep(10);
  
  KPKGroup *groupA = [self.treeA.root groupForUUID:self.groupUUID];
  groupA.title = @"TitleChangeAfterDeletion";
  
  [self.treeA synchronizeWithTree:self.treeB options:KPKSynchronizationSynchronizeOption];
  
  /* make sure deletion was carried over */
  KPKGroup *synchronizedGroup = [self.treeA.root groupForUUID:self.groupUUID];
  XCTAssertNotNil(synchronizedGroup);
  XCTAssertNil(self.treeA.mutableDeletedObjects[self.groupUUID]);
  XCTAssertEqualObjects(synchronizedGroup, groupA);
  XCTAssertEqualObjects(synchronizedGroup.title, @"TitleChangeAfterDeletion");
  
  /* other non-modified nodes should be delete */
  XCTAssertNil([self.treeA.root groupForUUID:self.subGroupUUID]);
  XCTAssertNil([self.treeA.root entryForUUID:self.subEntryUUID]);
}


- (void)testChangedLocalGroup {
  KPKGroup *groupB = self.treeB.root.groups.firstObject;
  NSUUID *uuid = groupB.uuid;
  groupB.title = @"TheTitleHasChanged";
  
  usleep(10);
  
  KPKGroup *groupA = [self.treeA.root groupForUUID:uuid];
  groupA.title = @"ThisChangeWasLaterSoItStays";
  
  [self.treeA synchronizeWithTree:self.treeB options:KPKSynchronizationSynchronizeOption];
  
  KPKGroup *changedGroup = [self.treeA.root groupForUUID:uuid];
  XCTAssertNotNil(changedGroup);
  XCTAssertEqualObjects(changedGroup.title, @"ThisChangeWasLaterSoItStays");
}

- (void)testMovedEntry {
  //
  //  before:
  //  rootgroup
  //    - group
  //      - subgroup
  //    - entry
  //
  //  after:
  //  rootgroup
  //    - group
  //      - entry
  //      - subgroup
  //
  KPKEntry *entry = self.treeB.root.entries.firstObject;
  
  NSUUID *entryUUID = entry.uuid;
  NSUUID *groupUUID = self.treeB.root.groups.firstObject.uuid;
  
  [entry moveToGroup:self.treeB.root.groups.firstObject];
  
  
  [self.treeA synchronizeWithTree:self.treeB options:KPKSynchronizationSynchronizeOption];
  
  KPKEntry *movedEntry = [self.treeA.root entryForUUID:entryUUID];
  
  XCTAssertNotNil(movedEntry);
  XCTAssertEqualObjects(movedEntry.parent.uuid, groupUUID);
  
  NSMutableSet *uuids = [[NSMutableSet alloc] init];
  for(KPKEntry *entry in self.treeA.allEntries) {
    XCTAssertFalse([uuids containsObject:entry.uuid]);
    [uuids addObject:entry.uuid];
  }
  
  [uuids removeAllObjects];
  
  XCTAssertFalse([uuids containsObject:self.treeA.root.uuid]);
  [uuids addObject:self.treeA.root];
  for(KPKGroup *group in self.treeA.allGroups) {
    XCTAssertFalse([uuids containsObject:group.uuid]);
    [uuids addObject:group.uuid];
  }
}

- (void)testMovedGroup {
  KPKGroup *group = self.treeB.root.groups.firstObject;
  KPKGroup *subGroup = group.groups.firstObject;
  NSUUID *subGroupUUID = subGroup.uuid;
  
  [subGroup moveToGroup:self.treeB.root];
  
  [self.treeA synchronizeWithTree:self.treeB options:KPKSynchronizationSynchronizeOption];
  
  KPKGroup *movedGroup = [self.treeA.root groupForUUID:subGroupUUID];
  
  XCTAssertNotNil(movedGroup);
  XCTAssertEqualObjects(movedGroup.parent.uuid, self.treeA.root.uuid);
}
- (void)testChangedMetaData {
  /* name */
  self.treeA.metaData.databaseName = @"NameA";
  usleep(10);
  self.treeB.metaData.databaseName = @"NameB";
  
  /* desc */
  self.treeB.metaData.databaseDescription = @"DescriptionB";
  usleep(10);
  self.treeA.metaData.databaseDescription = @"DescriptionA";
  
  /* trash */
  self.treeB.metaData.useTrash = YES;
  [self.treeA synchronizeWithTree:self.treeB options:KPKSynchronizationSynchronizeOption];
  
  XCTAssertEqualObjects(self.treeA.metaData.databaseName, @"NameB");
  XCTAssertEqualObjects(self.treeA.metaData.databaseNameChanged, self.treeB.metaData.databaseNameChanged);
  
  XCTAssertEqualObjects(self.treeA.metaData.databaseDescription, @"DescriptionA");
  XCTAssertNotEqualObjects(self.treeA.metaData.databaseDescriptionChanged, self.treeB.metaData.databaseDescriptionChanged);
  
  XCTAssertEqual(self.treeA.metaData.useTrash, YES);
  XCTAssertEqualObjects(self.treeA.metaData.trashChanged, self.treeB.metaData.trashChanged );
}

- (void)testRemovedPublicCustomData {
  
}

- (void)testAddedPublicCustomData {
  
}

- (void)testChangedPublicCustomData {
  
}

- (void)testRemovedCustomData {
  
}

- (void)testAddedCustomData {
  
}

- (void)testChangedCustomData {
  
}

@end
