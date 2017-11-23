//
//  KPKTextPlaceholder.m
//  MacPass
//
//  Created by Michael Starke on 15.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"
#import "KeePassKit_Private.h"


@interface KPKTestPlaceholder : XCTestCase <KPKTreeDelegate>

@property (strong) KPKTree *tree;
@property (strong) KPKEntry *entry;

@end

@implementation KPKTestPlaceholder

- (void)setUp {
  [super setUp];
  self.tree = [[KPKTree alloc] init];
  self.tree.root = [[KPKGroup alloc] init];
  [[[KPKEntry alloc] init] addToGroup:self.tree.root];
  self.entry = self.tree.root.mutableEntries.firstObject;
}

- (void)testSimplePlaceholder {
  self.entry.title = @"TestTitle";
  self.entry.username = @"TestUsername";
  self.entry.notes = @"TestNotes";
  self.entry.url = @"TestURL";
  self.entry.password = @"TestPassword";
  KPKAttribute *attribute = [[KPKAttribute alloc] initWithKey:@"extended" value:@"valueForExtended"];
  [self.entry addCustomAttribute:attribute];
  
  NSString *placeholder = @"{USERNAME}{PASSWORD}{NOTHING}{URL}{S:extended}";
  NSString *evaluated = [placeholder kpk_finalValueForEntry:self.entry];
  NSString *evaluatedGoal = [NSString stringWithFormat:@"%@%@{NOTHING}%@%@", self.entry.username, self.entry.password, self.entry.url, attribute.value];
  XCTAssertTrue([evaluated isEqualToString:evaluatedGoal], @"Evaluated string must match");
}

- (void)testCustomPlaceholder {
  self.entry.title = @"{USERNAME}{MYPLACEHOLDER}{PASSWORD}";
  self.entry.username = @"username";
  self.entry.password = @"password";
  self.tree.delegate = self;
  
  XCTAssertEqualObjects([self.entry.title kpk_finalValueForEntry:self.entry], @"username-MyPlaceholderValue-password", @"Custom placeholder is registered and evaluated");

}

- (NSArray <NSString *> *)availablePlaceholdersForTree:(KPKTree *)tree {
  return @[ @"{MYPLACEHOLDER}" ];
}

- (NSString *)tree:(KPKTree *)tree resolvePlaceholder:(NSString *)placeholder forEntry:(KPKEntry *)entry {
  if([placeholder isEqualToString:@"{MYPLACEHOLDER}"]) {
    return @"-MyPlaceholderValue-";
  }
  return nil;
}

@end
