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
@property (strong) KPKTree *kdbxTreeA;
@property (strong) KPKTree *kdbxTreeB;
@property (strong) KPKTree *kdbTreeA;
@property (strong) KPKTree *kdbTreeB;
@property (copy) NSUUID *rootGroupUUID;
@property (copy) NSUUID *groupUUID;
@property (copy) NSUUID *subGroupUUID;
@property (copy) NSUUID *subSubGroupUUID;
@property (copy) NSUUID *rootEntryUUID;
@property (copy) NSUUID *entryUUID;

@end

KPKGroup *_findGroupByTitle(NSString *title, KPKTree *tree) {
  __block KPKNode *localNode = nil;
  [tree.root _traverseNodesWithOptions:KPKNodeTraversalOptionSkipEntries block:^(KPKNode *node, BOOL *stop) {
    if([node.title isEqualToString:title]) {
      localNode = node;
      *stop = YES;
    }
  }];
  return localNode.asGroup;
}

@implementation KPKTestSynchronization

- (void)setUp {
  
  //
  //  rootgroup
  //    - group (custom data)
  //      - subgroup
  //        - subsubgroup
  //      - entry
  //    - rootentry (custom data)
  
  [super setUp];
  self.kdbxTreeA = [[KPKTree alloc] init];
  
  [self.kdbxTreeA.metaData setValue:@"CustomDataValueA" forCustomDataKey:@"CustomDataKeyA"];
  [self.kdbxTreeA.metaData setValue:@"CustomDataValueB" forCustomDataKey:@"CustomDataKeyB"];
  
  uint8_t bytes[] = {0x00, 0x01, 0x02, 0x03};
  self.kdbxTreeA.metaData.mutableCustomPublicData[@"UInt32"] = [KPKNumber numberWithUnsignedInteger32:32];
  self.kdbxTreeA.metaData.mutableCustomPublicData[@"UInt64"] = [KPKNumber numberWithUnsignedInteger64:64];
  self.kdbxTreeA.metaData.mutableCustomPublicData[@"Int32"] = [KPKNumber numberWithInteger32:-32];
  self.kdbxTreeA.metaData.mutableCustomPublicData[@"Int64"] = [KPKNumber numberWithInteger64:-64];
  self.kdbxTreeA.metaData.mutableCustomPublicData[@"Data"] = [NSData dataWithBytes:bytes length:4];
  self.kdbxTreeA.metaData.mutableCustomPublicData[@"String"] = @"String";
  
  KPKIcon *icon = [[KPKIcon alloc] initWithImage:[NSImage imageNamed:NSImageNameCaution]];
  icon.name = @"Icon";
  
  [self.kdbxTreeA.metaData addCustomIcon:icon];
  
  self.kdbxTreeA.root = [[KPKGroup alloc] init];
  self.kdbxTreeA.root.title = @"RootGroup";
  KPKGroup *group = [[KPKGroup alloc] init];
  group.title = @"Group";
  [group setCustomData:@"CustomGroupDataA" forKey:@"GroupKeyA"];
  [group addToGroup:self.kdbxTreeA.root];
  KPKGroup *subGroup = [[KPKGroup alloc] init];
  subGroup.title = @"SubGroup";
  [subGroup addToGroup:group];
  [[[KPKGroup alloc] init] addToGroup:subGroup];
  subGroup.mutableGroups.firstObject.title = @"SubSubGroup";
  [[[KPKEntry alloc] init] addToGroup:group];
  group.mutableEntries.firstObject.title = @"Entry";
  KPKEntry *entry = [[KPKEntry alloc] init];
  entry.title = @"RootEntry";
  [entry setCustomData:@"CustomEntryDataA" forKey:@"EntryKeyA"];
  [entry addToGroup:self.kdbxTreeA.root];
  
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithKeys:@[[KPKKey keyWithPassword:@"1234"]]];
  NSData *kdbxData = [self.kdbxTreeA encryptWithKey:key format:KPKDatabaseFormatKdbx error:nil];
  /* load both trees to ensure dates are seconds precision */
  self.kdbxTreeB = [[KPKTree alloc] initWithData:kdbxData key:key error:nil];
  self.kdbxTreeA = [[KPKTree alloc] initWithData:kdbxData key:key error:nil];
  
  NSData *kdbData = [self.kdbxTreeA encryptWithKey:key format:KPKDatabaseFormatKdb error:nil];
  self.kdbTreeA = [[KPKTree alloc] initWithData:kdbData key:key error:nil];
  self.kdbTreeB = [[KPKTree alloc] initWithData:kdbData key:key error:nil];
  
  self.rootGroupUUID = self.kdbxTreeA.root.uuid;
  self.groupUUID = self.kdbxTreeA.root.mutableGroups.firstObject.uuid;
  self.subGroupUUID = self.kdbxTreeA.root.mutableGroups.firstObject.mutableGroups.firstObject.uuid;
  self.subSubGroupUUID = self.kdbxTreeA.root.mutableGroups.firstObject.mutableGroups.firstObject.mutableGroups.firstObject.uuid;
  self.rootEntryUUID = self.kdbxTreeA.root.mutableEntries.firstObject.uuid;
  self.entryUUID = self.kdbxTreeA.root.mutableGroups.firstObject.mutableEntries.firstObject.uuid;
}

