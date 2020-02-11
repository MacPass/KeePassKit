//
//  KPKTestKeyFileEncryption.m
//  KeePassKit
//
//  Created by Michael Starke on 19.11.18.
//  Copyright © 2018 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <KeePassKit/KeePassKit.h>

@interface KPKTestKeyFileEncryption : XCTestCase

@end

@implementation KPKTestKeyFileEncryption

- (void)testKDBXNoPasswordKDBHexKey {
  NSBundle *myBundle = [NSBundle bundleForClass:self.class];
  NSURL *keyUrl = [myBundle URLForResource:@"Kdb1HexKey" withExtension:@"key"];
  XCTAssertNotNil(keyUrl);
  NSError *error;
  NSData *keyFileData = [NSData dataWithContentsOfURL:keyUrl options:0 error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(keyFileData);
  
  KPKCompositeKey *compositeKey = [[KPKCompositeKey alloc] initWithKeys:@[[KPKKey keyWithKeyFileData:keyFileData]]];
  XCTAssertNotNil(compositeKey);
  
  NSURL *dbUrl = [myBundle URLForResource:@"No_Password_Kdb1HexKey_Keyfile" withExtension:@"kdbx"];
  XCTAssertNotNil(dbUrl);
  NSData *dbData = [NSData dataWithContentsOfURL:dbUrl options:0 error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(dbData);
  
  KPKTree *tree = [[KPKTree alloc] initWithData:dbData key:compositeKey error:&error];
  XCTAssertNotNil(tree);
  XCTAssertNil(error);
}

- (void)testKDBNoPasswordKDBHexKey {
  NSBundle *myBundle = [NSBundle bundleForClass:self.class];
  NSURL *keyUrl = [myBundle URLForResource:@"Kdb1HexKey" withExtension:@"key"];
  XCTAssertNotNil(keyUrl);
  NSError *error;
  NSData *keyFileData = [NSData dataWithContentsOfURL:keyUrl options:0 error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(keyFileData);
  
  KPKCompositeKey *compositeKey = [[KPKCompositeKey alloc] initWithKeys:@[[KPKKey keyWithKeyFileData:keyFileData]]];
  XCTAssertNotNil(compositeKey);
  
  NSURL *dbUrl = [myBundle URLForResource:@"No_Password_Kdb1HexKey_Keyfile" withExtension:@"kdb"];
  XCTAssertNotNil(dbUrl);
  NSData *dbData = [NSData dataWithContentsOfURL:dbUrl options:0 error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(dbData);
  
  KPKTree *tree = [[KPKTree alloc] initWithData:dbData key:compositeKey error:&error];
  XCTAssertNotNil(tree);
  XCTAssertNil(error);
}

- (void)testKDBPasswordKDBHexKey {
  NSBundle *myBundle = [NSBundle bundleForClass:self.class];
  NSURL *keyUrl = [myBundle URLForResource:@"Kdb1HexKey" withExtension:@"key"];
  XCTAssertNotNil(keyUrl);
  NSError *error;
  NSData *keyFileData = [NSData dataWithContentsOfURL:keyUrl options:0 error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(keyFileData);
  
  NSArray *keys = @[[KPKKey keyWithPassword:@"test"],[KPKKey keyWithKeyFileData:keyFileData]];
  KPKCompositeKey *compositeKey = [[KPKCompositeKey alloc] initWithKeys:keys];
  XCTAssertNotNil(compositeKey);
  
  NSURL *dbUrl = [myBundle URLForResource:@"KDB1_Password_1234_Keyfile_Kdb1HexKey" withExtension:@"kdb"];
  XCTAssertNotNil(dbUrl);
  NSData *dbData = [NSData dataWithContentsOfURL:dbUrl options:0 error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(dbData);
  
  KPKTree *tree = [[KPKTree alloc] initWithData:dbData key:compositeKey error:&error];
  XCTAssertNotNil(tree);
  XCTAssertNil(error);
}

@end
