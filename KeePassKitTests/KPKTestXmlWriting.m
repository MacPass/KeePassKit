//
//  KPKTestXmlWriting.m
//  MacPass
//
//  Created by Michael Starke on 20.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"


@interface KPKTestXmlWriting : XCTestCase

@end


@implementation KPKTestXmlWriting

- (void)testXmlWriting {
  NSData *data = [self _loadBundleData:@"CustomIcon_Password_1234" extension:@"kdbx"];
  NSError *error;
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"1234" key:nil];
  KPKTree *tree = [[KPKTree alloc] initWithData:data key:key error:&error];
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
  
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"1234" key:nil];
  NSError *error;
  NSData *data = [tree encryptWithKey:key format:KPKDatabaseFormatKdbx error:&error];
  XCTAssertNotNil(data, @"Tree encryption yields data!");
  
  KPKTree *decryptedTree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNotNil(decryptedTree, @"Initalized tree from data is present!");
  KPKEntry *decryptedEntry = [tree.root entryForUUID:uuid];
  XCTAssertNotNil(entry, @"Encrypted entry is decryted!");
  XCTAssertEqualObjects(entry, decryptedEntry, @"Decrypted entry is the same as the encrypted one");
}

- (void)testWindowAssociationWriting {
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
  
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"1234" key:nil];
  NSError *error;
  NSData *data = [tree encryptWithKey:key format:KPKDatabaseFormatKdbx error:&error];
  XCTAssertNotNil(data, @"Tree encryption yields data!");
  
  KPKTree *decryptedTree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNotNil(decryptedTree, @"Initalized tree from data is present!");
  KPKEntry *decryptedEntry = [tree.root entryForUUID:uuid];
  XCTAssertNotNil(entry, @"Encrypted entry is decryted!");
  XCTAssertEqualObjects(entry, decryptedEntry, @"Decrypted entry is the same as the encrypted one");
}

- (NSData *)_loadBundleData:(NSString *)name extension:(NSString *)extension {
  return [NSData dataWithContentsOfURL:[self _bundleURLForData:name extension:extension]];
}

- (NSURL *)_bundleURLForData:(NSString *)name extension:(NSString *)extension {
  NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
  return [myBundle URLForResource:name withExtension:extension];
}

@end