- (void)tearDown {
  self.kdbxTreeB = nil;
  self.kdbxTreeA = nil;
  
  self.rootGroupUUID = nil;
  self.groupUUID = nil;
  self.subGroupUUID = nil;
  self.rootEntryUUID = nil;
  self.entryUUID = nil;
  
  [super tearDown];
}

- (void)testLocalModifiedEntryKBDX {
  KPKEntry *entryA = [self.kdbxTreeA.root entryForUUID:self.rootEntryUUID];
  
  usleep(10);
  
  /* merge will create a history entry, so supply a appropriate one */
  [entryA _pushHistoryAndMaintain:NO];
  
  entryA.title = @"TitleChanged";
  entryA.username = @"ChangedUserName";
  entryA.url = @"ChangedURL";
  
  KPKEntry *entryACopy = [entryA copy];
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  /* make sure deletion was carried over */
  KPKEntry *synchronizedEntry = [self.kdbxTreeA.root entryForUUID:self.rootEntryUUID];
  XCTAssertEqual(KPKComparsionEqual, [entryACopy compareToEntry:synchronizedEntry]);
  XCTAssertEqualObjects(@"TitleChanged", synchronizedEntry.title);
  XCTAssertEqualObjects(@"ChangedUserName", synchronizedEntry.username);
  XCTAssertEqualObjects(@"ChangedURL", synchronizedEntry.url);
}

- (void)testLocalModifiedEntryKDB {
  KPKEntry *entryA = [self.kdbTreeA.root entryForUUID:self.entryUUID];
  
  usleep(10);
  
  /* merge will create a history entry, so supply a appropriate one */
  [entryA _pushHistoryAndMaintain:NO];
  
  entryA.title = @"TitleChanged";
  entryA.username = @"ChangedUserName";
  entryA.url = @"ChangedURL";
  
  KPKEntry *entryACopy = [entryA copy];
  
  [self.kdbTreeA synchronizeWithTree:self.kdbTreeB mode:KPKSynchronizationModeSynchronize options:KPKSynchronizationOptionMatchGroupsByTitleOnly];
  
  /* make sure deletion was carried over */
  KPKEntry *synchronizedEntry = [self.kdbTreeA.root entryForUUID:self.entryUUID];
  XCTAssertEqual(KPKComparsionEqual, [entryACopy compareToEntry:synchronizedEntry]);
  XCTAssertEqualObjects(@"TitleChanged", synchronizedEntry.title);
  XCTAssertEqualObjects(@"ChangedUserName", synchronizedEntry.username);
  XCTAssertEqualObjects(@"ChangedURL", synchronizedEntry.url);
}


- (void)testAddedEntryKDBX {
  KPKEntry *newEntry = [[KPKEntry alloc] init];
  [newEntry addToGroup:self.kdbxTreeB.root.groups.firstObject];
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  KPKEntry *synchronizedEntry = [self.kdbxTreeA.root entryForUUID:newEntry.uuid];
  XCTAssertNotNil(synchronizedEntry);
  XCTAssertNotEqual(newEntry, synchronizedEntry, @"Entries are different objects!");
  XCTAssertEqual(KPKComparsionEqual, [newEntry compareToEntry:synchronizedEntry]);
  XCTAssertEqual(synchronizedEntry.parent, self.kdbxTreeA.root.groups.firstObject);
}

- (void)testAddedEntryKDB {
  KPKEntry *newEntry = [[KPKEntry alloc] init];
  /* add Entry to Subgroup since root group entries will get moved to first subgroup on save for KDB files */
  [newEntry addToGroup:self.kdbTreeB.root.groups.firstObject];
  
  [self.kdbTreeA synchronizeWithTree:self.kdbTreeB mode:KPKSynchronizationModeSynchronize options:KPKSynchronizationOptionMatchGroupsByTitleOnly];
  
  KPKEntry *synchronizedEntry = [self.kdbTreeA.root entryForUUID:newEntry.uuid];
  XCTAssertNotNil(synchronizedEntry);
  XCTAssertNotEqual(newEntry, synchronizedEntry, @"Entries are different objects!");
  XCTAssertEqual(KPKComparsionEqual, [newEntry compareToEntry:synchronizedEntry]);
  XCTAssertEqual(self.kdbTreeA.root.groups.firstObject, synchronizedEntry.parent);
}


- (void)testExternalDeletedEntry {
  KPKEntry *entry = [self.kdbxTreeB.root entryForUUID:self.rootEntryUUID];
  XCTAssertNotNil(entry);
  [entry remove];
  
  /* make sure entry is actually deleted */
  XCTAssertNil([self.kdbxTreeB.root entryForUUID:self.rootEntryUUID]);
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  /* make sure deletion was carried over */
  XCTAssertNil([self.kdbxTreeA.root entryForUUID:self.rootEntryUUID]);
}

- (void)testLocalDeletedEntry {
  KPKEntry *entry = [self.kdbxTreeA.root entryForUUID:self.rootEntryUUID];
  XCTAssertNotNil(entry);
  [entry remove];
  
  /* make sure entry is actually deleted */
  XCTAssertNil([self.kdbxTreeA.root entryForUUID:self.rootEntryUUID]);
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  /* make sure deletion was carried over */
  XCTAssertNil([self.kdbxTreeA.root entryForUUID:self.rootEntryUUID]);
  XCTAssertNotNil(self.kdbxTreeA.mutableDeletedObjects[self.rootEntryUUID]);
}

