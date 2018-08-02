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
  //    - group (custom data)
  //      - subgroup
  //      - subentry
  //    - entry (custom data)
  
  [super setUp];
  self.treeA = [[KPKTree alloc] init];
  
  self.treeA.metaData.mutableCustomData[@"CustomDataKeyA"] = @"CustomDataValueA";
  self.treeA.metaData.mutableCustomData[@"CustomDataKeyB"] = @"CustomDataValueB";

  uint8_t bytes[] = {0x00, 0x01, 0x02, 0x03};
  self.treeA.metaData.mutableCustomPublicData[@"UInt32"] = [KPKNumber numberWithUnsignedInteger32:32];
  self.treeA.metaData.mutableCustomPublicData[@"UInt64"] = [KPKNumber numberWithUnsignedInteger64:64];
  self.treeA.metaData.mutableCustomPublicData[@"Int32"] = [KPKNumber numberWithInteger32:-32];
  self.treeA.metaData.mutableCustomPublicData[@"Int64"] = [KPKNumber numberWithInteger64:-64];
  self.treeA.metaData.mutableCustomPublicData[@"Data"] = [NSData dataWithBytes:bytes length:4];
  self.treeA.metaData.mutableCustomPublicData[@"String"] = @"String";
  
  
  self.treeA.root = [[KPKGroup alloc] init];
  KPKGroup *group = [[KPKGroup alloc] init];
  [group setCustomData:@"CustomGroupDataA" forKey:@"GroupKeyA"];
  [group addToGroup:self.treeA.root];
  [[[KPKGroup alloc] init] addToGroup:group];
  [[[KPKEntry alloc] init] addToGroup:group];
  KPKEntry *entry = [[KPKEntry alloc] init];
  [entry setCustomData:@"CustomEntryDataA" forKey:@"EntryKeyA"];
  [entry addToGroup:self.treeA.root];
  
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
  
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];
  
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
  
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];
  
  KPKEntry *synchronizedEntry = [self.treeA.root entryForUUID:newEntry.uuid];
  XCTAssertNotNil(synchronizedEntry);
  XCTAssertNotEqual(newEntry, synchronizedEntry, @"Entries are different objects!");
  XCTAssertEqual(KPKComparsionEqual, [newEntry compareToEntry:synchronizedEntry]);
}

- (void)testExternalDeletedEntry {
  KPKEntry *entry = [self.treeB.root entryForUUID:self.entryUUID];
  XCTAssertNotNil(entry);
  [entry remove];
  
  /* make sure entry is actually deleted */
  XCTAssertNil([self.treeB.root entryForUUID:self.entryUUID]);
  
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];
  
  /* make sure deletion was carried over */
  XCTAssertNil([self.treeA.root entryForUUID:self.entryUUID]);
}

- (void)testLocalDeletedEntry {
  KPKEntry *entry = [self.treeA.root entryForUUID:self.entryUUID];
  XCTAssertNotNil(entry);
  [entry remove];
  
  /* make sure entry is actually deleted */
  XCTAssertNil([self.treeA.root entryForUUID:self.entryUUID]);
  
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];
  
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
  [entryA _pushHistoryAndMaintain:NO];
  entryA.title = @"TitleChangeAfterDeletion";
  KPKEntry *entryACopy = [entryA copy];
  
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];
  
  /* make sure deletion was carried over */
  KPKEntry *synchronizedEntry = [self.treeA.root entryForUUID:self.entryUUID];
  XCTAssertNotNil(synchronizedEntry);
  XCTAssertEqual(entryA, synchronizedEntry, @"Objects stay the same after synchronization");
  XCTAssertNil(self.treeA.mutableDeletedObjects[self.entryUUID]);
  XCTAssertEqual(KPKComparsionEqual, [entryA compareToEntry:entryACopy]);
  XCTAssertNotEqual(entry, entryACopy, @"Entries are different objects");
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
  [entryB _pushHistoryAndMaintain:NO];
  entryB.title = @"TitleChangeAfterDeletion";
  
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];
  
  /* make sure deletion was carried over */
  KPKEntry *synchronizedEntry = [self.treeA.root entryForUUID:self.entryUUID];
  XCTAssertNotNil(synchronizedEntry);
  XCTAssertNil(self.treeA.mutableDeletedObjects[self.entryUUID]);
  XCTAssertNotEqualObjects(synchronizedEntry, entryB, @"Entries have to be different objects!");
  XCTAssertNotEqualObjects(synchronizedEntry, entry, @"Entries have to be different objects!");
  XCTAssertEqual(KPKComparsionEqual, [synchronizedEntry compareToEntry:entryB]);
  XCTAssertEqualObjects(synchronizedEntry.title, @"TitleChangeAfterDeletion");
}


