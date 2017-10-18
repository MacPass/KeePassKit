//
//  KPKTestEntryAttributes.m
//  KeePassKitTests
//
//  Created by Michael Starke on 18.10.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit.h"

@interface KPKTestEntryAttributes : XCTestCase
@property (strong) KPKEntry *entry;
@end

@implementation KPKTestEntryAttributes

- (void)setUp {
  [super setUp];
  self.entry = [[KPKEntry alloc] init];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testAddingDuplicateAttribute {
  KPKAttribute *attributeA = [[KPKAttribute alloc] initWithKey:@"Key" value:@"ValueA"];
  KPKAttribute *attributeB = [[KPKAttribute alloc] initWithKey:@"Key" value:@"ValueB"];
  
  [self.entry addCustomAttribute:attributeA];
  XCTAssertEqual(self.entry.customAttributes.count, 1, @"Attribute A is added to custom attributes");
  XCTAssertEqualObjects(attributeA.key, @"Key", @"Unique attribute key is not changed after adding attribute");
  [self.entry addCustomAttribute:attributeB];
  XCTAssertEqual(self.entry.customAttributes.count, 2, @"Attribute is added to list of custom attributes");
  XCTAssertNotEqualObjects(attributeB.key, @"Key", @"Duplicate Key is changed to unique key!");
}

- (void)testChangeAttributeKeyToDuplicateKey {
  KPKAttribute *attributeA = [[KPKAttribute alloc] initWithKey:@"KeyA" value:@"ValueA"];
  KPKAttribute *attributeB = [[KPKAttribute alloc] initWithKey:@"KeyB" value:@"ValueB"];
  
  [self.entry addCustomAttribute:attributeA];
  [self.entry addCustomAttribute:attributeB];
  XCTAssertEqual(self.entry.customAttributes.count, 2, @"Attributes are added to list of custom attributes");
  attributeB.key = attributeA.key;
  XCTAssertNotEqualObjects(attributeB.key, attributeA.key);
}

@end