- (void)testLocalModifiedExternalDeletedEntry {
  KPKEntry *entry = [self.kdbxTreeB.root entryForUUID:self.rootEntryUUID];
  XCTAssertNotNil(entry);
  [entry remove];
  
  /* make sure entry is actually deleted */
  XCTAssertNil([self.kdbxTreeB.root entryForUUID:self.rootEntryUUID]);
  
  usleep(10);
  
  KPKEntry *entryA = [self.kdbxTreeA.root entryForUUID:self.rootEntryUUID];
  [entryA _pushHistoryAndMaintain:NO];
  entryA.title = @"TitleChangeAfterDeletion";
  KPKEntry *entryACopy = [entryA copy];
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  /* make sure deletion was carried over */
  KPKEntry *synchronizedEntry = [self.kdbxTreeA.root entryForUUID:self.rootEntryUUID];
  XCTAssertNotNil(synchronizedEntry);
  XCTAssertEqual(entryA, synchronizedEntry, @"Objects stay the same after synchronization");
  XCTAssertNil(self.kdbxTreeA.mutableDeletedObjects[self.rootEntryUUID]);
  XCTAssertEqual(KPKComparsionEqual, [entryA compareToEntry:entryACopy]);
  XCTAssertNotEqual(entry, entryACopy, @"Entries are different objects");
  XCTAssertEqualObjects(synchronizedEntry.title, @"TitleChangeAfterDeletion");
}

- (void)testLocalDeletedExternalModifiedEntry {
  KPKEntry *entry = [self.kdbxTreeA.root entryForUUID:self.rootEntryUUID];
  XCTAssertNotNil(entry);
  [entry remove];
  
  /* make sure entry is actually deleted */
  XCTAssertNil([self.kdbxTreeA.root entryForUUID:self.rootEntryUUID]);
  
  usleep(10);
  
  KPKEntry *entryB = [self.kdbxTreeB.root entryForUUID:self.rootEntryUUID];
  [entryB _pushHistoryAndMaintain:NO];
  entryB.title = @"TitleChangeAfterDeletion";
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  /* make sure deletion was carried over */
  KPKEntry *synchronizedEntry = [self.kdbxTreeA.root entryForUUID:self.rootEntryUUID];
  XCTAssertNotNil(synchronizedEntry);
  XCTAssertNil(self.kdbxTreeA.mutableDeletedObjects[self.rootEntryUUID]);
  XCTAssertNotEqualObjects(synchronizedEntry, entryB, @"Entries have to be different objects!");
  XCTAssertNotEqualObjects(synchronizedEntry, entry, @"Entries have to be different objects!");
  XCTAssertEqual(KPKComparsionEqual, [synchronizedEntry compareToEntry:entryB]);
  XCTAssertEqualObjects(synchronizedEntry.title, @"TitleChangeAfterDeletion");
}

- (void)testExternalAddedGroupKDBX {
  KPKGroup *newGroup = [[KPKGroup alloc] init];
  [newGroup addToGroup:self.kdbxTreeB.root];
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  KPKGroup *synchronizedGroup = [self.kdbxTreeA.root groupForUUID:newGroup.uuid];
  XCTAssertNotNil(synchronizedGroup);
  XCTAssertNotEqual(newGroup, synchronizedGroup, @"Group objects are different!");
  XCTAssertEqual(KPKComparsionEqual, [newGroup compareToGroup:synchronizedGroup]);
}

- (void)testExternalAddedGroupKDB {
  KPKGroup *newGroup = [[KPKGroup alloc] init];
  newGroup.title = @"NewGroup";
  [newGroup addToGroup:self.kdbTreeB.root];
  
  [self.kdbTreeA synchronizeWithTree:self.kdbTreeB mode:KPKSynchronizationModeSynchronize options:KPKSynchronizationOptionMatchGroupsByTitleOnly];
  
  KPKGroup *synchronizedGroup = _findGroupByTitle(newGroup.title, self.kdbTreeA);
  XCTAssertNotNil(synchronizedGroup);
  XCTAssertNotEqual(newGroup, synchronizedGroup, @"Group objects are different!");
  XCTAssertEqual(KPKComparsionEqual, [newGroup _compareToNode:synchronizedGroup options:KPKNodeCompareOptionIgnoreUUID | KPKNodeCompareOptionIgnoreGroups | KPKNodeCompareOptionIgnoreEntries]);
}

- (void)testLocalDeletedGroup {
  KPKGroup *group = [self.kdbxTreeA.root groupForUUID:self.groupUUID];
  XCTAssertNotNil(group);
  [group remove];
  
  /* make sure group is actually deleted */
  XCTAssertNil([self.kdbxTreeA.root groupForUUID:self.groupUUID]);
  XCTAssertNil([self.kdbxTreeA.root groupForUUID:self.subGroupUUID]);
  XCTAssertNil([self.kdbxTreeA.root entryForUUID:self.entryUUID]);
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  /* make sure deletion was carried over */
  XCTAssertNil([self.kdbxTreeA.root groupForUUID:self.groupUUID]);
  XCTAssertNil([self.kdbxTreeA.root groupForUUID:self.subGroupUUID]);
  XCTAssertNil([self.kdbxTreeA.root entryForUUID:self.entryUUID]);
  XCTAssertNotNil(self.kdbxTreeA.mutableDeletedObjects[self.groupUUID]);
  XCTAssertNotNil(self.kdbxTreeA.mutableDeletedObjects[self.subGroupUUID]);
  XCTAssertNotNil(self.kdbxTreeA.mutableDeletedObjects[self.entryUUID]);
}

