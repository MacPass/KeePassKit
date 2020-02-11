//
//  KPKTestXmlWriting.m
//  MacPass
//
//  Created by Michael Starke on 20.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"


@interface KPKTestXMLSerialization : XCTestCase

@end


@implementation KPKTestXMLSerialization

- (void)testXmlWriting {
  NSData *data = [self _loadBundleData:@"CustomIcon_Password_1234" extension:@"kdbx"];
  NSError *error;
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithKeys:@[[KPKKey keyWithPassword:@"1234"]]];
  KPKTree *tree = [[KPKTree alloc] initWithData:data key:key error:&error];
  
  KPKFileVersion kdbx3 = { KPKDatabaseFormatKdbx, kKPKKdbxFileVersion3 };
  XCTAssertLessThanOrEqual(NSOrderedSame, KPKFileVersionCompare(tree.minimumVersion, kdbx3));
  
  error = nil;
  NSData *saveData = [tree encryptWithKey:key format:KPKDatabaseFormatKdbx error:&error];
  XCTAssertNotNil(saveData, @"Serialization should yield data");
  NSString *tempFile = [NSTemporaryDirectory() stringByAppendingString:@"CustomIcon_Password_1234_save.kdbx"];
  NSLog(@"Saved file to %@", tempFile);
  [saveData writeToFile:tempFile atomically:YES];
  
  error = nil;
  NSURL *url = [NSURL fileURLWithPath:tempFile];
  KPKTree *reloadedTree = [[KPKTree alloc] initWithContentsOfUrl:url key:key error:&error];
  XCTAssertNotNil(reloadedTree, @"Reloaded tree should not be nil");
}

- (void)testCustomAutotypeKeystrokeSequenceLoading {
  NSError *error;
  KPKTree *tree = [[KPKTree alloc] initWithXmlContentsOfURL:[self _bundleURLForData:@"AutotypeCustomKeystrokeSequence_1234" extension:@"xml"] error:&error];
  XCTAssertNotNil(tree, @"Tree from XML should not be nil!");
}

- (void)testAutotypeCustomKeystrokeSequenceSerialization{
  KPKTree *tree = [[KPKTree alloc] init];
  tree.root = [[KPKGroup alloc] init];
  KPKEntry *entry = [[KPKEntry alloc] init];
  NSUUID *uuid = entry.uuid;
  
  NSString *sequence = @"{Title}{Title}{Title}";
  XCTAssertTrue(entry.autotype.hasDefaultKeystrokeSequence, @"Initalized Autotype has default (==nil) sequence");
  entry.autotype.defaultKeystrokeSequence = sequence;
  [entry addToGroup:tree.root];
  
  XCTAssertEqualObjects(entry.autotype.defaultKeystrokeSequence, sequence);
  
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithKeys:@[[KPKKey keyWithPassword:@"1234"]]];
  NSError *error;
  NSData *data = [tree encryptWithKey:key format:KPKDatabaseFormatKdbx error:&error];
  XCTAssertNotNil(data, @"Tree encryption yields data!");
  
  KPKTree *decryptedTree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNotNil(decryptedTree, @"Initalized tree from data is present!");
  KPKEntry *decryptedEntry = [tree.root entryForUUID:uuid];
  XCTAssertNotNil(entry, @"Encrypted entry is decryted!");
  XCTAssertEqualObjects(entry, decryptedEntry, @"Decrypted entry is the same as the encrypted one");
}

- (void)testWindowAssociationSerialization {
  KPKTree *tree = [[KPKTree alloc] init];
  tree.root = [[KPKGroup alloc] init];
  KPKEntry *entry = [[KPKEntry alloc] init];
  NSUUID *uuid = entry.uuid;
  [entry.autotype addAssociation:[[KPKWindowAssociation alloc] initWithWindowTitle:@"A" keystrokeSequence:@"A{ENTER}{SPACE}{ENTER}A"]];
  XCTAssertEqual(entry.autotype.associations.count, 1, @"Entry has 1 window association");
  [entry.autotype addAssociation:[[KPKWindowAssociation alloc] initWithWindowTitle:@"B" keystrokeSequence:@"B{ENTER}{SPACE}{ENTER}B"]];
  XCTAssertEqual(entry.autotype.associations.count, 2, @"Entry has 2 window association");
  [entry.autotype addAssociation:[[KPKWindowAssociation alloc] initWithWindowTitle:@"C" keystrokeSequence:@"C{ENTER}{SPACE}{ENTER}C"]];
  XCTAssertEqual(entry.autotype.associations.count, 3, @"Entry has 3 window association");
  
  [entry addToGroup:tree.root];
  
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithKeys:@[[KPKKey keyWithPassword:@"1234"]]];
  NSError *error;
  NSData *data = [tree encryptWithKey:key format:KPKDatabaseFormatKdbx error:&error];
  XCTAssertNotNil(data, @"Tree encryption yields data!");
  
  KPKTree *decryptedTree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNotNil(decryptedTree, @"Initalized tree from data is present!");
  KPKEntry *decryptedEntry = [tree.root entryForUUID:uuid];
  XCTAssertNotNil(entry, @"Encrypted entry is decryted!");
  XCTAssertEqualObjects(entry, decryptedEntry, @"Decrypted entry is the same as the encrypted one");
}

