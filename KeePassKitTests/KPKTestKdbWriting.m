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

@interface KPKTestKdbWriting : XCTestCase

@end

@implementation KPKTestKdbWriting

- (void)testWriting {
  NSError __autoreleasing *error = nil;
  NSURL *dbUrl = [self _urlForFile:@"CustomIcon_Password_1234" extension:@"kdbx"];
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithKeys:@[[KPKKey keyWithPassword:@"1234"]]];
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
  NSDate *expirationDate = NSDate.date.kpk_dateWithReducedPrecsion;
  
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
  
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithKeys:@[[KPKKey keyWithPassword:@"test"]]];
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

- (void)testKdbCustomIconSupport {
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
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithKeys:@[[KPKKey keyWithPassword:@"test"]]];
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

- (void)testDatabaseNameAndDescriptionSerialization {
  KPKTree *tree = [[KPKTree alloc] init];
  tree.root = [[KPKGroup alloc] init];
  
  KPKGroup *group = [[KPKGroup alloc] init];
  [group addToGroup:tree.root];
  KPKEntry *entry = [[KPKEntry alloc] init];
  [entry addToGroup:tree.root.mutableGroups.firstObject];

  NSString *databaseName = @"DatabaseName";
  NSString *databaseDescription = @"DatabaseDescription";
  
  tree.metaData.databaseName = databaseName;
  tree.metaData.databaseDescription = databaseDescription;
  
  NSError *error;
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithKeys:@[[KPKKey keyWithPassword:@"test"]]];
  NSData *data = [tree encryptWithKey:key format:KPKDatabaseFormatKdb error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(data);
  
  KPKTree *loadedTree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(loadedTree);

  XCTAssertEqualObjects(loadedTree.metaData.databaseName, databaseName);
  XCTAssertEqualObjects(loadedTree.metaData.databaseDescription, databaseDescription);
}

- (void)testTrashMetaDataSerialization {
  KPKTree *tree = [[KPKTree alloc] init];
  tree.root = [[KPKGroup alloc] init];
  
  KPKGroup *group = [[KPKGroup alloc] init];
  [group addToGroup:tree.root];
  KPKEntry *entry = [[KPKEntry alloc] init];
  [entry addToGroup:tree.root.mutableGroups.firstObject];
  KPKGroup *trash = [[KPKGroup alloc] init];
  
  NSString *trashTitle = @"TrashGroup";
  trash.title = trashTitle;
  [trash addToGroup:tree.root];
  
  tree.metaData.useTrash = YES;
  tree.trash = trash;
  
  NSError *error;
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithKeys:@[[KPKKey keyWithPassword:@"test"]]];
  NSData *data = [tree encryptWithKey:key format:KPKDatabaseFormatKdb error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(data);
  
  KPKTree *loadedTree = [[KPKTree alloc] initWithData:data key:key error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(loadedTree);
  XCTAssertTrue(loadedTree.metaData.useTrash);
  XCTAssertNotNil(loadedTree.trash);
  XCTAssertEqualObjects(loadedTree.trash.title, trashTitle);
}


- (NSData *)_dataForFile:(NSString *)name extension:(NSString *)extension {
  NSURL *url = [self _urlForFile:name extension:extension];
  return [NSData dataWithContentsOfURL:url];
}

- (NSURL *)_urlForFile:(NSString *)file extension:(NSString *)extension {
  return [[NSBundle bundleForClass:self.class] URLForResource:file withExtension:extension];
}


@end
