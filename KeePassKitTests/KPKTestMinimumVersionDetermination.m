//
//  KPKTestMinimumVersionDetermination.m
//  KeePassKit
//
//  Created by Michael Starke on 17/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit.h"
#import "KeePassKit_Private.h"

@interface KPKTestMinimumVersionDetermination : XCTestCase {
  KPKFileVersion kdb;
  KPKFileVersion kdbx3;
  KPKFileVersion kdbx4;
  KPKFileVersion kdbx4_1;
  KPKTree *tree;
  NSMutableDictionary *kdfParams;
}
@end

@implementation KPKTestMinimumVersionDetermination

- (void)setUp {
  [super setUp];
  
  kdb = KPKMakeFileVersion(KPKDatabaseFormatKdb, kKPKKdbFileVersion);
  kdbx3 = KPKMakeFileVersion(KPKDatabaseFormatKdbx, kKPKKdbxFileVersion3);
  kdbx4 = KPKMakeFileVersion(KPKDatabaseFormatKdbx, kKPKKdbxFileVersion4);
  kdbx4_1 = KPKMakeFileVersion(KPKDatabaseFormatKdbx, kKPKKdbxFileVersion4_1);
  
  tree = [[KPKTree alloc] init];
  tree.root = [[KPKGroup alloc] init];
  
  kdfParams = [tree.metaData.keyDerivationParameters mutableCopy];
}

- (void)testMinimumVersionForKeyDerivations {
  kdfParams[KPKKeyDerivationOptionUUID] = [KPKAESKeyDerivation uuid].kpk_uuidData;
  
  tree.metaData.keyDerivationParameters = [kdfParams copy];
  /* empty tree does not require KDBX */
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdb, tree.minimumVersion));
  
  kdfParams[KPKKeyDerivationOptionUUID] = [KPKArgon2DKeyDerivation uuid].kpk_uuidData;
  tree.metaData.keyDerivationParameters = [kdfParams copy];
  
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdbx4, tree.minimumVersion));
}

- (void)testMinimumVersionForEntries {
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdb, tree.minimumVersion));
  
  KPKGroup *group = [[KPKGroup alloc] init];
  [group addToGroup:tree.root];
  
  KPKEntry *entry = [[KPKEntry alloc] init];
  [entry addToGroup:group];
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdb, tree.minimumVersion));
}

- (void)testMinimumVersionForNamedIcons {
  KPKIcon *icon = [[KPKIcon alloc] initWithImage:[NSImage imageNamed:NSImageNameCaution]];
  XCTAssertEqual(0,icon.name.length);
  XCTAssertNil(icon.modificationDate);
  
  [tree.metaData addCustomIcon:icon];
  
  XCTAssertEqual(0,icon.name.length);
  XCTAssertNil(icon.modificationDate);
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(tree.minimumVersion, kdb));
  
  icon.name = @"New Icon Name";
  
  XCTAssertTrue(0 < icon.name.length);
  XCTAssertNotNil(icon.modificationDate);
  
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(tree.minimumVersion, kdbx4_1));
}

- (void)testMinimumVersionForCustomPublicData {
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdb, tree.minimumVersion));
  tree.metaData.mutableCustomPublicData[@"Key"] = @"Value";
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdbx4, tree.minimumVersion));
  tree.metaData.mutableCustomPublicData[@"Key"] = nil;
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdb, tree.minimumVersion));
}

- (void)testMinimumVersionForHistory {
  KPKGroup *group = [[KPKGroup alloc] init];
  [group addToGroup:tree.root];
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdb, tree.minimumVersion));
  
  KPKEntry *entry = [[KPKEntry alloc] init];
  [entry addToGroup:group];
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdb, tree.minimumVersion));
  
  [entry pushHistory];
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdbx3, tree.minimumVersion));
  
}

- (void)testMinimumVersionForCustomGroupData {
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdb, tree.minimumVersion));
  tree.root.mutableCustomData[@"Key"] = @"Value";
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdbx4, tree.minimumVersion));
  tree.root.mutableCustomData[@"Key"] = nil;
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdb, tree.minimumVersion));
}

- (void)testMinimumVersionForCustomEntryData {
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdb, tree.minimumVersion));
  
  KPKGroup *group = [[KPKGroup alloc] init];
  [group addToGroup:tree.root];
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdb, tree.minimumVersion));
  
  KPKEntry *entry = [[KPKEntry alloc] init];
  [entry addToGroup:group];
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdb, tree.minimumVersion));

  entry.mutableCustomData[@"Key"] = @"Value";
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdbx4, tree.minimumVersion));
  
  entry.mutableCustomData[@"Key"] = nil;
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdb, tree.minimumVersion));
}

- (void)testMinimumVersionForEntryBinaries {
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdb, tree.minimumVersion));

  KPKGroup *group = [[KPKGroup alloc] init];
  [group addToGroup:tree.root];
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdb, tree.minimumVersion));
  
  KPKEntry *entry = [[KPKEntry alloc] init];
  [entry addToGroup:group];
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdb, tree.minimumVersion));
  
  KPKBinary *binary1 = [[KPKBinary alloc] initWithName:@"Data1" data:[NSData kpk_dataWithRandomBytes:10]];
  KPKBinary *binary2 = [[KPKBinary alloc] initWithName:@"Data2" data:[NSData kpk_dataWithRandomBytes:10]];

  [entry addBinary:binary1];
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdb, tree.minimumVersion));
  
  [entry addBinary:binary2];
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdbx3, tree.minimumVersion));

  [entry removeBinary:binary1];
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdb, tree.minimumVersion));
}

@end
