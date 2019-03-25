//
//  KPKTestReference.m
//  MacPass
//
//  Created by Michael Starke on 15.02.14.
//  Copyright (c) 2014 HicknHack Software GmbH. All rights reserved.
//

@import  XCTest;

#import "KeePassKit.h"

@interface KPKTestReference : XCTestCase
@property (strong) KPKTree *tree;
@property (weak) KPKEntry *entry1;
@property (weak) KPKEntry *entry2;

@end

@implementation KPKTestReference

- (void)setUp {
  self.tree = [[KPKTree alloc] init];
  
  self.tree.root = [[KPKGroup alloc] init];
  self.tree.root.title = @"Root";
  
  KPKEntry *entry1 = [self.tree createEntry:self.tree.root];
  KPKEntry *entry2 = [self.tree createEntry:self.tree.root];
  [entry1 addToGroup:self.tree.root];
  [entry2 addToGroup:self.tree.root];
  self.entry1 = entry1;
  self.entry2 = entry2;
  
  self.entry1.url = @"-Entry1URL-";
  self.entry2.url = @"-Entry2URL-";
  
  [super setUp];
}

- (void)tearDown {
  self.tree = nil;
  [super tearDown];
}

- (void)testCorrectUUIDReference {
  self.entry1.title = @"-Entry1Title-";
  self.entry2.title = [[NSString alloc] initWithFormat:@"Nothing{ref:t@i:%@}Changed", self.entry1.uuid.UUIDString];;
  self.entry2.url = @"-Entry2URL-";
  
  NSString *result = [self.entry2.title kpk_finalValueForEntry:self.entry2];
  XCTAssertEqualObjects(result, @"Nothing-Entry1Title-Changed", @"Reference with delemited UUID string matches!");
  
  NSString *undelemitedUUIDString = [self.entry1.uuid.UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""];
  self.entry2.title = [[NSString alloc] initWithFormat:@"Nothing{ref:t@i:%@}Changed", undelemitedUUIDString];;
  
  XCTAssertEqualObjects([self.entry2.title kpk_finalValueForEntry:self.entry2], @"Nothing-Entry1Title-Changed", @"Reference with undelemtied UUID string matches!");
}

- (void)testRecursiveUUIDReference{
  self.entry1.title = [[NSString alloc] initWithFormat:@"Title1{REF:A@i:%@}", self.entry2.uuid.UUIDString];
  self.entry2.title = [[NSString alloc] initWithFormat:@"Nothing{REF:t@I:%@}Changed", self.entry1.uuid.UUIDString];
  
  XCTAssertEqualObjects([self.entry2.title kpk_finalValueForEntry:self.entry2], @"NothingTitle1-Entry2URL-Changed", @"Replaced Strings should match");
}

- (void)testRecursiveUUIDReferencePerformance {
  self.entry1.title = [[NSString alloc] initWithFormat:@"Title1{REF:A@i:%@}", self.entry2.uuid.UUIDString];
  self.entry2.title = [[NSString alloc] initWithFormat:@"Nothing{REF:t@I:%@}Changed", self.entry1.uuid.UUIDString];
  
  [self measureBlock:^{
    XCTAssertEqualObjects([self.entry2.title kpk_finalValueForEntry:self.entry2], @"NothingTitle1-Entry2URL-Changed", @"Replaced Strings should match");
  }];
}

- (void)testReferenceSearchKeys {
  
  self.entry1.title = @"Entry1Title";
  self.entry1.username = @"Entry1Username";
  self.entry1.password = @"Entry1Password";
  self.entry1.url = @"Entry1URL";
  self.entry1.notes = @"Entry1Notes";
  
  
  
  NSDictionary *values = @{ @(KPKReferenceFieldTitle)       : self.entry1.title,
                            @(KPKReferenceFieldUsername)    : self.entry1.username,
                            @(KPKReferenceFieldPassword)    : self.entry1.password,
                            @(KPKReferenceFieldUrl)         : self.entry1.url,
                            @(KPKReferenceFieldNotes)       : self.entry1.notes };
  
  for(NSNumber *where in values) {
    KPKReferenceField whereField = where.unsignedIntegerValue;
    
    for(NSNumber *reference in values) {
      KPKReferenceField referenceField = reference.unsignedIntegerValue;
      NSString *referenceString = [KPKReferenceBuilder reference:referenceField where:whereField is:values[where]];
      self.entry2.title = referenceString;
      NSString *actual = [self.entry2.title kpk_finalValueForEntry:self.entry2];
      XCTAssertEqualObjects(actual, values[reference]);
    }
  }
}


