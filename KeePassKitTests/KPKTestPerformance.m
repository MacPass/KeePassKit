//
//  KPKTestPerformance.m
//  MacPass
//
//  Created by Michael Starke on 21/10/15.
//  Copyright © 2015 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"
#import "KeePassKit_Private.h"

NSUInteger const _kKPKAttributeCount = 1000;
NSUInteger const _kKPKItemCount = 100;
NSUInteger const _kKPKTreeDepth = 10;
NSUInteger const _kKPKGroupAndEntryCount = 50000;

@interface KPKTestPerformance : XCTestCase <KPKTreeDelegate> {
  KPKEntry *testEntry;
  NSMutableDictionary *benchmarkDict;
  KPKTree *tree;
  NSMutableArray<KPKEntry *> *entries;
  NSMutableArray<KPKGroup *> *groups;
  NSMutableArray<NSUUID *> *entryUUIDs;
  NSMutableArray<NSUUID *> *groupUUIDs;

}
@end

@implementation KPKTestPerformance

- (void)setUp {
  [super setUp];
  testEntry = [[KPKEntry alloc] init];
  benchmarkDict = [[NSMutableDictionary alloc] init];
  NSUInteger count = _kKPKAttributeCount;
  while(count-- > 0) {
    [testEntry addCustomAttribute:[[KPKAttribute alloc] initWithKey:@(count).stringValue
                                                              value:@(count).stringValue]];
    benchmarkDict[@(count).stringValue] = @(count).stringValue;
  }
  
  tree = [[KPKTree alloc] init];
  tree.root = [[KPKGroup alloc] init];
  NSUInteger depth = _kKPKTreeDepth;
  [self _add:_kKPKItemCount ofItemsToGroup:tree.root depth:&depth];
  
  entries = [[NSMutableArray alloc] initWithCapacity:_kKPKGroupAndEntryCount];
  groups = [[NSMutableArray alloc] initWithCapacity:_kKPKGroupAndEntryCount];
  entryUUIDs = [[NSMutableArray alloc] initWithCapacity:_kKPKGroupAndEntryCount];
  groupUUIDs = [[NSMutableArray alloc] initWithCapacity:_kKPKGroupAndEntryCount];
  count = _kKPKGroupAndEntryCount;
  while(count-- > 0) {
    [entries addObject:[[KPKEntry alloc] init]];
    [entryUUIDs addObject:entries.lastObject.uuid];
    [groups addObject:[[KPKGroup alloc] init]];
    [groupUUIDs addObject:groups.lastObject.uuid];
  }
}

- (void)_add:(NSUInteger)number ofItemsToGroup:(KPKGroup *)root depth:(NSUInteger *)depth{
  if(depth == 0 || *depth == 0) {
    return;
  }
  *depth = (*depth - 1);
  NSUInteger items = number;
  while(number--) {
    [[[KPKGroup alloc] init] addToGroup:root];
    [[[KPKEntry alloc] init] addToGroup:root];
  }
  for(KPKGroup *group in root.mutableGroups) {
    [self _add:items ofItemsToGroup:group depth:depth];
  }
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void)testAttributeLookupPerformanceA {
  [self measureBlock:^{
   [testEntry customAttributeForKey:@(0).stringValue];
  }];
}
- (void)testDictLockupPerformanceA {
  [self measureBlock:^{
    XCTAssertNotNil(benchmarkDict[@(0).stringValue]);
  }];
}

- (void)testAttributeLookupPerformanceB {
  [self measureBlock:^{
    XCTAssertNotNil([testEntry customAttributeForKey:@(_kKPKAttributeCount+ - 1).stringValue]);
  }];
}
- (void)testDictLockupPerformanceB {
  [self measureBlock:^{
    XCTAssertNotNil(benchmarkDict[@(_kKPKAttributeCount - 1).stringValue]);
  }];
}

- (void)testAttributeLookupPerformanceC {
  [self measureBlock:^{
    [testEntry customAttributeForKey:kKPKTitleKey];
  }];
}

- (void)testCacheMissAfterKeyChange {
  KPKAttribute *attribute = testEntry.customAttributes[10];
  NSString *value = [attribute.value copy];
  NSString *changedKey = @"ChangedKey";
  attribute.key = changedKey;
  XCTAssertEqualObjects([testEntry customAttributeForKey:changedKey].value, value);
}

