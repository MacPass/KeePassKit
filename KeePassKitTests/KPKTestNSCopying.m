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

@end
