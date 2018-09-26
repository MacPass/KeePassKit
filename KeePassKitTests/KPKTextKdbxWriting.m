//
//  KPKTextKdbxWriting.m
//  KeePassKit
//
//  Created by Michael Starke on 12.06.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"
#import "KeePassKit_Private.h"

@interface KPKTestKdbxWriting : XCTestCase
@property (strong) KPKTree *tree;
@property (strong) KPKEntry *entry;
@property (strong) KPKEntry *anotherEntry;
@property (strong) NSData *data;
@end

@implementation KPKTestKdbxWriting

- (void)setUp {
  [super setUp];
  
  //uint8_t bytes[] = {0x00,0x01,0x02,0x03,0x04,0x05};
  self.data = [NSData kpk_dataWithRandomBytes:1024*1024*10]; //[NSData dataWithBytes:bytes length:sizeof(bytes)/sizeof(uint8_t)];
  
  self.tree = [[KPKTree alloc] init];
  self.tree.root = [[KPKGroup alloc] init];
  
  [[[KPKGroup alloc] init] addToGroup:self.tree.root];
  
  self.entry = [[KPKEntry alloc] init];
  self.entry.title = @"TestEntry";
  
  [self.entry addBinary:[[KPKBinary alloc] initWithName:@"Binary0" data:self.data]];
  [self.entry addBinary:[[KPKBinary alloc] initWithName:@"Binary1" data:self.data]];
  [self.entry addBinary:[[KPKBinary alloc] initWithName:@"Binary2" data:self.data]];
  
  [self.entry addToGroup:self.tree.root.groups.firstObject];
  
  /* kill all time info that cannot be serialized to ensure equality checks work out! */
  [self.entry.timeInfo _reducePrecicionToSeconds];
  
  self.anotherEntry = [[KPKEntry alloc] init];
  self.anotherEntry.title = @"TestEntryB";
  
  [self.anotherEntry addBinary:[[KPKBinary alloc] initWithName:@"Binary0" data:self.data]];
  [self.anotherEntry addBinary:[[KPKBinary alloc] initWithName:@"Binary1" data:self.data]];
  
  [self.anotherEntry addToGroup:self.tree.root.groups.firstObject];
  
  /* kill all time info that cannot be serialized to ensure equality checks work out! */
  [self.anotherEntry.timeInfo _reducePrecicionToSeconds];

}

- (void)testKdbx4BinarySerialization {
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"Test" keyFileData:nil];
  self.tree.metaData.keyDerivationParameters = [[KPKArgon2KeyDerivation alloc] init].parameters;
  NSError *error;
  NSData *data = [self.tree encryptWithKey:key format:KPKDatabaseFormatKdbx error:&error];
  
  XCTAssertNotNil(data);
  XCTAssertNil(error);
  
  KPKTree *loadedTree = [[KPKTree alloc] initWithData:data key:key error:&error];
  
  XCTAssertNotNil(loadedTree);
  XCTAssertEqualObjects(loadedTree.metaData.keyDerivationParameters[KPKKeyDerivationOptionUUID], [KPKArgon2KeyDerivation uuid].kpk_uuidData);
  
  KPKEntry *entry = loadedTree.root.groups.firstObject.entries.firstObject;
  
  XCTAssertEqual(KPKComparsionEqual, [self.entry compareToEntry:entry]);
  XCTAssertEqual(entry.binaries.count, 3);
  /* explicitly test binaries for equality */
  XCTAssertEqualObjects(entry.binaries[0].data, self.data);
  XCTAssertEqualObjects(entry.binaries[1].data, self.data);
  XCTAssertEqualObjects(entry.binaries[2].data, self.data);
  
  KPKEntry *anotherEntry = loadedTree.root.groups.firstObject.entries.lastObject;
  
  XCTAssertEqual(KPKComparsionEqual, [self.anotherEntry compareToEntry:anotherEntry]);
  XCTAssertEqual(anotherEntry.binaries.count, 2);
  /* explicitly test binaries for equality */
  XCTAssertEqualObjects(anotherEntry.binaries[0].data, self.data);
  XCTAssertEqualObjects(anotherEntry.binaries[1].data, self.data);
  
}

- (void)testKdbx3BinarySerialization {
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"Test" keyFileData:nil];
  NSError *error;
  NSData *data = [self.tree encryptWithKey:key format:KPKDatabaseFormatKdbx error:&error];
  
  XCTAssertNotNil(data);
  XCTAssertNil(error);
  
  KPKTree *loadedTree = [[KPKTree alloc] initWithData:data key:key error:&error];
  
  XCTAssertNotNil(loadedTree);
  XCTAssertEqualObjects(loadedTree.metaData.keyDerivationParameters[KPKKeyDerivationOptionUUID], [KPKAESKeyDerivation uuid].kpk_uuidData);
  
  KPKEntry *entry = loadedTree.root.groups.firstObject.entries.firstObject;
  
  XCTAssertEqual(KPKComparsionEqual, [self.entry compareToEntry:entry]);
  XCTAssertEqual(entry.binaries.count, 3);
  /* explicitly test binaries for equality */
  XCTAssertEqualObjects(entry.binaries[0].data, self.data);
  XCTAssertEqualObjects(entry.binaries[1].data, self.data);
  XCTAssertEqualObjects(entry.binaries[2].data, self.data);
  
  KPKEntry *anotherEntry = loadedTree.root.groups.firstObject.entries.lastObject;
  
  XCTAssertEqual(KPKComparsionEqual, [self.anotherEntry compareToEntry:anotherEntry]);
  XCTAssertEqual(anotherEntry.binaries.count, 2);
  /* explicitly test binaries for equality */
  XCTAssertEqualObjects(anotherEntry.binaries[0].data, self.data);
  XCTAssertEqualObjects(anotherEntry.binaries[1].data, self.data);
}

- (void)testXMLBinarySerialization {
  NSError *error;
  NSData *data = self.tree.xmlData;
  
  XCTAssertNotNil(data);
  XCTAssertNil(error);
  
  KPKTree *loadedTree = [[KPKTree alloc] initWithXmlData:data error:&error];
  
  XCTAssertNotNil(loadedTree);
  
  KPKEntry *entry = loadedTree.root.groups.firstObject.entries.firstObject;
  
  XCTAssertEqual(KPKComparsionEqual, [self.entry compareToEntry:entry]);
  XCTAssertEqual(entry.binaries.count, 3);
  /* explicitly test binaries for equality */
  XCTAssertEqualObjects(entry.binaries[0].data, self.data);
  XCTAssertEqualObjects(entry.binaries[1].data, self.data);
  XCTAssertEqualObjects(entry.binaries[2].data, self.data);
  
  KPKEntry *anotherEntry = loadedTree.root.groups.firstObject.entries.lastObject;
  
  XCTAssertEqual(KPKComparsionEqual, [self.anotherEntry compareToEntry:anotherEntry]);
  XCTAssertEqual(anotherEntry.binaries.count, 2);
  /* explicitly test binaries for equality */
  XCTAssertEqualObjects(anotherEntry.binaries[0].data, self.data);
  XCTAssertEqualObjects(anotherEntry.binaries[1].data, self.data);
}





@end
