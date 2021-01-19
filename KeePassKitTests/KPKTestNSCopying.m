//
//  KPKTestNSCopying.m
//  MacPass
//
//  Created by Michael Starke on 31.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit.h"
#import "KeePassKit_Private.h"

@interface KPKTestNSCopying : XCTestCase

@end

@implementation KPKTestNSCopying

- (void)testAttributeCopying {
  KPKAttribute *attribute = [[KPKAttribute alloc] initWithKey:@"Key" value:kKPKXmlValue isProtected:NO];
  KPKAttribute *copy = [attribute copy];
  
  attribute.key = @"NewKey";
  attribute.value = @"NewValue";
  attribute.protect = YES;
  
  XCTAssertNotNil(copy, @"Copy shoule exist");
  XCTAssertTrue([copy.key isEqualToString:@"Key"], @"Copy key should be key");
  XCTAssertTrue([copy.value isEqualToString:kKPKXmlValue], @"Copy value should be value");
  XCTAssertFalse(copy.protect, @"Copy should not be protected");
}

- (void)testEntryCopying {
  KPKTree *tree = [[KPKTree alloc] init];
  tree.root = [[KPKGroup alloc] init];
  KPKEntry *entry = [[KPKEntry alloc] init];
  [entry addToGroup:tree.root];
  
  usleep(10);
  
  entry.iconUUID = [[NSUUID alloc] initWithUUIDString:@"66873E56-2822-4258-A45F-92CFE194232F"];
  entry.iconId = 500;
  entry.title = @"Title";
  entry.url = @"URL";
  entry.username = @"Username";
  entry.password = @"Password";
  entry.tags = @[@"TagA", @"TagB", @"TagC"];
  entry.foregroundColor = NSUIColor.redColor;
  entry.backgroundColor = NSUIColor.greenColor;
  
  uint8_t bytes[] = { 0xFF, 0x00, 0xFF, 0x00, 0xFF };
  NSData *data = [[NSData alloc] initWithBytes:bytes length:5];
  
  KPKBinary *binary = [[KPKBinary alloc] init];
  binary.data = data;
  binary.name = @"Binary";
  
  [entry addBinary:binary];
  [entry addCustomAttribute:[[KPKAttribute alloc] initWithKey:@"Custom" value:kKPKXmlValue isProtected:NO]];

  [entry pushHistory];
  XCTAssertEqual(entry.mutableHistory.count, 1);
  
  usleep(10);
  
  KPKEntry *copyEntry = [entry copy];
  XCTAssertEqual(KPKComparsionEqual, [entry compareToEntry:copyEntry]);
   
  entry.title = @"NewTitle";
  [entry removeBinary:binary];
  ((KPKAttribute *)entry.customAttributes.lastObject).key = @"NewCustomKey";
  
  XCTAssertEqual(KPKComparsionDifferent, [entry compareToEntry:copyEntry]);
  
  XCTAssertNotNil(copyEntry, @"Copied Entry cannot be nil");
  XCTAssertEqualObjects(copyEntry.title, @"Title", @"Titles should match");
  XCTAssertEqualObjects(copyEntry.url, @"URL", @"URLS should match");
  XCTAssertEqual(copyEntry.binaries.count, 1, @"Binareis should be copied");
  
  KPKBinary *copiedBinary = copyEntry.binaries.lastObject;
  XCTAssertTrue([copiedBinary.data isEqualToData:binary.data], @"Binary data should match");
  XCTAssertTrue([copiedBinary.name isEqualToString:binary.name], @"Binary names should macht");
}

- (void)testGroupCopying {
  
  /*
   root
    + Group A
      + Entry A
      + Group A1
      + Group A2
        + Entry B
   */
  
  KPKGroup *root = [[KPKGroup alloc] init];
  root.title = @"root";
  
  KPKGroup *groupA = [[KPKGroup alloc] init];
  groupA.title = @"Group A";
  groupA.isAutoTypeEnabled = KPKInheritNO;
  
  KPKGroup *groupA1 = [[KPKGroup alloc] init];
  groupA1.title = @"Group A1";
  groupA1.notes = @"Some notes";
  groupA1.iconId = KPKIconASCII;
  
  KPKGroup *groupA2 = [[KPKGroup alloc] init];
  groupA2.title = @"Group A2";
  groupA2.notes = @"More notes";
  groupA2.isSearchEnabled = KPKInheritYES;
  
  KPKEntry *entryA = [[KPKEntry alloc] init];
  entryA.title = @"Entry A";
  entryA.url = @"www.url.com";
  KPKEntry *entryB = [[KPKEntry alloc] init];
  entryB.title = @"Entry B";
  entryB.url = @"www.nope.com";

  
  [entryA addToGroup:groupA];
  [groupA1 addToGroup:groupA];
  [groupA2 addToGroup:groupA];
  [entryB addToGroup:groupA2];
  
  [groupA addToGroup:root];
  
  KPKGroup *copy = [root copy];
  
  XCTAssertEqual(KPKComparsionEqual, [root compareToGroup:copy]);
}

- (void)testTimeInfoCopying {
  KPKTimeInfo *timeInfo = [[KPKTimeInfo alloc] init];
  timeInfo.expirationDate = NSDate.date;

  usleep(10);
  
  KPKTimeInfo *copy = [timeInfo copy];
  XCTAssertEqualObjects(copy, timeInfo);
  
}