- (void)testExternalDeletedGroup {
  KPKGroup *group = [self.kdbxTreeB.root groupForUUID:self.groupUUID];
  XCTAssertNotNil(group);
  [group remove];
  
  /* make sure group is actually deleted */
  XCTAssertNil([self.kdbxTreeB.root groupForUUID:self.groupUUID]);
  XCTAssertNil([self.kdbxTreeB.root groupForUUID:self.subGroupUUID]);
  XCTAssertNil([self.kdbxTreeB.root entryForUUID:self.entryUUID]);
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  /* make sure deletion was carried over */
  XCTAssertNil([self.kdbxTreeA.root groupForUUID:self.groupUUID]);
  XCTAssertNil([self.kdbxTreeA.root groupForUUID:self.subGroupUUID]);
  XCTAssertNil([self.kdbxTreeA.root entryForUUID:self.entryUUID]);
  XCTAssertNotNil(self.kdbxTreeA.mutableDeletedObjects[self.groupUUID]);
  XCTAssertNotNil(self.kdbxTreeA.mutableDeletedObjects[self.subGroupUUID]);
  XCTAssertNotNil(self.kdbxTreeA.mutableDeletedObjects[self.entryUUID]);
}

- (void)testChangedExternalGroup {
  KPKGroup *group = self.kdbxTreeB.root.groups.firstObject;
  NSUUID *uuid = group.uuid;
  group.title = @"TheTitleHasChanged";
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  KPKGroup *changedGroup = [self.kdbxTreeA.root groupForUUID:uuid];
  XCTAssertNotNil(changedGroup);
  XCTAssertNotEqual(group, changedGroup, @"No pointer match for groups");
  XCTAssertEqual(KPKComparsionEqual, [group compareToGroup:changedGroup]);
  XCTAssertEqualObjects(changedGroup.title, @"TheTitleHasChanged");
}

- (void)testLocalModifiedExternalDeletedGroup {
  KPKGroup *group = [self.kdbxTreeB.root groupForUUID:self.groupUUID];
  XCTAssertNotNil(group);
  [group remove];
  
  /* make sure group and subcontent is actually deleted */
  XCTAssertNil([self.kdbxTreeB.root groupForUUID:self.groupUUID]);
  XCTAssertNil([self.kdbxTreeB.root groupForUUID:self.subGroupUUID]);
  XCTAssertNil([self.kdbxTreeB.root entryForUUID:self.entryUUID]);
  
  usleep(10);
  
  KPKGroup *groupA = [self.kdbxTreeA.root groupForUUID:self.groupUUID];
  groupA.title = @"TitleChangeAfterDeletion";
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  /* make sure deletion was carried over */
  KPKGroup *synchronizedGroup = [self.kdbxTreeA.root groupForUUID:self.groupUUID];
  XCTAssertNotNil(synchronizedGroup);
  XCTAssertNil(self.kdbxTreeA.mutableDeletedObjects[self.groupUUID]);
  XCTAssertEqualObjects(synchronizedGroup, groupA);
  XCTAssertEqualObjects(synchronizedGroup.title, @"TitleChangeAfterDeletion");
  
  /* other non-modified nodes should be delete */
  XCTAssertNil([self.kdbxTreeA.root groupForUUID:self.subGroupUUID]);
  XCTAssertNil([self.kdbxTreeA.root entryForUUID:self.entryUUID]);
}


- (void)testChangedLocalGroup {
  KPKGroup *groupB = self.kdbxTreeB.root.groups.firstObject;
  NSUUID *uuid = groupB.uuid;
  groupB.title = @"TheTitleHasChanged";
  
  usleep(10);
  
  KPKGroup *groupA = [self.kdbxTreeA.root groupForUUID:uuid];
  groupA.title = @"ThisChangeWasLaterSoItStays";
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  KPKGroup *changedGroup = [self.kdbxTreeA.root groupForUUID:uuid];
  XCTAssertNotNil(changedGroup);
  XCTAssertEqual(groupA, changedGroup, @"Group pointers stay the same!");
  XCTAssertEqual(KPKComparsionEqual, [changedGroup compareToGroup:groupA]);
  XCTAssertEqualObjects(changedGroup.title, @"ThisChangeWasLaterSoItStays");
}

