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
  XCTAssertEqualObjects(evaluated, evaluatedGoal, @"Evaluated string must match");
}

- (void)testCustomPlaceholder {
  self.entry.title = @"{USERNAME}{MYPLACEHOLDER}{PASSWORD}";
  self.entry.username = @"username";
  self.entry.password = @"password";
  self.tree.delegate = self;
  
  XCTAssertEqualObjects([self.entry.title kpk_finalValueForEntry:self.entry], @"username-MyPlaceholderValue-password", @"Custom placeholder is registered and evaluated");
}

- (void)testNoPlaceholderOrReferencePerformance {
  self.entry.password = @"0!1§2$3%4&5/6(7)8=9?t`h´i*s+I#s'A-V_e.r:s,L;o<n>g^P°aºs«s∑w€o®r†dΩW¨i⁄tøhπS•o±m‘eæEœx@t∆rºaªC©hƒa∂r‚aåc¥t≈eçs√9∫8~7µ6∞5…4–3¡2“1¶0¢";
  [self measureBlock:^{
    XCTAssertNotNil([self.entry.password kpk_finalValueForEntry:self.entry]);
  }];
}

- (void)testSinglePlaceholderEvaluationPerformace {
  self.tree.delegate = self;
  self.entry.username = @"username";
  self.entry.password = @"{USERNAME}";
  [self measureBlock:^{
    XCTAssertNotNil([self.entry.password kpk_finalValueForEntry:self.entry]);
  }];
}

- (void)testPickCharPlaceholder {
  self.tree.delegate = self;
  
  self.entry.username = @"myUserName";
  self.entry.password = @"-{USERNAME}-";
  self.entry.title = @"myTitle";
  self.entry.notes = @"{username}{pickchars}{username}";
  
  XCTAssertEqualObjects([self.entry.notes kpk_finalValueForEntry:self.entry], @"myUserName-myUserName-myUserName");

  self.entry.notes = @"{username}{pickchars:Title}{username}";
  NSString *expected = [NSString stringWithFormat:@"%@%@%@", self.entry.username, self.entry.title, self.entry.username];
  XCTAssertEqualObjects([self.entry.notes kpk_finalValueForEntry:self.entry], expected);
}

- (void)testRecursivePickCharsPlaceholder {
  self.tree.delegate = self;
  
  self.entry.username = @"{PICKCHARS:Password}";
  self.entry.password = @"{PICKCHARS:UserName}";
  
  XCTAssertEqualObjects([self.entry.username kpk_finalValueForEntry:self.entry], @"");
  
  self.entry.username = @"{PICKCHARS:Password}Username";
  self.entry.password = @"{PICKCHARS:UserName}Password";
  self.entry.notes = @"notes";

  XCTAssertEqualObjects([self.entry.username kpk_finalValueForEntry:self.entry], @"PasswordUsernamePasswordUsernamePasswordUsernamePasswordUsernamePasswordUsername");
}

- (void)testMalformedPickCharsPlaceholder {
  self.tree.delegate = self;
  self.entry.username = @"{PICKCHARS:Title,C=5}";
  
  XCTAssertEqualObjects([self.entry.username kpk_finalValueForEntry:self.entry], @"");
}

#pragma mark - KPKTreeDelegate;
- (NSString *)tree:(KPKTree *)tree resolvePlaceholder:(NSString *)placeholder forEntry:(KPKEntry *)entry {
  if([placeholder isEqualToString:@"{MYPLACEHOLDER}"]) {
    return @"-MyPlaceholderValue-";
  }
  return nil;
}

- (NSString *)tree:(KPKTree *)tree resolvePickFieldPlaceholderForEntry:(KPKEntry *)entry {
  return @"pickedField";
}

- (NSString *)tree:(KPKTree *)tree resolvePickCharsPlaceholderForValue:(NSString *)value options:(NSString *)options {
  return value ? value : @"";
}

- (BOOL)tree:(KPKTree *)tree resolveUnknownPlaceholdersInString:(NSMutableString *)string forEntry:(KPKEntry *)entry {
  return (0 < [string replaceOccurrencesOfString:@"{MYPLACEHOLDER}" withString:@"-MyPlaceholderValue-" options:NSCaseInsensitiveSearch range:NSMakeRange(0, string.length)]);
}

@end