- (void)testExternalAddedGroup {
  KPKGroup *newGroup = [[KPKGroup alloc] init];
  [newGroup addToGroup:self.treeB.root];
  
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];
  
  KPKGroup *synchronizedGroup = [self.treeA.root groupForUUID:newGroup.uuid];
  XCTAssertNotNil(synchronizedGroup);
  XCTAssertNotEqual(newGroup, synchronizedGroup, @"Group objects are different!");
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
  
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];
  
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
  
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];
  
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
  
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];
  
  KPKGroup *changedGroup = [self.treeA.root groupForUUID:uuid];
  XCTAssertNotNil(changedGroup);
  XCTAssertNotEqual(group, changedGroup, @"No pointer match for groups");
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
  
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];
  
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
  
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];
  
  KPKGroup *changedGroup = [self.treeA.root groupForUUID:uuid];
  XCTAssertNotNil(changedGroup);
  XCTAssertEqual(groupA, changedGroup, @"Group pointers stay the same!");
  XCTAssertEqual(KPKComparsionEqual, [changedGroup compareToGroup:groupA]);
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
  
  
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];
  
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
  
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];
  
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
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];
  
  XCTAssertEqualObjects(self.treeA.metaData.databaseName, @"NameB");
  XCTAssertEqualObjects(self.treeA.metaData.databaseNameChanged, self.treeB.metaData.databaseNameChanged);
  
  XCTAssertEqualObjects(self.treeA.metaData.databaseDescription, @"DescriptionA");
  XCTAssertNotEqualObjects(self.treeA.metaData.databaseDescriptionChanged, self.treeB.metaData.databaseDescriptionChanged);
  
  XCTAssertEqual(self.treeA.metaData.useTrash, YES);
  XCTAssertEqualObjects(self.treeA.metaData.trashChanged, self.treeB.metaData.trashChanged );
}

- (void)testAddedCustomData {
  self.treeB.metaData.mutableCustomData[@"NewKey"] = @"NewData";  
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];
  KPKMetaData *metaDataA = self.treeA.metaData;
  XCTAssertEqual(3, metaDataA.mutableCustomData.count);
  XCTAssertEqualObjects(@"CustomDataValueA", metaDataA.mutableCustomData[@"CustomDataKeyA"]);
  XCTAssertEqualObjects(@"CustomDataValueB", metaDataA.mutableCustomData[@"CustomDataKeyB"]);
  XCTAssertEqualObjects(@"NewData", metaDataA.mutableCustomData[@"NewKey"]);
}

- (void)testRemovedCustomData {
  self.treeB.metaData.mutableCustomData[@"CustomDataKeyA"] = nil;
  XCTAssertEqual(1, self.treeB.metaData.mutableCustomData.count);
  
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];
  
  KPKMetaData *metaDataA = self.treeA.metaData;
  XCTAssertEqual(2, metaDataA.mutableCustomData.count);
  XCTAssertEqualObjects(@"CustomDataValueA", metaDataA.mutableCustomData[@"CustomDataKeyA"]);
  XCTAssertEqualObjects(@"CustomDataValueB", metaDataA.mutableCustomData[@"CustomDataKeyB"]);
}

- (void)testChangedCustomData {
  
}


- (void)testRemovedPublicCustomData {
  
}

- (void)testAddedPublicCustomData {
  
}

- (void)testChangedPublicCustomData {
  
}

- (void)testRemovedCustomNodeData {
  KPKGroup *groupB = [self.treeB.root groupForUUID:self.groupUUID];
  KPKEntry *entryB = [self.treeB.root entryForUUID:self.entryUUID];
  
  usleep(10);
  
  XCTAssertEqual(groupB.mutableCustomData.count, 1);
  XCTAssertEqual(entryB.mutableCustomData.count, 1);
  [groupB removeCustomDataForKey:@"GroupKeyA"];
  [entryB removeCustomDataForKey:@"EntryKeyA"];
  XCTAssertEqual(groupB.mutableCustomData.count, 0);
  XCTAssertEqual(entryB.mutableCustomData.count, 0);
  
  KPKGroup *groupA = [self.treeA.root groupForUUID:self.groupUUID];
  XCTAssertNotEqual(groupA, groupB);
  KPKEntry *entryA = [self.treeA.root entryForUUID:self.entryUUID];
  XCTAssertNotEqual(entryA, entryB);
  XCTAssertEqual(groupA.mutableCustomData.count, 1);
  XCTAssertEqual(entryA.mutableCustomData.count, 1);
  
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];

  XCTAssertEqual(groupB.mutableCustomData.count, 0);
  XCTAssertEqual(entryB.mutableCustomData.count, 0);
}

