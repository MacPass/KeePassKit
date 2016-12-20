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

@interface KPKTestKVO : XCTestCase
@property (copy) NSString *string;
@end

@implementation KPKTestKVO


- (void)testEntryKVO {
  KPKEntry *entry = [[KPKEntry alloc] init];
  
  /* username */
  [self _bindAndTestEntry:entry selector:@selector(username)];
  [self _bindAndTestEntry:entry selector:@selector(title)];
  [self _bindAndTestEntry:entry selector:@selector(notes)];
  [self _bindAndTestEntry:entry selector:@selector(password)];
  [self _bindAndTestEntry:entry selector:@selector(url)];

  XCTFail(@"Incomplete Test");
}

- (void)testGroupKVO {
  XCTFail(@"Missing Test");
}

- (void)_bindAndTestEntry:(KPKEntry *)entry selector:(SEL)selector {
  [self bind:NSStringFromSelector(@selector(string)) toObject:entry withKeyPath:NSStringFromSelector(selector) options:nil];
  [entry setValue:@"Test" forKey:NSStringFromSelector(selector)];
  XCTAssertEqualObjects([entry valueForKey:NSStringFromSelector(selector)], self.string);
  [self unbind:NSStringFromSelector(@selector(string))];
}

@end
