//
//  KPKTestWindowAssociationTitleMatching.m
//  KeePassKit
//
//  Created by Michael Starke on 17/01/2017.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit.h"

@interface KPKTestWindowAssociationTitleMatching : XCTestCase
@end

@implementation KPKTestWindowAssociationTitleMatching

- (void)testSimpleWindowTitle {
  KPKWindowAssociation *a = [[KPKWindowAssociation alloc] initWithWindowTitle:@"Title" keystrokeSequence:@""];
  XCTAssertTrue([a matchesWindowTitle:@"Title"]);
  XCTAssertFalse([a matchesWindowTitle:@"Titl"]);
  XCTAssertFalse([a matchesWindowTitle:@"itle"]);
  XCTAssertFalse([a matchesWindowTitle:@"Titles"]);
  XCTAssertFalse([a matchesWindowTitle:@"aTitle"]);
}

- (void)testWildcardWindowTitle {
  KPKWindowAssociation *a = [[KPKWindowAssociation alloc] initWithWindowTitle:@"Test*" keystrokeSequence:@""];
  XCTAssertTrue([a matchesWindowTitle:@"Test"]);
  XCTAssertTrue([a matchesWindowTitle:@"Testing"]);
  XCTAssertTrue([a matchesWindowTitle:@"Test - some more!"]);
  XCTAssertFalse([a matchesWindowTitle:@"This is a Test!"]);
  
  a = [[KPKWindowAssociation alloc] initWithWindowTitle:@"*Test*" keystrokeSequence:@""];
  XCTAssertTrue([a matchesWindowTitle:@"Test"]);
  XCTAssertTrue([a matchesWindowTitle:@"Testing"]);
  XCTAssertTrue([a matchesWindowTitle:@"Test - some more!"]);
  XCTAssertTrue([a matchesWindowTitle:@"This is a Test!"]);
  
  a = [[KPKWindowAssociation alloc] initWithWindowTitle:@"*" keystrokeSequence:@""];
  XCTAssertTrue([a matchesWindowTitle:@"This is just a test!"]);
  XCTAssertTrue([a matchesWindowTitle:@"Hello"]);
  XCTAssertTrue([a matchesWindowTitle:@"abcde"]);
  XCTAssertTrue([a matchesWindowTitle:@""]);
}

- (void)testRegularExpressionWindowTitle {
  KPKWindowAssociation *catchAllAssociation = [[KPKWindowAssociation alloc] initWithWindowTitle:@"//.*//" keystrokeSequence:@""];
  XCTAssertTrue([catchAllAssociation matchesWindowTitle:@"Test"]);
  XCTAssertTrue([catchAllAssociation matchesWindowTitle:@"Testing"]);
  XCTAssertTrue([catchAllAssociation matchesWindowTitle:@"Test - some more!"]);
  XCTAssertTrue([catchAllAssociation matchesWindowTitle:@"This is a Test!"]);

  KPKWindowAssociation *option = [[KPKWindowAssociation alloc] initWithWindowTitle:@"//match|this|or|that//" keystrokeSequence:@""];
  XCTAssertTrue([option matchesWindowTitle:@"match"]);
  XCTAssertTrue([option matchesWindowTitle:@"this"]);
  XCTAssertTrue([option matchesWindowTitle:@"or"]);
  XCTAssertTrue([option matchesWindowTitle:@"that"]);
  XCTAssertFalse([option matchesWindowTitle:@"matc"]);
  XCTAssertFalse([option matchesWindowTitle:@"hi"]);
  XCTAssertFalse([option matchesWindowTitle:@"r"]);
  XCTAssertFalse([option matchesWindowTitle:@"hat"]);

  KPKWindowAssociation *pipedTitle = [[KPKWindowAssociation alloc] initWithWindowTitle:@"test|this" keystrokeSequence:@""];
  XCTAssertFalse([pipedTitle matchesWindowTitle:@"no"]);
  XCTAssertFalse([pipedTitle matchesWindowTitle:@"match"]);
  XCTAssertFalse([pipedTitle matchesWindowTitle:@"test|"]);
  XCTAssertFalse([pipedTitle matchesWindowTitle:@"test"]);
  XCTAssertFalse([pipedTitle matchesWindowTitle:@"|"]);
  XCTAssertFalse([pipedTitle matchesWindowTitle:@"this"]);
  XCTAssertTrue([pipedTitle matchesWindowTitle:@"test|this"]);
  
  KPKWindowAssociation *regularExpressionLookalike = [[KPKWindowAssociation alloc] initWithWindowTitle:@"[a-z]*[0-9]*" keystrokeSequence:@""];
  XCTAssertFalse([regularExpressionLookalike matchesWindowTitle:@"a0"]);
  XCTAssertFalse([regularExpressionLookalike matchesWindowTitle:@"0123"]);
  XCTAssertFalse([regularExpressionLookalike matchesWindowTitle:@"0a"]);
  XCTAssertTrue([regularExpressionLookalike matchesWindowTitle:@"[a-z][0-9]"]);
  XCTAssertTrue([regularExpressionLookalike matchesWindowTitle:@"[a-z]hallo[0-9]"]);
  XCTAssertTrue([regularExpressionLookalike matchesWindowTitle:@"[a-z]1one2two3three![0-9]"]);
  XCTAssertTrue([regularExpressionLookalike matchesWindowTitle:@"[a-z][0-9]at0-001ß"]);
  
  KPKWindowAssociation *characterClasses = [[KPKWindowAssociation alloc] initWithWindowTitle:@"//^([a-z]*|[0-9]+)$//" keystrokeSequence:@""];
  XCTAssertTrue([characterClasses matchesWindowTitle:@"0"]);
  XCTAssertTrue([characterClasses matchesWindowTitle:@"9"]);
  XCTAssertTrue([characterClasses matchesWindowTitle:@"123456789"]);
  XCTAssertTrue([characterClasses matchesWindowTitle:@"abcd"]);
  XCTAssertTrue([characterClasses matchesWindowTitle:@"hallo"]);
  XCTAssertTrue([characterClasses matchesWindowTitle:@"nicematchyougotthere"]);
  XCTAssertFalse([characterClasses matchesWindowTitle:@"I don't think so!"]);
  XCTAssertFalse([characterClasses matchesWindowTitle:@"a9"]);
  XCTAssertFalse([characterClasses matchesWindowTitle:@"9a"]);
  XCTAssertFalse([characterClasses matchesWindowTitle:@"a9"]);
}


@end