- (void)testPlaceholderReference {
  self.entry1.title = [NSString stringWithFormat:@"{%@}", kKPKUsernameKey];
  self.entry1.username = [NSString stringWithFormat:@"Title1{REF:T@i:%@}", self.entry2.uuid.UUIDString];
  self.entry1.notes = [NSString stringWithFormat:@"Notes1{REF:U@i:%@}", self.entry2.uuid.UUIDString];
  self.entry2.title = @"-Entry2Title-";
  self.entry2.username = [NSString stringWithFormat:@"{%@}", kKPKURLKey];
  
  XCTAssertEqualObjects([self.entry1.title kpk_finalValueForEntry:self.entry1], @"Title1-Entry2Title-", @"Reverences in placeholders should be evaluated");
  XCTAssertEqualObjects([self.entry1.notes kpk_finalValueForEntry:self.entry1], @"Notes1-Entry2URL-", @"Placeholder in references should evaluate to references entry");
}

- (void)testRecursion {
  self.entry1.title = [NSString stringWithFormat:@"{%@}", kKPKUsernameKey];
  self.entry1.username = [NSString stringWithFormat:@"{%@}", kKPKTitleKey];
  
  XCTAssertNotNil([self.entry1.title kpk_finalValueForEntry:self.entry1]);
  XCTAssertNotNil([self.entry1.username kpk_finalValueForEntry:self.entry1]);
}

- (void)testMalformedUUIDReferences {
  self.entry1.title = @"Title1";
  self.entry2.title = [[NSString alloc] initWithFormat:@"{REF:T@I:%@-}", self.entry1.uuid.UUIDString];
  
  XCTAssertNoThrow([self.entry2.title kpk_finalValueForEntry:self.entry2], @"Malformed UUID string does not throw exception!");
  XCTAssertEqualObjects([self.entry2.title kpk_finalValueForEntry:self.entry2], self.entry2.title, @"Malformed UUID does not yield a match!");
}

- (void)testReferncePasswordByTitle {
  self.entry1.title = [[NSString alloc] initWithFormat:@"Title1{REF:A@i:%@}", self.entry2.uuid.UUIDString];
  self.entry2.title = [[NSString alloc] initWithFormat:@"Nothing{REF:t@I:%@}Changed", self.entry1.uuid.UUIDString];
  
  NSString *result = [self.entry2.title kpk_finalValueForEntry:self.entry2];
  XCTAssertEqualObjects(result, @"NothingTitle1-Entry2URL-Changed", @"Replaced Strings should match");
}

- (void)testReferncePasswordByCustomAttribute {
  self.entry1.title = [[NSString alloc] initWithFormat:@"Title1{REF:T@i:%@}", self.entry2.uuid.UUIDString];
  self.entry2.title = @"Entry2Title";
  
  KPKAttribute *attribute1 = [[KPKAttribute alloc] initWithKey:@"Custom1" value:@"Value1"];
  [self.entry2 addCustomAttribute:attribute1];
  KPKAttribute *attribute2 = [[KPKAttribute alloc] initWithKey:@"Custom2" value:@"Value2"];
  [self.entry2 addCustomAttribute:attribute2];
}

- (void)testMultipleReferences {
  self.entry1.username = [NSString stringWithFormat:@"Username:{REF:U@I:%@} Password:{REF:P@I:%@}", self.entry2.uuid.UUIDString, self.entry2.uuid.UUIDString];
  self.entry1.password = @"Password1";
  self.entry2.username = @"Username2";
  self.entry2.password = @"Password2";
  NSString *actual = [self.entry1.username kpk_finalValueForEntry:self.entry1];
  NSString *expected = [NSString stringWithFormat:@"Username:%@ Password:%@", self.entry2.username, self.entry2.password];
  XCTAssertEqualObjects(actual,expected, @"Multiple references inside a string get resolved correctly");
}


@end