- (void)testAllEntriesRetirevalByCopyPerformance {
  [self measureBlock:^{
    for(KPKEntry *entry in tree.allEntries) {}
  }];
}

- (void)testAllGroupsRetrieval {
  XCTAssertEqual(tree.allGroups.count, _kKPKItemCount * _kKPKTreeDepth);
}

- (void)testAllEntriesRetrieval {
  XCTAssertEqual(tree.allEntries.count, _kKPKItemCount * _kKPKTreeDepth);
}

- (void)testAllGroupsRetirevalByCopyPerformance {
  [self measureBlock:^{
    for(KPKGroup *group in tree.allGroups) {}
  }];
}


- (void)testAllEntriesRetirevalByTraversalPerformance {
  [self measureBlock:^{
    [tree.root _traverseNodesWithBlock:^(KPKNode *node){}];
  }];
}

- (void)testAllGroupsRetirevalByTraversalPerformance {
  [self measureBlock:^{
    [tree.root _traverseNodesWithBlock:^(KPKNode *node){}];
  }];
}

- (void)testKDBSeralizationPerformance {
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"1234" key:nil];
  [self measureBlock:^{
    [tree encryptWithKey:key format:KPKDatabaseFormatKdb error:nil];
  }];
}

- (void)testKDBDeseralizationPerformance {
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"1234" key:nil];
  NSData *data = [tree encryptWithKey:key format:KPKDatabaseFormatKdb error:nil];
  [self measureBlock:^{
    KPKTree *tree = [[KPKTree alloc] initWithData:data key:key error:nil];
    XCTAssertNotNil(tree);
  }];
}

- (void)testKDBX31SerializationPerformance {
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"1234" key:nil];
  [self measureBlock:^{
    [tree encryptWithKey:key format:KPKDatabaseFormatKdbx error:nil];
  }];
}

- (void)testKDBX31DeserializationPerformance {
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"1234" key:nil];
  NSData *data = [tree encryptWithKey:key format:KPKDatabaseFormatKdbx error:nil];
  [self measureBlock:^{
    KPKTree *tree = [[KPKTree alloc] initWithData:data key:key error:nil];
    XCTAssertNotNil(tree);
  }];
}

- (void)testKDBX4SerializationPerformance {
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"1234" key:nil];
  tree.metaData.keyDerivationParameters = [KPKArgon2KeyDerivation defaultParameters];
  [self measureBlock:^{
    XCTAssertNotNil([tree encryptWithKey:key format:KPKDatabaseFormatKdbx error:nil]);
  }];
}

- (void)testKDBX4DeserializationPerformance {
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"1234" key:nil];
  tree.metaData.keyDerivationParameters = [KPKArgon2KeyDerivation defaultParameters];
  NSData *data = [tree encryptWithKey:key format:KPKDatabaseFormatKdbx error:nil];
  [self measureBlock:^{
    KPKTree *tree = [[KPKTree alloc] initWithData:data key:key error:nil];
    XCTAssertNotNil(tree);
  }];
}


- (void)testEntryEqualityPerformance {
  KPKEntry *lastEntry = entries.lastObject;
  [self measureBlock:^{
    XCTAssertNotEqual(NSNotFound, [entries indexOfObject:lastEntry]);
  }];
}

- (void)testEntryIdentityPerformance {
  KPKEntry *lastEntry = entries.lastObject;
  [self measureBlock:^{
    XCTAssertNotEqual(NSNotFound, [entries indexOfObjectIdenticalTo:lastEntry]);
  }];
}

- (void)testUUIDEqualityPerformanceA {
  [self measureBlock:^{
    XCTAssertNotEqual(NSNotFound, [entryUUIDs indexOfObject:entryUUIDs.lastObject]);
  }];
}

- (void)testUUIDEqualityPerformanceB {
  [self measureBlock:^{
    XCTAssertNotEqual(NSNotFound, [groupUUIDs indexOfObject:groupUUIDs.lastObject]);
  }];
}

- (void)testGroupEqualityPerformance {
  KPKGroup *lastGroup = groups.lastObject;
  [self measureBlock:^{
    [groups indexOfObject:lastGroup];
  }];
}

@end
