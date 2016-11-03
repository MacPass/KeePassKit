//
//  KPKXmlLoadingTest.m
//  MacPass
//
//  Created by Michael Starke on 23.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"


@interface KPKTextKdbxLoading : XCTestCase {
@private
  NSData *_data;
  KPKCompositeKey *_key;
}

@end


@implementation KPKTextKdbxLoading

- (void)setUp {
  NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
  NSURL *url = [myBundle URLForResource:@"Test_Password_1234" withExtension:@"kdbx"];
  _data = [NSData dataWithContentsOfURL:url];
  _key = [[KPKCompositeKey alloc] initWithPassword:@"1234" key:nil];
}

- (void)tearDown {
  _data = nil;
  _key = nil;
}

- (void)testLoadingArgon2KDFAESCipher {
  NSError *error;
  NSData *data =  [self _loadTestDataBase:@"Argon2KDF_AES_Cipher_test" extension:@"kdbx"];
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"test" key:nil];
  KPKTree *tree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNotNil(tree, @"Loading should result in a tree object");
}

- (void)testLoadingArgon2KDFChaCha20Cipher {
  NSError *error;
  NSData *data =  [self _loadTestDataBase:@"Argon2KDF_ChaCha_Cipher_test" extension:@"kdbx"];
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"test" key:nil];
  KPKTree *tree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNotNil(tree, @"Loading should result in a tree object");
}

- (void)testLoadingBinaries {
  NSError *error;
  NSData *data =  [self _loadTestDataBase:@"BinaryAttachments_test" extension:@"kdbx"];
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"test" key:nil];
  KPKTree *tree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNotNil(tree, @"Loading should result in a tree object");
}

- (void)testLoadingVersion3 {
  NSError *error;
  KPKTree *tree = [[KPKTree alloc] initWithData:_data key:_key error:&error];
  XCTAssertNotNil(tree, @"Loading should result in a tree object");
  
  XCTAssertEqual(tree.root.groups.count, 0, @"Tree contains just root group");
  XCTAssertEqual(tree.root.entries.count, 1, @"Tree has only one entry");
}

- (void)testAutotypeLoading {
  NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
  NSURL *url = [myBundle URLForResource:@"Autotype_test" withExtension:@"kdbx"];
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"test" key:nil];
  NSError *error;
  KPKTree *tree = [[KPKTree alloc] initWithContentsOfUrl:url key:key error:&error];
  XCTAssertNotNil(tree, @"Tree shoud be loaded");
  KPKEntry *entry = tree.root.entries.firstObject;
  XCTAssertNotNil(entry, @"Entry should be there");
}

- (NSData *)_loadTestDataBase:(NSString *)name extension:(NSString *)extension {
  NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
  NSURL *url = [myBundle URLForResource:name withExtension:extension];
  return [NSData dataWithContentsOfURL:url];
}

@end