- (void)testMovedEntryKDBX {
  //
  //  before:
  //  rootgroup
  //    - group
  //      - subgroup
  //        - entry
  //    - rootentry
  //
  //  after:
  //  rootgroup
  //    - group
  //      - rootentry
  //      - subgroup
  //        - entry
  //
  KPKEntry *entry = self.kdbxTreeB.root.entries.firstObject;
  
  NSUUID *entryUUID = entry.uuid;
  NSUUID *groupUUID = self.kdbxTreeB.root.groups.firstObject.uuid;
  
  [entry moveToGroup:self.kdbxTreeB.root.groups.firstObject];
  
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  KPKEntry *movedEntry = [self.kdbxTreeA.root entryForUUID:entryUUID];
  
  XCTAssertNotNil(movedEntry);
  XCTAssertEqualObjects(movedEntry.parent.uuid, groupUUID);
  
  /* ensure that we do not have any duplications */
  NSMutableSet *uuids = [[NSMutableSet alloc] init];
  for(KPKEntry *entry in self.kdbxTreeA.allEntries) {
    XCTAssertFalse([uuids containsObject:entry.uuid]);
    [uuids addObject:entry.uuid];
  }
  
  [uuids removeAllObjects];
  
  XCTAssertFalse([uuids containsObject:self.kdbxTreeA.root.uuid]);
  [uuids addObject:self.kdbxTreeA.root];
  for(KPKGroup *group in self.kdbxTreeA.allGroups) {
    XCTAssertFalse([uuids containsObject:group.uuid]);
    [uuids addObject:group.uuid];
  }
}

- (void)testMovedEntryKDB {
  //
  //  before:
  //  rootgroup
  //    - rootentry
  //    - group
  //      - entry
  //      - subgroup
  
  //
  //  after:
  //  rootgroup
  //    - group
  //      - rootentry (moved due to KDB constraints!)
  //      - subgroup
  //        - entry
  //
  KPKEntry *entryB = [self.kdbTreeB.root entryForUUID:self.entryUUID];
  
  NSUUID *entryUUID = entryB.uuid;
  KPKGroup *subGroupB = self.kdbTreeB.root.mutableGroups.firstObject.mutableGroups.firstObject;
  
  [entryB moveToGroup:subGroupB];
  
  [self.kdbTreeA synchronizeWithTree:self.kdbTreeB mode:KPKSynchronizationModeSynchronize options:KPKSynchronizationOptionMatchGroupsByTitleOnly];
  
  KPKEntry *entryA = [self.kdbTreeA.root entryForUUID:entryUUID];
  
  KPKGroup *subGroupA = self.kdbTreeA.root.mutableGroups.firstObject.mutableGroups.firstObject;
  
  XCTAssertNotNil(entryA);
  XCTAssertEqual(entryA.parent, subGroupA);
  
  NSMutableSet *uuids = [[NSMutableSet alloc] init];
  for(KPKEntry *entry in self.kdbTreeA.allEntries) {
    XCTAssertFalse([uuids containsObject:entry.uuid]);
    [uuids addObject:entry.uuid];
  }
}

- (void)testMovedGroupKDBX {
  KPKGroup *group = self.kdbxTreeB.root.groups.firstObject;
  KPKGroup *subGroup = group.groups.firstObject;
  NSUUID *subGroupUUID = subGroup.uuid;
  
  [subGroup moveToGroup:self.kdbxTreeB.root];
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  KPKGroup *movedGroup = [self.kdbxTreeA.root groupForUUID:subGroupUUID];
  
  XCTAssertNotNil(movedGroup);
  XCTAssertEqualObjects(movedGroup.parent.uuid, self.kdbxTreeA.root.uuid);
}

- (void)testMovedGroupKDB {
  KPKGroup *group = self.kdbTreeB.root.groups.firstObject;
  NSString *groupTitle = group.title;
  KPKGroup *subSubGroup = group.groups.firstObject.groups.firstObject;
  NSString *subSubGroupTitle = subSubGroup.title;
  
  [subSubGroup moveToGroup:group];
  
  [self.kdbTreeA synchronizeWithTree:self.kdbTreeB mode:KPKSynchronizationModeSynchronize options:KPKSynchronizationOptionMatchGroupsByTitleOnly];
  
  KPKGroup *movedGroup = _findGroupByTitle(subSubGroupTitle, self.kdbTreeA);
  KPKGroup *newParent = _findGroupByTitle(groupTitle, self.kdbTreeA);
  
  XCTAssertNotNil(movedGroup);
  XCTAssertEqual(movedGroup.parent, newParent);
}

- (void)testMovedDateMergeKDBX {
  KPKEntry *entryA = self.kdbxTreeA.root.entries.firstObject;
  KPKEntry *entryB = self.kdbxTreeB.root.entries.firstObject;
  
  NSDate *locationDataA = entryA.timeInfo.locationChanged;
  
  XCTAssertEqualObjects(entryA.uuid, entryB.uuid);
  
  NSUUID *entryUUID = entryB.uuid;
  
  /* Move entry two times to update moved date but keep old parent */
  [entryB moveToGroup:self.kdbxTreeB.root.groups.firstObject];
  usleep(10);
  [entryB moveToGroup:self.kdbxTreeB.root];
  
  
  NSDate *locationDataB = entryB.timeInfo.locationChanged;
  
  XCTAssertEqual(locationDataA, [locationDataB earlierDate:locationDataA]);
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  KPKEntry *movedEntryA = [self.kdbxTreeA.root entryForUUID:entryUUID];
  
  XCTAssertNotNil(movedEntryA);
  XCTAssertEqualObjects(movedEntryA.timeInfo.locationChanged, locationDataB);
}

