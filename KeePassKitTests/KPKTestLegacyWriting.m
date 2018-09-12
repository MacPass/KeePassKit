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

- (void)testExpirationDateSerializsation {
  NSData *packedDate = NSDate.date.kpk_packedBytes;
  NSDate *expirationDate = [NSDate kpk_dateFromPackedBytes:packedDate.bytes];
  
  
  KPKTree *tree = [[KPKTree alloc] init];
  KPKGroup *root = [[KPKGroup alloc] init];
  tree.root = root;
  KPKGroup *group = [[KPKGroup alloc] init];
  [group addToGroup:tree.root];
  group.timeInfo.expires = YES;
  group.timeInfo.expirationDate = expirationDate;
  
  KPKEntry *entry = [[KPKEntry alloc] init];
  [entry addToGroup:group];
  entry.timeInfo.expires = YES;
  entry.timeInfo.expirationDate = expirationDate;
  
  NSUUID *entryUUID = entry.uuid;
  
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"test" key:nil];
  NSError *error;
  NSData *data = [tree encryptWithKey:key format:KPKDatabaseFormatKdb error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(data);
  
  KPKTree *decryptedTree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNotNil(decryptedTree);
  XCTAssertNil(error);
  
  KPKEntry *decryptedEntry = [decryptedTree.root entryForUUID:entryUUID];
  XCTAssertNotNil(decryptedEntry);
  XCTAssertTrue(decryptedEntry.timeInfo.expires);
  XCTAssertEqualObjects(decryptedEntry.timeInfo.expirationDate, expirationDate);
  XCTAssertTrue(decryptedEntry.parent.timeInfo.expires);
  XCTAssertEqualObjects(decryptedEntry.parent.timeInfo.expirationDate, expirationDate);
  
}

- (void)testLegacyCustomIconSupport {
  KPKTree *tree = [[KPKTree alloc] init];
  tree.root = [[KPKGroup alloc] init];

  KPKGroup *group = [[KPKGroup alloc] init];
  [group addToGroup:tree.root];
  KPKEntry *entry = [[KPKEntry alloc] init];
  [entry addToGroup:tree.root.mutableGroups.firstObject];
  
  NSData *imageData = [self _dataForFile:@"image" extension:@"png"];
  KPKIcon *icon = [[KPKIcon alloc] initWithImage:[[NSUIImage alloc] initWithData:imageData]];
  
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
  KPKIcon *loadedIcon = loadedTree.metaData.mutableCustomIcons.firstObject;
  XCTAssertNotNil(loadedIcon.uuid);
  XCTAssertNotNil(loadedIcon.image);
  KPKEntry *loadedEntry = [loadedTree.root entryForUUID:entry.uuid];
  XCTAssertNotNil(loadedEntry);
  XCTAssertNotNil(loadedEntry.iconUUID);
  XCTAssertEqualObjects(loadedEntry.iconUUID, loadedIcon.uuid);
}

- (NSData *)_dataForFile:(NSString *)name extension:(NSString *)extension {
  NSURL *url = [self _urlForFile:name extension:extension];
  return [NSData dataWithContentsOfURL:url];
}

- (NSURL *)_urlForFile:(NSString *)file extension:(NSString *)extension {
  return [[NSBundle bundleForClass:self.class] URLForResource:file withExtension:extension];
}


@end
