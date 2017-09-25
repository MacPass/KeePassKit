//
//  KPKLegacyWritingTest.m
//  MacPass
//
//  Created by Michael Starke on 02.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"
#import "KeePassKit_Private.h"

@interface KPKTestLegacyWriting : XCTestCase

@end

@implementation KPKTestLegacyWriting

- (void)testWriting {
  NSError __autoreleasing *error = nil;
  NSURL *dbUrl = [self _urlForFile:@"CustomIcon_Password_1234" extension:@"kdbx"];
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"1234" key:nil];
  KPKTree *tree = [[KPKTree alloc] initWithContentsOfUrl:dbUrl key:key error:&error];
  XCTAssertNotNil(tree, @"Tree should be created");
  error = nil;
  NSData *data = [tree encryptWithKey:key format:KPKDatabaseFormatKdb error:&error];
  XCTAssertNotNil(data, @"Serialized Data should be created");
  NSString *tempFile = [NSTemporaryDirectory() stringByAppendingString:@"CustomIcon_Password_1234.kdb"];
  NSLog(@"Saved to %@", tempFile);
  [data writeToFile:tempFile atomically:YES];
  KPKTree *loadTree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNotNil(loadTree, @"Tree should be loadable from kdb file data");
}

- (void)testLegacyCustomIconSupport {
  KPKTree *tree = [[KPKTree alloc] init];
  tree.root = [[KPKGroup alloc] init];

  KPKGroup *group = [[KPKGroup alloc] init];
  [group addToGroup:tree.root];
  KPKEntry *entry = [[KPKEntry alloc] init];
  [entry addToGroup:tree.root.mutableGroups.firstObject];
  
  
  KPKIcon *icon = [[KPKIcon alloc] initWithImage:[NSImage imageNamed:NSImageNameCaution]];
  [tree.metaData addCustomIcon:icon];
  entry.iconUUID = icon.uuid;
  
  NSError *error;
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"test" key:nil];
  NSData *data = [tree encryptWithKey:key format:KPKDatabaseFormatKdb error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(data);
  KPKTree *loadedTree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(loadedTree);
  XCTAssertEqual(loadedTree.metaData.mutableCustomIcons.count, 1);
  XCTAssertEqualObjects(loadedTree.metaData.mutableCustomIcons.firstObject.uuid, icon.uuid);
  KPKEntry *loadedEntry = [loadedTree.root entryForUUID:entry.uuid];
  XCTAssertNotNil(loadedEntry);
}

- (NSData *)_dataForFile:(NSString *)name extension:(NSString *)extension {
  NSURL *url = [self _urlForFile:name extension:extension];
  return [NSData dataWithContentsOfURL:url];
}

- (NSURL *)_urlForFile:(NSString *)file extension:(NSString *)extension {
  return [[NSBundle bundleForClass:self.class] URLForResource:file withExtension:extension];
}


@end
