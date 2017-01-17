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
  KPKWindowAssociation *a = [[KPKWindowAssociation alloc] initWithWindowTitle:@"//.*//" keystrokeSequence:@""];
  XCTAssertTrue([a matchesWindowTitle:@"Test"]);
  XCTAssertTrue([a matchesWindowTitle:@"Testing"]);
  XCTAssertTrue([a matchesWindowTitle:@"Test - some more!"]);
  XCTAssertTrue([a matchesWindowTitle:@"This is a Test!"]);
}


@end