- (void)testMovedDateMergeKDB {
  KPKEntry *entryA = self.kdbTreeA.root.mutableGroups.firstObject.mutableEntries.firstObject;
  KPKEntry *entryB = self.kdbTreeB.root.mutableGroups.firstObject.mutableEntries.firstObject;
  
  NSDate *locationDataA = entryA.timeInfo.locationChanged;
  
  XCTAssertEqualObjects(entryA.uuid, entryB.uuid);
  
  NSUUID *entryUUID = entryB.uuid;
  
  /* Move entry two times to update moved date but keep old parent */
  [entryB moveToGroup:self.kdbTreeB.root.mutableGroups.firstObject.mutableGroups.firstObject];
  usleep(10);
  [entryB moveToGroup:self.kdbTreeB.root.mutableGroups.firstObject];
  
  
  NSDate *locationDataB = entryB.timeInfo.locationChanged;
  
  XCTAssertEqual(locationDataA, [locationDataB earlierDate:locationDataA]);
  
  [self.kdbTreeA synchronizeWithTree:self.kdbTreeB mode:KPKSynchronizationModeSynchronize options:KPKSynchronizationOptionMatchGroupsByTitleOnly];
  
  KPKEntry *movedEntryA = [self.kdbTreeA.root entryForUUID:entryUUID];
  
  XCTAssertNotNil(movedEntryA);
  XCTAssertEqualObjects(movedEntryA.timeInfo.locationChanged, locationDataB);
}



- (void)testChangedMetaData {
  /* name */
  self.kdbxTreeA.metaData.databaseName = @"NameA";
  usleep(10);
  self.kdbxTreeB.metaData.databaseName = @"NameB";
  
  /* desc */
  self.kdbxTreeB.metaData.databaseDescription = @"DescriptionB";
  usleep(10);
  self.kdbxTreeA.metaData.databaseDescription = @"DescriptionA";
  
  /* trash */
  self.kdbxTreeB.metaData.useTrash = YES;
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  XCTAssertEqualObjects(self.kdbxTreeA.metaData.databaseName, @"NameB");
  XCTAssertEqualObjects(self.kdbxTreeA.metaData.databaseNameChanged, self.kdbxTreeB.metaData.databaseNameChanged);
  
  XCTAssertEqualObjects(self.kdbxTreeA.metaData.databaseDescription, @"DescriptionA");
  XCTAssertNotEqualObjects(self.kdbxTreeA.metaData.databaseDescriptionChanged, self.kdbxTreeB.metaData.databaseDescriptionChanged);
  
  XCTAssertEqual(self.kdbxTreeA.metaData.useTrash, YES);
  XCTAssertEqualObjects(self.kdbxTreeA.metaData.trashChanged, self.kdbxTreeB.metaData.trashChanged );
}

- (void)testAddedCustomData {
  [self.kdbxTreeB.metaData setValue:@"NewData" forCustomDataKey:@"NewKey"];
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  KPKMetaData *metaDataA = self.kdbxTreeA.metaData;
  XCTAssertEqual(3, metaDataA.mutableCustomData.count);
  XCTAssertEqualObjects(@"CustomDataValueA", [metaDataA valueForCustomDataKey:@"CustomDataKeyA"]);
  XCTAssertEqualObjects(@"CustomDataValueB", [metaDataA valueForCustomDataKey:@"CustomDataKeyB"]);
  XCTAssertEqualObjects(@"NewData", [metaDataA valueForCustomDataKey:@"NewKey"]);
}

- (void)testRemovedCustomData {
  [self.kdbxTreeB.metaData removeCustomDataForKey:@"CustomDataKeyA"];
  XCTAssertEqual(1, self.kdbxTreeB.metaData.mutableCustomData.count);
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  KPKMetaData *metaDataA = self.kdbxTreeA.metaData;
  XCTAssertEqual(2, metaDataA.mutableCustomData.count);
  XCTAssertEqualObjects(@"CustomDataValueA", [metaDataA valueForCustomDataKey:@"CustomDataKeyA"]);
  XCTAssertEqualObjects(@"CustomDataValueB", [metaDataA valueForCustomDataKey:@"CustomDataKeyB"]);
}

- (void)testChangedCustomData {
  KPKModifiedString *dataB = self.kdbxTreeB.metaData.mutableCustomData[@"CustomDataKeyB"];
  NSDate *oldDateB = dataB.modificationDate;
  [self.kdbxTreeB.metaData setValue:@"ChangedCustomDataValueB" forCustomDataKey:@"CustomDataKeyB"];
  XCTAssertEqual(NSOrderedAscending, [oldDateB compare:dataB.modificationDate]);
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  XCTAssertEqual(2, self.kdbxTreeA.metaData.mutableCustomData.count);
  XCTAssertEqualObjects(@"ChangedCustomDataValueB", [self.kdbxTreeA.metaData valueForCustomDataKey:@"CustomDataKeyB"]);
}

- (void)testRemovedPublicCustomData {
  /*
  self.kdbxTreeA.metaData.mutableCustomPublicData[@"UInt32"] = [KPKNumber numberWithUnsignedInteger32:32];
  self.kdbxTreeA.metaData.mutableCustomPublicData[@"UInt64"] = [KPKNumber numberWithUnsignedInteger64:64];
  self.kdbxTreeA.metaData.mutableCustomPublicData[@"Int32"] = [KPKNumber numberWithInteger32:-32];
  self.kdbxTreeA.metaData.mutableCustomPublicData[@"Int64"] = [KPKNumber numberWithInteger64:-64];
  self.kdbxTreeA.metaData.mutableCustomPublicData[@"Data"] = [NSData dataWithBytes:bytes length:4];
  self.kdbxTreeA.metaData.mutableCustomPublicData[@"String"] = @"String";
  */
  
  [self.kdbxTreeB.metaData removePublicCustomDataForKey:@"UInt32"];
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  XCTAssertNil([self.kdbxTreeA.metaData valueForPublicCustomDataKey:@"UInt32"]);
  XCTAssertEqual(5, self.kdbxTreeA.metaData.mutableCustomPublicData.count);
}