- (void)testTreeCopying {
  KPKTree *tree = [[KPKTree alloc] init];
  
  tree.metaData.masterKeyChangeEnforcementInterval = 10;
  tree.metaData.masterKeyChangeRecommendationInterval = 20;
  tree.metaData.databaseDescription = @"test database";
  tree.metaData.defaultUserName = @"default-user-name";
  
  KPKGroup *root = [[KPKGroup alloc] init];
  
  tree.root = root;
  
  KPKGroup *groupA = [[KPKGroup alloc] init];
  groupA.title = @"groupA";
  KPKGroup *groupB = [[KPKGroup alloc] init];
  groupB.title = @"groupB";
  KPKGroup *trash = [[KPKGroup alloc] init];
  trash.title = @"trash";
  KPKGroup *templates = [[KPKGroup alloc] init];
  templates.title = @"templates";
  
  [groupA addToGroup:root];
  [groupB addToGroup:root];
  [trash addToGroup:root];
  [templates addToGroup:root];
  
  tree.trash = trash;
  tree.templates = templates;
  
  XCTAssertEqual(tree.trash, trash);
  XCTAssertEqual(tree.templates, templates);
  
  KPKEntry *entryA1 = [[KPKEntry alloc] init];
  entryA1.title = @"entryA1";
  entryA1.url = @"www.entryA1.com";
  KPKEntry *entryA2 = [[KPKEntry alloc] init];
  entryA2.title = @"entryA2";
  entryA2.notes = @"entryA2notes";
  KPKEntry *entryA3 = [[KPKEntry alloc] init];
  entryA3.title = @"entryA3";
  entryA3.autotype.enabled = NO;
  

  [entryA1 addToGroup:groupA];
  [entryA2 addToGroup:groupA];
  [entryA3 addToGroup:groupA];
  
  KPKEntry *entryB1 = [[KPKEntry alloc] init];
  KPKEntry *entryB2 = [[KPKEntry alloc] init];
  KPKEntry *entryB3 = [[KPKEntry alloc] init];

  [entryB1 addToGroup:groupB];
  [entryB2 addToGroup:groupB];
  [entryB3 addToGroup:groupB];
  
  /*
   root
    groupA
      entryA1
      entryA2
      entryA4
    groupB
      entryB1
      entryB2
      entryB3
    trash
    templates
   */

  [entryA3 trashOrRemove];
  [entryB3 trashOrRemove];
  
  XCTAssertEqual(trash.entries.count, 2 );
  XCTAssertTrue(entryA3.isTrashed);
  XCTAssertTrue(entryB3.isTrashed);
  
  [trash clear];
  
  XCTAssertEqual(tree.mutableDeletedObjects.count,2);
  XCTAssertNotNil(tree.mutableDeletedNodes[entryA3.uuid]);
  XCTAssertNotNil(tree.mutableDeletedObjects[entryB3.uuid]);
  
  XCTAssertEqual(tree.mutableDeletedNodes.count,2);
  XCTAssertEqual(tree.mutableDeletedNodes[entryA3.uuid], entryA3);
  XCTAssertEqual(tree.mutableDeletedNodes[entryB3.uuid], entryB3);
  
  
  KPKTree *copy = [tree copy];
  
  XCTAssertEqualObjects(copy.root.uuid, tree.root.uuid);
  
  KPKEntry *entryA1copy = [copy.root entryForUUID:entryA1.uuid];
  XCTAssertNotNil(entryA1copy);
  KPKEntry *entryA2copy = [copy.root entryForUUID:entryA2.uuid];
  XCTAssertNotNil(entryA2copy);
  KPKEntry *entryA3copy = [copy.root entryForUUID:entryA3.uuid];
  XCTAssertNil(entryA3copy);
  
  XCTAssertEqual(copy.mutableDeletedObjects.count,2);
  XCTAssertNotNil(copy.mutableDeletedNodes[entryA3.uuid]);
  XCTAssertNotNil(copy.mutableDeletedObjects[entryB3.uuid]);
  
  XCTAssertEqual(copy.mutableDeletedNodes.count,2);
  XCTAssertNotEqual(copy.mutableDeletedNodes[entryA3.uuid], entryA3);
  XCTAssertNotEqual(copy.mutableDeletedNodes[entryB3.uuid], entryB3);

  // XCTAssertEqualObjects(tree.xmlData, copy.xmlData); XML has no stable order in some elements. We cannot compare on that level!
  XCTAssertEqual(tree.xmlData.length, copy.xmlData.length);
}

- (void)testTreeCopyPerformance {
  NSBundle *myBundle = [NSBundle bundleForClass:self.class];
  NSURL *url = [myBundle URLForResource:@"LargeSize_test" withExtension:@"kdbx"];
  NSData *data = [NSData dataWithContentsOfURL:url];
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithKeys:@[[KPKKey keyWithPassword:@"test"]]];
  
  KPKTree *tree = [[KPKTree alloc] initWithData:data key:key error:nil];
  XCTAssertNotNil(tree);
  
  [self measureBlock:^{
    XCTAssertNotNil([tree copy]);
  }];
}

- (void)testMetaDataCopying {
  NSBundle *myBundle = [NSBundle bundleForClass:self.class];
  NSURL *url = [myBundle URLForResource:@"LargeSize_test" withExtension:@"kdbx"];
  NSData *data = [NSData dataWithContentsOfURL:url];
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithKeys:@[[KPKKey keyWithPassword:@"test"]]];
  
  KPKTree *tree = [[KPKTree alloc] initWithData:data key:key error:nil];
  
  KPKMetaData *copy = [tree.metaData copy];
  
  XCTAssertTrue([copy isEqualToMetaData:tree.metaData]);
  
}

@end
