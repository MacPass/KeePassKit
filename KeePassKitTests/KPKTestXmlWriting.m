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
  NSData *data = [self _loadTestDataBase:@"CustomIcon_Password_1234" extension:@"kdbx"];
  NSError *error;
  KPKCompositeKey *password = [[KPKCompositeKey alloc] initWithPassword:@"1234" key:nil];
  KPKTree *tree = [[KPKTree alloc] initWithData:data password:password error:&error];
  error = nil;
  NSData *saveData = [tree encryptWithPassword:password forVersion:KPKXmlVersion error:&error];
  XCTAssertNotNil(saveData, @"Serialization should yield data");
  NSString *tempFile = [NSTemporaryDirectory() stringByAppendingString:@"CustomIcon_Password_1234_save.kdbx"];
  NSLog(@"Saved file to %@", tempFile);
  [saveData writeToFile:tempFile atomically:YES];
  
  error = nil;
  NSURL *url = [NSURL fileURLWithPath:tempFile];
  KPKTree *reloadedTree = [[KPKTree alloc] initWithContentsOfUrl:url password:password error:&error];
  XCTAssertNotNil(reloadedTree, @"Reloaded tree should not be nil");
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
  
  KPKCompositeKey *password = [[KPKCompositeKey alloc] initWithPassword:@"1234" key:nil];
  NSError *error;
  NSData *data = [tree encryptWithPassword:password forVersion:KPKXmlVersion error:&error];
  XCTAssertNotNil(data, @"Tree encryption yields data!");
  
  KPKTree *decryptedTree = [[KPKTree alloc] initWithData:data password:password error:&error];
  XCTAssertNotNil(decryptedTree, @"Initalized tree from data is present!");
  KPKEntry *decryptedEntry = [tree.root entryForUUID:uuid];
  XCTAssertNotNil(entry, @"Encrypted entry is decryted!");
  XCTAssertEqualObjects(entry, decryptedEntry, @"Decrypted entry is the same as the encrypted one");
  
}

- (NSData *)_loadTestDataBase:(NSString *)name extension:(NSString *)extension {
  NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
  NSURL *url = [myBundle URLForResource:name withExtension:extension];
  return [NSData dataWithContentsOfURL:url];
}

@end