- (void)testAddedPublicCustomData {
  
}

- (void)testChangedPublicCustomData {
  
}

- (void)testAddedCustomIcon {
  KPKIcon *icon = [[KPKIcon alloc] initWithImage:[NSImage imageNamed:NSImageNameInfo]];
  [self.kdbxTreeB.metaData addCustomIcon:icon];
  XCTAssertEqual(1, self.kdbxTreeA.metaData.mutableCustomIcons.count);
  XCTAssertEqual(2, self.kdbxTreeB.metaData.mutableCustomIcons.count);
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  XCTAssertEqual(2, self.kdbxTreeA.metaData.mutableCustomIcons.count);
}

- (void)testRemovedCustomIcon {
  KPKIcon *icon = [[KPKIcon alloc] initWithImage:[NSImage imageNamed:NSImageNameInfo]];
  [self.kdbxTreeA.metaData addCustomIcon:icon];
  [self.kdbxTreeB.metaData addCustomIcon:icon];
  
  [self.kdbxTreeB.metaData removeCustomIcon:icon];
  
  XCTAssertEqual(2, self.kdbxTreeA.metaData.mutableCustomIcons.count);
  XCTAssertEqual(1, self.kdbxTreeB.metaData.mutableCustomIcons.count);
  
  KPKDeletedNode *deletedNodeA = self.kdbxTreeA.mutableDeletedObjects[icon.uuid];
  XCTAssertNil(deletedNodeA);
  
  KPKDeletedNode *deletedNodeB = self.kdbxTreeB.mutableDeletedObjects[icon.uuid];
  XCTAssertNotNil(deletedNodeB);
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  XCTAssertEqual(1, self.kdbxTreeA.metaData.mutableCustomIcons.count);
  deletedNodeA = self.kdbxTreeA.mutableDeletedObjects[icon.uuid];
  XCTAssertNotNil(deletedNodeA);  
}

- (void)testLocalDeletedExternalModifiedCustomIcon {
  KPKIcon *iconA = self.kdbxTreeA.metaData.mutableCustomIcons.firstObject;
  [self.kdbxTreeA.metaData removeCustomIcon:iconA];
  XCTAssertEqual(0, self.kdbxTreeA.metaData.mutableCustomIcons.count);
  XCTAssertEqual(1, self.kdbxTreeA.mutableDeletedObjects.count);
  
  KPKIcon *iconB = self.kdbxTreeB.metaData.mutableCustomIcons.firstObject;
  usleep(10);
  iconB.name = @"ChangedName";
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  KPKIcon *synchedIconA = [self.kdbxTreeA.metaData findIcon:iconA.uuid];
  XCTAssertNotNil(synchedIconA);
  XCTAssertEqual(1, self.kdbxTreeA.metaData.mutableCustomIcons.count);
  XCTAssertEqualObjects(iconB, synchedIconA);
}

- (void)testExternalDeletedLocalModifiedCustomIcon {
  KPKIcon *iconA = self.kdbxTreeA.metaData.mutableCustomIcons.firstObject;
  KPKIcon *iconB = [self.kdbxTreeB.metaData findIcon:iconA.uuid];
  
  [self.kdbxTreeB.metaData removeCustomIcon:iconB];
  XCTAssertEqual(0, self.kdbxTreeB.metaData.mutableCustomIcons.count);
  XCTAssertEqual(1, self.kdbxTreeB.mutableDeletedObjects.count);

  usleep(10);
  iconA.name = @"ChangedName";
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  KPKIcon *synchedIconA = [self.kdbxTreeA.metaData findIcon:iconA.uuid];
  XCTAssertNotNil(synchedIconA);
  XCTAssertEqual(1, self.kdbxTreeA.metaData.mutableCustomIcons.count);
  XCTAssertEqualObjects(iconA, synchedIconA);
}

- (void)testLocalModifiedExternalDeletedCustomIcon {
  KPKIcon *iconA = self.kdbxTreeA.metaData.mutableCustomIcons.firstObject;
  iconA.name = @"ChangedName";
  
  KPKIcon *iconB = [self.kdbxTreeB.metaData findIcon:iconA.uuid];
  [self.kdbxTreeB.metaData removeCustomIcon:iconB];
  XCTAssertEqual(0, self.kdbxTreeB.metaData.mutableCustomIcons.count);
  XCTAssertEqual(1, self.kdbxTreeB.mutableDeletedObjects.count);
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  KPKIcon *synchedIconA = [self.kdbxTreeA.metaData findIcon:iconA.uuid];
  XCTAssertNil(synchedIconA);
  XCTAssertEqual(0, self.kdbxTreeA.metaData.mutableCustomIcons.count);
  XCTAssertNotNil(self.kdbxTreeA.deletedObjects[iconA.uuid]);
}