- (void)testAddedCustomNodeData {
  KPKGroup *groupB = [self.treeB.root groupForUUID:self.groupUUID];
  KPKEntry *entryB = [self.treeB.root entryForUUID:self.entryUUID];
  
  usleep(10);
  
  XCTAssertEqual(groupB.mutableCustomData.count, 1);
  XCTAssertEqual(entryB.mutableCustomData.count, 1);
  [groupB setCustomData:@"MoreData" forKey:@"GroupMoreDataKey"];
  [entryB setCustomData:@"MoreData" forKey:@"EntryMoreDataKey"];
  XCTAssertEqual(groupB.mutableCustomData.count, 2);
  XCTAssertEqual(entryB.mutableCustomData.count, 2);
  
  KPKGroup *groupA = [self.treeA.root groupForUUID:self.groupUUID];
  XCTAssertNotEqual(groupA, groupB);
  KPKEntry *entryA = [self.treeA.root entryForUUID:self.entryUUID];
  XCTAssertNotEqual(entryA, entryB);
  XCTAssertEqual(groupA.mutableCustomData.count, 1);
  XCTAssertEqual(entryA.mutableCustomData.count, 1);
  
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];
  
  XCTAssertEqual(groupB.mutableCustomData.count, 2);
  XCTAssertEqual(entryB.mutableCustomData.count, 2);
  XCTAssertEqualObjects(entryB.mutableCustomData[@"EntryMoreDataKey"], @"MoreData");
  XCTAssertEqualObjects(groupB.mutableCustomData[@"GroupMoreDataKey"], @"MoreData");
  XCTAssertEqualObjects(entryB.mutableCustomData[@"EntryKeyA"], @"CustomEntryDataA");
  XCTAssertEqualObjects(groupB.mutableCustomData[@"GroupKeyA"], @"CustomGroupDataA");
}

- (void)testChangedCustomNodeData {
  KPKEntry *entryB = [self.treeB.root entryForUUID:self.entryUUID];
  KPKGroup *groupB = [self.treeB.root groupForUUID:self.groupUUID];
  
  usleep(10);
  
  XCTAssertEqual(entryB.mutableCustomData.count, 1);
  XCTAssertEqual(groupB.mutableCustomData.count, 1);
  
  [entryB setCustomData:@"ChangedEntryData" forKey:@"EntryKeyA"];
  [groupB setCustomData:@"ChangedGroupData" forKey:@"GroupKeyA"];
  XCTAssertEqual(entryB.mutableCustomData.count, 1);
  XCTAssertEqual(groupB.mutableCustomData.count, 1);
  
  KPKGroup *groupA = [self.treeA.root groupForUUID:self.groupUUID];
  XCTAssertNotEqual(groupA, groupB);
  KPKEntry *entryA = [self.treeA.root entryForUUID:self.entryUUID];
  XCTAssertNotEqual(entryA, entryB);
  XCTAssertEqual(groupA.mutableCustomData.count, 1);
  XCTAssertEqual(entryA.mutableCustomData.count, 1);
  XCTAssertEqualObjects(entryA.mutableCustomData[@"EntryKeyA"], @"CustomEntryDataA");
  XCTAssertEqualObjects(groupA.mutableCustomData[@"GroupKeyA"], @"CustomGroupDataA");

  
  [self.treeA synchronizeWithTree:self.treeB mode:KPKSynchronizationModeSynchronize options:0];
  
  XCTAssertEqual(groupB.mutableCustomData.count, 1);
  XCTAssertEqual(entryB.mutableCustomData.count, 1);
  XCTAssertEqualObjects(entryB.mutableCustomData[@"EntryKeyA"], @"ChangedEntryData");
  XCTAssertEqualObjects(groupB.mutableCustomData[@"GroupKeyA"], @"ChangedGroupData");
}

@end
