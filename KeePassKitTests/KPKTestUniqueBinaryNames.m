//
//  KPKTestUniqueBinaryNames.m
//  KeePassKit
//
//  Created by Michael Starke on 16.05.18.
//  Copyright © 2018 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit.h"

@interface KPKTestUniqueBinaryNames : XCTestCase

@end

@implementation KPKTestUniqueBinaryNames

- (void)testAddingDuplicateBinaries {
  KPKEntry *entry = [[KPKEntry alloc] init];
  NSData *data = [NSData kpk_dataWithRandomBytes:1024];
  KPKBinary *binary1 = [[KPKBinary alloc] initWithName:@"Binary" data:data];
  KPKBinary *binary2 = [[KPKBinary alloc] initWithName:@"Binary" data:data];
  
  XCTAssertEqualObjects(binary1, binary2);
  
  [entry addBinary:binary1];
  XCTAssertEqual(entry.binaries.count, 1, @"On binary is added to entry");
  XCTAssertEqualObjects(entry.binaries.firstObject.name, @"Binary", @"Added binary has kept it's name");
  
  [entry addBinary:binary2];
  XCTAssertEqual(entry.binaries.count, 2, @"Second binary is added to entry");
  XCTAssertNotEqualObjects(entry.binaries.lastObject.name, @"Binary");
  XCTAssertNotEqualObjects(entry.binaries.firstObject, entry.binaries.lastObject);
  XCTAssertEqualObjects(entry.binaries.firstObject.data, entry.binaries.lastObject.data);
  
  [entry addBinary:binary1];
  XCTAssertEqual(entry.binaries.count, 2, @"Binary is not added a second time");
}

- (void)testLoadingDuplicateBinaryFile {
  NSBundle *myBundle = [NSBundle bundleForClass:self.class];
  NSURL *url = [myBundle URLForResource:@"Error_DuplicateAttachments_1234" withExtension:@"kdbx"];
  NSData *data = [NSData dataWithContentsOfURL:url];
  KPKCompositeKey  *key = [[KPKCompositeKey alloc] initWithPassword:@"1234" keyFileData:nil];
  NSError *error;
  
  KPKTree *tree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNotNil(tree);
  XCTAssertNil(error);
  
  KPKEntry *entry = tree.allEntries.firstObject;
  
  XCTAssertNotNil(entry);
  XCTAssertEqual(3, entry.binaries.count);
  
}

@end
