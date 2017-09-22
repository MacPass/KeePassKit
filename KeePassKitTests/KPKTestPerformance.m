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

NSUInteger const _kKPKEntryCount = 1000;
NSUInteger const _kKPKItemCount = 100;
NSUInteger const _kKPKTreeDepth = 100;

@interface KPKTestPerformance : XCTestCase {
  KPKEntry *testEntry;
  NSMutableDictionary *benchmarkDict;
  KPKTree *tree;
}
@end

@implementation KPKTestPerformance

- (void)setUp {
  [super setUp];
  testEntry = [[KPKEntry alloc] init];
  benchmarkDict = [[NSMutableDictionary alloc] init];
  NSUInteger count = _kKPKEntryCount;
  while(count-- > 0) {
    [testEntry addCustomAttribute:[[KPKAttribute alloc] initWithKey:@(count).stringValue
                                                              value:@(count).stringValue]];
    benchmarkDict[@(count).stringValue] = @(count).stringValue;
  }
  
  tree = [[KPKTree alloc] init];
  tree.root = [[KPKGroup alloc] init];
  NSUInteger depth = _kKPKTreeDepth;
  [self _add:_kKPKItemCount ofItemsToGroup:tree.root depth:&depth];
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
    id result = [testEntry customAttributeForKey:@(0).stringValue];
  }];
}
- (void)testDictLockupPerformanceA {
  [self measureBlock:^{
    id result = benchmarkDict[@(0).stringValue];
  }];
}

- (void)testAttributeLookupPerformanceB {
  [self measureBlock:^{
    id result = [testEntry customAttributeForKey:@(_kKPKEntryCount - 1).stringValue];
  }];
}
- (void)testDictLockupPerformanceB {
  [self measureBlock:^{
    id result = benchmarkDict[@(_kKPKEntryCount - 1).stringValue];
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
    NSArray <KPKEntry *> *entries = tree.allEntries;
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
    NSArray <KPKGroup *> *groups = tree.allGroups;
  }];
}


- (void)testAllEntriesRetirevalByTraversalPerformance {
  [self measureBlock:^{
    __block NSMutableArray *entries = [[NSMutableArray alloc] init];
    [tree.root _traverseNodesWithBlock:^(KPKNode *node) {
      if(node.asEntry) {
        [entries addObject:node];
      }
    }];
  }];
}

- (void)testAllGroupsRetirevalByTraversalPerformance {
  [self measureBlock:^{
    __block NSMutableArray *groups = [[NSMutableArray alloc] init];
    [tree.root _traverseNodesWithBlock:^(KPKNode *node) {
      if(node.asGroup) {
        [groups addObject:node];
      }
    }];
  }];
}




@end