- (void)testGroupSearchSettingsSerialization {
  KPKTree *tree = [[KPKTree alloc] init];
  tree.root = [[KPKGroup alloc] init];

  KPKGroup *inheritGroup = [[KPKGroup alloc] init];
  KPKGroup *disabledGroup = [[KPKGroup alloc] init];
  KPKGroup *enabledGroup = [[KPKGroup alloc] init];
  
  inheritGroup.isSearchEnabled = KPKInherit;
  enabledGroup.isSearchEnabled = KPKInheritYES;
  disabledGroup.isSearchEnabled = KPKInheritNO;
  
  XCTAssertEqual(inheritGroup.isSearchEnabled, KPKInherit);
  XCTAssertEqual(enabledGroup.isSearchEnabled, KPKInheritYES);
  XCTAssertEqual(disabledGroup.isSearchEnabled, KPKInheritNO);

  [inheritGroup addToGroup:tree.root];
  [enabledGroup addToGroup:tree.root];
  [disabledGroup addToGroup:tree.root];
  
  NSUUID *inheritUUID = inheritGroup.uuid;
  NSUUID *enabledUUID = enabledGroup.uuid;
  NSUUID *disabledUUID = disabledGroup.uuid;

  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithKeys:@[[KPKKey keyWithPassword:@"1234"]]];
  NSError *error;
  NSData *data = [tree encryptWithKey:key format:KPKDatabaseFormatKdbx error:&error];
  XCTAssertNotNil(data, @"Tree encryption yields data!");
  
  KPKTree *decryptedTree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNotNil(decryptedTree, @"Initalized tree from data is present!");
  KPKGroup *loadedInheritGroup = [tree.root groupForUUID:inheritUUID];
  XCTAssertNotNil(loadedInheritGroup, @"Encrypted entry is decryted!");
  XCTAssertEqual(loadedInheritGroup.isSearchEnabled, inheritGroup.isSearchEnabled);

  KPKGroup *loadedEnabledGroup = [tree.root groupForUUID:enabledUUID];
  XCTAssertNotNil(loadedEnabledGroup, @"Encrypted entry is decryted!");
  XCTAssertEqual(loadedEnabledGroup.isSearchEnabled, enabledGroup.isSearchEnabled);
  
  KPKGroup *loadedDisabledGroup = [tree.root groupForUUID:disabledUUID];
  XCTAssertNotNil(loadedDisabledGroup, @"Encrypted entry is decryted!");
  XCTAssertEqual(loadedDisabledGroup.isSearchEnabled, disabledGroup.isSearchEnabled);
}

- (void)testGroupAutotypeSettingsSerialization {
  KPKTree *tree = [[KPKTree alloc] init];
  tree.root = [[KPKGroup alloc] init];
  
  KPKGroup *inheritGroup = [[KPKGroup alloc] init];
  KPKGroup *enabledGroup = [[KPKGroup alloc] init];
  KPKGroup *disabledGroup = [[KPKGroup alloc] init];
  
  inheritGroup.isAutoTypeEnabled = KPKInherit;
  enabledGroup.isAutoTypeEnabled = KPKInheritYES;
  disabledGroup.isAutoTypeEnabled = KPKInheritNO;

  XCTAssertEqual(inheritGroup.isAutoTypeEnabled, KPKInherit);
  XCTAssertEqual(enabledGroup.isAutoTypeEnabled, KPKInheritYES);
  XCTAssertEqual(disabledGroup.isAutoTypeEnabled, KPKInheritNO);

  
  [inheritGroup addToGroup:tree.root];
  [enabledGroup addToGroup:tree.root];
  [disabledGroup addToGroup:tree.root];
  
  NSUUID *inheritUUID = inheritGroup.uuid;
  NSUUID *disabledUUID = disabledGroup.uuid;
  NSUUID *enabledUUID = enabledGroup.uuid;
  
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithKeys:@[[KPKKey keyWithPassword:@"1234"]]];
  NSError *error;
  NSData *data = [tree encryptWithKey:key format:KPKDatabaseFormatKdbx error:&error];
  XCTAssertNotNil(data, @"Tree encryption yields data!");
  
  KPKTree *decryptedTree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNotNil(decryptedTree, @"Initalized tree from data is present!");
  KPKGroup *loadedInheritGroup = [tree.root groupForUUID:inheritUUID];
  XCTAssertNotNil(loadedInheritGroup, @"Encrypted entry is decryted!");
  XCTAssertEqual(loadedInheritGroup.isAutoTypeEnabled, inheritGroup.isAutoTypeEnabled);
  
  KPKGroup *loadedEnabledGroup = [tree.root groupForUUID:enabledUUID];
  XCTAssertNotNil(loadedEnabledGroup, @"Encrypted entry is decryted!");
  XCTAssertEqual(loadedEnabledGroup.isAutoTypeEnabled, enabledGroup.isAutoTypeEnabled);
  
  KPKGroup *loadedDisabledGroup = [tree.root groupForUUID:disabledUUID];
  XCTAssertNotNil(loadedDisabledGroup, @"Encrypted entry is decryted!");
  XCTAssertEqual(loadedDisabledGroup.isAutoTypeEnabled, disabledGroup.isAutoTypeEnabled);
}

- (NSData *)_loadBundleData:(NSString *)name extension:(NSString *)extension {
  return [NSData dataWithContentsOfURL:[self _bundleURLForData:name extension:extension]];
}

- (NSURL *)_bundleURLForData:(NSString *)name extension:(NSString *)extension {
  NSBundle *myBundle = [NSBundle bundleForClass:self.class];
  return [myBundle URLForResource:name withExtension:extension];
}

@end
