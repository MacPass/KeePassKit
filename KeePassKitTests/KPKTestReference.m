//
//  KPKTestReference.m
//  MacPass
//
//  Created by Michael Starke on 15.02.14.
//  Copyright (c) 2014 HicknHack Software GmbH. All rights reserved.
//

@import  XCTest;

#import <KeePassKit/KeePassKit.h>

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

  self.entry2.title = [NSString stringWithFormat:@"{REF:T@I:%@}", [self.entry1.uuid.kpk_UUIDString substringToIndex:8]];
  XCTAssertEqualObjects([self.entry2.title kpk_finalValueForEntry:self.entry2], self.entry2.title, @"Partial UUID does not yield a match!");
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

- (void)testStructuredReferenceParsing {
  NSString *value = @"prefix {ref:p@i:0123456789ABCDEF0123456789ABCDEF} middle {REF:U@T:Example Account} suffix";
  NSArray<KPKFieldReference *> *references = [KPKFieldReference referencesInString:value];

  XCTAssertEqual(references.count, 2);
  XCTAssertEqual(references[0].wantedField, KPKReferenceFieldPassword);
  XCTAssertEqual(references[0].searchField, KPKReferenceFieldUUID);
  XCTAssertEqualObjects(references[0].searchText, @"0123456789ABCDEF0123456789ABCDEF");
  XCTAssertEqualObjects([value substringWithRange:references[0].range], references[0].rawReference);
  XCTAssertEqual(references[1].wantedField, KPKReferenceFieldUsername);
  XCTAssertEqual(references[1].searchField, KPKReferenceFieldTitle);
}

- (void)testMalformedReferencesAreNotParsed {
  XCTAssertEqual([KPKFieldReference referencesInString:@"{REF:P@I:}"].count, 0);
  XCTAssertEqual([KPKFieldReference referencesInString:@"{REF:O@I:0123456789ABCDEF0123456789ABCDEF}"].count, 0);
  XCTAssertEqual([KPKFieldReference referencesInString:@"{REF:P@X:value}"].count, 0);
}

- (void)testBuilderValidationAndCanonicalUUID {
  NSString *reference = [KPKReferenceBuilder referenceToField:KPKReferenceFieldPassword inEntry:self.entry1];
  NSString *expectedReference = [NSString stringWithFormat:@"{REF:P@I:%@}", self.entry1.uuid.kpk_UUIDString];
  XCTAssertEqualObjects(reference, expectedReference);
  XCTAssertNil([KPKReferenceBuilder reference:KPKReferenceFieldOther where:KPKReferenceFieldUUID is:self.entry1.uuid.kpk_UUIDString]);
  XCTAssertNil([KPKReferenceBuilder reference:KPKReferenceFieldPassword where:KPKReferenceFieldUUID is:@""]);
  XCTAssertNil([KPKReferenceBuilder reference:KPKReferenceFieldPassword where:KPKReferenceFieldTitle is:@"invalid}"]);
}

- (void)testDashedUUIDReferencesRemainCompatible {
  NSString *rawReference = [NSString stringWithFormat:@"{REF:P@I:%@}", self.entry1.uuid.UUIDString];
  KPKFieldReference *reference = [KPKFieldReference referencesInString:rawReference].firstObject;
  KPKFieldReferenceResolution *resolution = [KPKReferenceBuilder resolveReference:reference inTree:self.tree];

  XCTAssertEqual(resolution.status, KPKFieldReferenceResolutionStatusResolvedUnique);
  XCTAssertEqualObjects(resolution.selectedEntry, self.entry1);
}

- (void)testReferenceResolutionReportsAmbiguityInTreeOrder {
  self.entry1.title = @"Shared Production Account";
  self.entry2.title = @"Shared Production Backup";
  KPKFieldReference *reference = [KPKFieldReference referencesInString:@"{REF:U@T:Shared Production}"].firstObject;
  KPKFieldReferenceResolution *resolution = [KPKReferenceBuilder resolveReference:reference inTree:self.tree];

  XCTAssertEqual(resolution.status, KPKFieldReferenceResolutionStatusResolvedAmbiguous);
  XCTAssertEqual(resolution.matchingEntries.count, 2);
  XCTAssertEqualObjects(resolution.selectedEntry, self.entry1);
}

- (void)testEvaluationDoesNotResolveAgainstCurrentEntry {
  self.entry1.title = @"Only Current Entry Matches";
  self.entry1.notes = @"{REF:T@T:Only Current Entry}";

  XCTAssertEqualObjects([self.entry1.notes kpk_finalValueForEntry:self.entry1], self.entry1.notes);
}

- (void)testSimpleExpressionReferenceSearch {
  self.entry1.title = @"Shared Production Account";
  self.entry1.username = @"production-user";
  self.entry2.title = @"Shared Staging Account";
  self.entry2.username = @"staging-user";

  self.entry2.notes = @"{REF:U@T:Shared Production -Backup}";
  XCTAssertEqualObjects([self.entry2.notes kpk_finalValueForEntry:self.entry2], @"production-user");

  self.entry2.notes = @"{REF:U@T:\"Production Account\"}";
  XCTAssertEqualObjects([self.entry2.notes kpk_finalValueForEntry:self.entry2], @"production-user");
}

- (void)testCustomFieldSearchUsesEvaluatedCandidateValues {
  self.entry1.username = @"custom-user";
  self.entry2.username = @"Shared Production";
  [self.entry1 addCustomAttribute:[[KPKAttribute alloc] initWithKey:@"Environment" value:@"{USERNAME}"]];
  [self.entry2 addCustomAttribute:[[KPKAttribute alloc] initWithKey:@"Environment" value:@"Shared Staging"]];
  self.entry2.notes = @"{REF:U@O:Shared Production}";

  XCTAssertEqualObjects([self.entry2.notes kpk_finalValueForEntry:self.entry2], @"custom-user");
}

- (void)testStandardFieldSearchUsesEvaluatedCandidateValues {
  self.entry1.title = @"{USERNAME}";
  self.entry1.username = @"Expanded target";
  self.entry1.password = @"matched-password";
  self.entry2.notes = @"{REF:P@T:Expanded target}";

  XCTAssertEqualObjects([self.entry2.notes kpk_finalValueForEntry:self.entry2], @"matched-password");
}

- (void)testEvaluationStopsAfterFirstMatch {
  self.entry1.title = @"Shared target";
  self.entry2.title = @"Shared target";
  KPKFieldReference *reference = [KPKFieldReference referencesInString:@"{REF:U@T:Shared}"].firstObject;
  KPKFieldReferenceResolution *resolution = [KPKReferenceBuilder resolveReference:reference
                                                                            inTree:self.tree
                                                                     excludingEntry:nil
                                                                   valueTransformer:nil
                                                                 collectAllMatches:NO];

  XCTAssertEqual(resolution.matchingEntries.count, 1);
  XCTAssertEqualObjects(resolution.selectedEntry, self.entry1);
}

- (void)testUUIDWantedFieldUsesUndelimitedForm {
  self.entry2.notes = [KPKReferenceBuilder reference:KPKReferenceFieldUUID where:KPKReferenceFieldTitle is:@"Root target"];
  self.entry1.title = @"Root target";

  XCTAssertEqualObjects([self.entry2.notes kpk_finalValueForEntry:self.entry2], self.entry1.uuid.kpk_UUIDString);
}


@end
