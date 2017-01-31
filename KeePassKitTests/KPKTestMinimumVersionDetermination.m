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
  KPKTree *tree;
  NSMutableDictionary *kdfParams;
}
@end

@implementation KPKTestMinimumVersionDetermination

- (void)setUp {
  [super setUp];
  
  kdb.format = KPKDatabaseFormatKdb;
  kdb.version = kKPKKdbFileVersion;
  
  kdbx3.format = KPKDatabaseFormatKdbx;
  kdbx3.version = kKPKKdbxFileVersion3;
  
  kdbx4.format = KPKDatabaseFormatKdbx;
  kdbx4.version = kKPKKdbxFileVersion4;
  
  tree = [[KPKTree alloc] init];
  tree.root = [[KPKGroup alloc] init];
  
  kdfParams = [tree.metaData.keyDerivationParameters mutableCopy];
}

- (void)testMinimumVersionForKeyDerivations {
  kdfParams[KPKKeyDerivationOptionUUID] = [KPKAESKeyDerivation uuid].kpk_uuidData;
  
  tree.metaData.keyDerivationParameters = [kdfParams copy];
  /* empty tree does not require KDBX */
  XCTAssertEqual(NSOrderedSame, KPKFileVersionCompare(kdb, tree.minimumVersion));
  
  kdfParams[KPKKeyDerivationOptionUUID] = [KPKArgon2KeyDerivation uuid].kpk_uuidData;
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
