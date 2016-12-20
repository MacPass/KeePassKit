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
@property (copy) NSDate *date;
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

- (void)testGroupKVO {
  KPKGroup *group = [[KPKGroup alloc] init];
  group.title = @"Title";
  group.notes = @"Notes";
  
  [self _bindAndTestGroup:group selector:@selector(title)];
  [self _bindAndTestGroup:group selector:@selector(notes)];
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
