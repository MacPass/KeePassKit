//
//  KPKXmlLoadingTest.m
//  MacPass
//
//  Created by Michael Starke on 23.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"

@interface KPKTestKdbxLoading : XCTestCase {
@private
  NSData *_data;
  KPKCompositeKey *_key;
  KPKFileVersion _kdbx4;
  KPKFileVersion _kdbx3;

}

@end


@implementation KPKTestKdbxLoading

- (void)setUp {
  NSBundle *myBundle = [NSBundle bundleForClass:self.class];
  NSURL *url = [myBundle URLForResource:@"Test_Password_1234" withExtension:@"kdbx"];
  _data = [NSData dataWithContentsOfURL:url];
  _key = [[KPKCompositeKey alloc] initWithPassword:@"1234" keyFileData:nil];
  
  _kdbx3.format = KPKDatabaseFormatKdbx;
  _kdbx3.version = kKPKKdbxFileVersion3;

  _kdbx4.format = KPKDatabaseFormatKdbx;
  _kdbx4.version = kKPKKdbxFileVersion4;
}

- (void)tearDown {
  _data = nil;
  _key = nil;
}

- (void)testLoadingAESKDFTwofishCipher {
  NSError *error;
  NSData *data =  [self _loadTestDataBase:@"TwoFishCipher256bit_test" extension:@"kdbx"];
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"test" keyFileData:nil];
  KPKTree *tree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNotNil(tree, @"Loading should result in a tree object");
  
  XCTAssertLessThanOrEqual(NSOrderedSame, KPKFileVersionCompare(tree.minimumVersion, _kdbx3));
}

- (void)testLoadingArgon2KDFAESCipher {
  NSError *error;
  NSData *data =  [self _loadTestDataBase:@"Argon2KDF_AES_Cipher_test" extension:@"kdbx"];
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"test" keyFileData:nil];
  KPKTree *tree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNotNil(tree, @"Loading should result in a tree object");
  
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(tree.minimumVersion, _kdbx4));
}

- (void)testLoadingArgon2KDFChaCha20Cipher {
  NSError *error;
  NSData *data =  [self _loadTestDataBase:@"Argon2KDF_ChaCha_Cipher_test" extension:@"kdbx"];
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"test" keyFileData:nil];
  KPKTree *tree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNotNil(tree, @"Loading should result in a tree object");
  
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(tree.minimumVersion, _kdbx4));
}

- (void)testLoadingDifferenHeaderFieldOrderStrongBox {
  NSError *error;
  NSData *data =  [self _loadTestDataBase:@"Strongbox" extension:@"kdbx"];
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"test" keyFileData:nil];
  KPKTree *tree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNotNil(tree, @"Loading should result in a tree object");
  
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(tree.minimumVersion, _kdbx4));
}

- (void)testLoadingInnerHeaderBinaries {
  NSError *error;
  NSData *data =  [self _loadTestDataBase:@"BinaryAttachments_test" extension:@"kdbx"];
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"test" keyFileData:nil];
  KPKTree *tree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNotNil(tree, @"Loading should result in a tree object");
  
  
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(tree.minimumVersion, _kdbx4));

  KPKEntry *entry = [tree.root entryForUUID:[[NSUUID alloc] initWithUUIDString:@"CE07121C-E7CB-2940-AB4A-9AD530A58622"]];
  XCTAssertNotNil(entry);
  XCTAssertEqual(entry.binaries.count, 2);
  
  NSData *binaryData = entry.binaries[0].data;
  XCTAssertEqualObjects(entry.binaries[0].name, @"Empty.xml");
  XCTAssertTrue(binaryData.length == 10694);
  /* byte 1392 0x50 */
  XCTAssertEqual(((const uint8_t*)binaryData.bytes)[1392],0x50);
  /* byte 3262 0x44 */
  XCTAssertEqual(((const uint8_t*)binaryData.bytes)[3262],0x44);
  
  binaryData = entry.binaries[1].data;
  XCTAssertEqualObjects(entry.binaries[1].name, @"New.rtf");
  XCTAssertEqual(entry.binaries[1].data.length, 155);
  /* byte 58 0x6c */
  XCTAssertEqual(((const uint8_t*)binaryData.bytes)[58],0x6c);
  /* byte 90 0x3b */
  XCTAssertEqual(((const uint8_t*)binaryData.bytes)[90],0x3b);
}

/*
- (void)testLoadingBrokenInnerHeaderBinaries {
  NSError *error;
  NSData *data =  [self _loadTestDataBase:@"Broken_BinaryAttachments_test" extension:@"kdbx"];
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"test" key:nil];
  XCTFail(@"Unfinished Test");
  KPKTree *tree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNotNil(tree, @"Loading should result in a tree object");
}
*/

- (void)testLoadingVersion3 {
  NSError *error;
  KPKTree *tree = [[KPKTree alloc] initWithData:_data key:_key error:&error];
  XCTAssertNotNil(tree, @"Loading should result in a tree object");
  
  XCTAssertEqual(tree.root.groups.count, 0, @"Tree contains just root group");
  XCTAssertEqual(tree.root.entries.count, 1, @"Tree has only one entry");
  
  XCTAssertLessThanOrEqual(NSOrderedSame, KPKFileVersionCompare(tree.minimumVersion, _kdbx3));
  
}

- (void)testAutotypeLoading {
  NSBundle *myBundle = [NSBundle bundleForClass:self.class];
  NSURL *url = [myBundle URLForResource:@"Autotype_test" withExtension:@"kdbx"];
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"test" keyFileData:nil];
  NSError *error;
  KPKTree *tree = [[KPKTree alloc] initWithContentsOfUrl:url key:key error:&error];
  XCTAssertNotNil(tree, @"Tree shoud be loaded");
  KPKEntry *entry = tree.root.entries.firstObject;
  XCTAssertNotNil(entry, @"Entry should be there");
  
  XCTAssertLessThanOrEqual(NSOrderedSame, KPKFileVersionCompare(tree.minimumVersion, _kdbx3));
}

- (NSData *)_loadTestDataBase:(NSString *)name extension:(NSString *)extension {
  NSBundle *myBundle = [NSBundle bundleForClass:self.class];
  NSURL *url = [myBundle URLForResource:name withExtension:extension];
  return [NSData dataWithContentsOfURL:url];
}

@end
