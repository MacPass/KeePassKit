//
//  KPKTestKVO.m
//  KeePassKit
//
//  Created by Michael Starke on 19/12/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit.h"
#import "KeePassKit_Private.h"

#if KPK_MAC

@interface KPKTestKVO : XCTestCase
@property (copy) NSString *string;
@property (copy) NSDate *date;
@property (strong) NSArrayController *entryArrayController;
@end

@implementation KPKTestKVO


- (void)testEntryAttribugeKVO {
  KPKEntry *entry = [[KPKEntry alloc] init];
  entry.username = @"Username";
  entry.title = @"Title";
  entry.notes = @"Notes";
  entry.password = @"Password";
  entry.url = @"URL";
  
  [self _bindAndTestEntry:entry selector:@selector(username)];
  [self _bindAndTestEntry:entry selector:@selector(title)];
  [self _bindAndTestEntry:entry selector:@selector(notes)];
  [self _bindAndTestEntry:entry selector:@selector(password)];
  [self _bindAndTestEntry:entry selector:@selector(url)];
}

- (void)testGroupAttributesKVO {
  KPKGroup *group = [[KPKGroup alloc] init];
  group.title = @"Title";
  group.notes = @"Notes";
  
  [self _bindAndTestGroup:group selector:@selector(title)];
  [self _bindAndTestGroup:group selector:@selector(notes)];
}

- (void)testGroupChildrenKVO {
  KPKGroup *group = [[KPKGroup alloc] init];

  [[[KPKEntry alloc] init] addToGroup:group];

  NSUInteger groups = 5;
  while(groups--) {
    KPKGroup *subGroup = [[KPKGroup alloc] init];
    [subGroup addToGroup:group];
    [[[KPKEntry alloc] init] addToGroup:subGroup];
    NSUInteger subGroups = 5;
    while(subGroups--) {
      [[[KPKGroup alloc] init] addToGroup:subGroup];
    }
  }
}

- (void)testGroupsAndEntriesArrayValues {
  KPKGroup *group = [[KPKGroup alloc] init];
  id groups = [group valueForKey:KPKGroupsArrayBinding];
  id entries = [group valueForKey:KPKEntriesArrayBinding];
  XCTAssertEqual([groups count], 0);
  XCTAssertEqual([entries count], 0);
  
  for(NSUInteger index=0; index < 5; index++) {
    [[[KPKGroup alloc] init] addToGroup:group];
  }

  XCTAssertEqual([groups count], 5);
  XCTAssertEqual([entries count], 0);
  
  for(NSUInteger index=0; index < 5; index++) {
    [[[KPKEntry alloc] init] addToGroup:group];
  }

  XCTAssertEqual([groups count], 5);
  XCTAssertEqual([entries count], 5);

  for(NSUInteger index=0; index < 5; index++) {
    KPKGroup *subGroup = [groups objectAtIndex:4-index];
    KPKGroup *actualSubgroup = group.mutableGroups[4-index];
    XCTAssertNotNil(subGroup);
    XCTAssertEqual(subGroup, actualSubgroup);
    XCTAssertEqual([groups count], group.mutableGroups.count);
    [subGroup remove];
  }
  
  XCTAssertEqual([groups count], 0);
  XCTAssertEqual([entries count], 5);
  
  for(NSInteger index=0; index < 5 ; index++) {
    KPKEntry *subEntry = [entries objectAtIndex:4-index];
    KPKEntry *actualSubEntry = group.mutableEntries[4-index];
    XCTAssertNotNil(subEntry);
    XCTAssertEqual(subEntry, actualSubEntry);
    XCTAssertEqual([entries count], group.mutableEntries.count);
    
    [subEntry remove];
  }
  
  XCTAssertEqual([groups count], 0);
  XCTAssertEqual([entries count], 0);
  
}

- (void)_bindAndTestGroup:(KPKGroup *)group selector:(SEL)selector {
  [self bind:NSStringFromSelector(@selector(string)) toObject:group withKeyPath:NSStringFromSelector(selector) options:nil];
  [group setValue:@"Test" forKey:NSStringFromSelector(selector)];
  XCTAssertEqualObjects([group valueForKey:NSStringFromSelector(selector)], self.string);
  [self unbind:NSStringFromSelector(@selector(string))];
}

- (void)_bindAndTestEntry:(KPKEntry *)entry selector:(SEL)selector {
  NSMutableArray *oldAttributes = [[NSMutableArray alloc] initWithArray:entry.mutableAttributes copyItems:YES];
  NSString *oldValue = [entry valueForKey:NSStringFromSelector(selector)];
  [self bind:NSStringFromSelector(@selector(string)) toObject:entry withKeyPath:NSStringFromSelector(selector) options:nil];
  [entry setValue:@"Test" forKey:NSStringFromSelector(selector)];
  XCTAssertEqualObjects([entry valueForKey:NSStringFromSelector(selector)], self.string);
  entry.mutableAttributes = oldAttributes;
  XCTAssertEqualObjects([entry valueForKey:NSStringFromSelector(selector)], self.string);
  XCTAssertEqualObjects(self.string, oldValue);
  
  [self unbind:NSStringFromSelector(@selector(string))];
}

@end

#endif