- (void)testRemovedCustomNodeData {
  KPKGroup *groupB = [self.kdbxTreeB.root groupForUUID:self.groupUUID];
  KPKEntry *entryB = [self.kdbxTreeB.root entryForUUID:self.rootEntryUUID];
  
  usleep(10);
  
  XCTAssertEqual(groupB.mutableCustomData.count, 1);
  XCTAssertEqual(entryB.mutableCustomData.count, 1);
  [groupB removeCustomDataForKey:@"GroupKeyA"];
  [entryB removeCustomDataForKey:@"EntryKeyA"];
  XCTAssertEqual(groupB.mutableCustomData.count, 0);
  XCTAssertEqual(entryB.mutableCustomData.count, 0);
  
  KPKGroup *groupA = [self.kdbxTreeA.root groupForUUID:self.groupUUID];
  XCTAssertNotEqual(groupA, groupB);
  KPKEntry *entryA = [self.kdbxTreeA.root entryForUUID:self.rootEntryUUID];
  XCTAssertNotEqual(entryA, entryB);
  XCTAssertEqual(groupA.mutableCustomData.count, 1);
  XCTAssertEqual(entryA.mutableCustomData.count, 1);
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  XCTAssertEqual(groupB.mutableCustomData.count, 0);
  XCTAssertEqual(entryB.mutableCustomData.count, 0);
}

- (void)testAddedCustomNodeData {
  KPKGroup *groupB = [self.kdbxTreeB.root groupForUUID:self.groupUUID];
  KPKEntry *entryB = [self.kdbxTreeB.root entryForUUID:self.rootEntryUUID];
  
  usleep(10);
  
  XCTAssertEqual(groupB.mutableCustomData.count, 1);
  XCTAssertEqual(entryB.mutableCustomData.count, 1);
  [groupB setCustomData:@"MoreData" forKey:@"GroupMoreDataKey"];
  [entryB setCustomData:@"MoreData" forKey:@"EntryMoreDataKey"];
  XCTAssertEqual(groupB.mutableCustomData.count, 2);
  XCTAssertEqual(entryB.mutableCustomData.count, 2);
  
  KPKGroup *groupA = [self.kdbxTreeA.root groupForUUID:self.groupUUID];
  XCTAssertNotEqual(groupA, groupB);
  KPKEntry *entryA = [self.kdbxTreeA.root entryForUUID:self.rootEntryUUID];
  XCTAssertNotEqual(entryA, entryB);
  XCTAssertEqual(groupA.mutableCustomData.count, 1);
  XCTAssertEqual(entryA.mutableCustomData.count, 1);
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  XCTAssertEqual(groupB.mutableCustomData.count, 2);
  XCTAssertEqual(entryB.mutableCustomData.count, 2);
  XCTAssertEqualObjects(entryB.mutableCustomData[@"EntryMoreDataKey"], @"MoreData");
  XCTAssertEqualObjects(groupB.mutableCustomData[@"GroupMoreDataKey"], @"MoreData");
  XCTAssertEqualObjects(entryB.mutableCustomData[@"EntryKeyA"], @"CustomEntryDataA");
  XCTAssertEqualObjects(groupB.mutableCustomData[@"GroupKeyA"], @"CustomGroupDataA");
}

- (void)testChangedCustomNodeData {
  KPKEntry *entryB = [self.kdbxTreeB.root entryForUUID:self.rootEntryUUID];
  KPKGroup *groupB = [self.kdbxTreeB.root groupForUUID:self.groupUUID];
  
  usleep(10);
  
  XCTAssertEqual(entryB.mutableCustomData.count, 1);
  XCTAssertEqual(groupB.mutableCustomData.count, 1);
  
  [entryB setCustomData:@"ChangedEntryData" forKey:@"EntryKeyA"];
  [groupB setCustomData:@"ChangedGroupData" forKey:@"GroupKeyA"];
  XCTAssertEqual(entryB.mutableCustomData.count, 1);
  XCTAssertEqual(groupB.mutableCustomData.count, 1);
  
  KPKGroup *groupA = [self.kdbxTreeA.root groupForUUID:self.groupUUID];
  XCTAssertNotEqual(groupA, groupB);
  KPKEntry *entryA = [self.kdbxTreeA.root entryForUUID:self.rootEntryUUID];
  XCTAssertNotEqual(entryA, entryB);
  XCTAssertEqual(groupA.mutableCustomData.count, 1);
  XCTAssertEqual(entryA.mutableCustomData.count, 1);
  XCTAssertEqualObjects(entryA.mutableCustomData[@"EntryKeyA"], @"CustomEntryDataA");
  XCTAssertEqualObjects(groupA.mutableCustomData[@"GroupKeyA"], @"CustomGroupDataA");
  
  
  [self.kdbxTreeA synchronizeWithTree:self.kdbxTreeB mode:KPKSynchronizationModeSynchronize options:0];
  
  XCTAssertEqual(groupB.mutableCustomData.count, 1);
  XCTAssertEqual(entryB.mutableCustomData.count, 1);
  XCTAssertEqualObjects(entryB.mutableCustomData[@"EntryKeyA"], @"ChangedEntryData");
  XCTAssertEqualObjects(groupB.mutableCustomData[@"GroupKeyA"], @"ChangedGroupData");
}

@end
