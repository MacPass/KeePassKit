//
//  MPTestToken.m
//  MacPassTests
//
//  Created by Michael Starke on 07.11.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KPKToken.h"

@interface KPKTestToken : XCTestCase

@end

@implementation KPKTestToken

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testSimpleTokenizing {
  NSArray <KPKToken *> *tokens = [KPKToken tokenizeString:@"{^}{USERNAME}^S+H{SPACE}"];
  XCTAssertEqual(7, tokens.count);
  
  XCTAssertEqual(7, tokens.count);
  XCTAssertEqualObjects(@"{^}", tokens[0].value);
  XCTAssertEqualObjects(@"{USERNAME}", tokens[1].value);
  XCTAssertEqualObjects(@"^", tokens[2].value);
  XCTAssertEqualObjects(@"S", tokens[3].value);
  XCTAssertEqualObjects(@"+", tokens[4].value);
  XCTAssertEqualObjects(@"H", tokens[5].value);
  XCTAssertEqualObjects(@"{SPACE}", tokens[6].value);
  
  tokens = [KPKToken tokenizeString:@"{^}{USERNAME 2}^S+H{SPACE 2}"];
  XCTAssertEqual(7, tokens.count);
  XCTAssertEqualObjects(@"{^}", tokens[0].value);
  XCTAssertEqualObjects(@"{USERNAME 2}", tokens[1].value);
  XCTAssertEqualObjects(@"^", tokens[2].value);
  XCTAssertEqualObjects(@"S", tokens[3].value);
  XCTAssertEqualObjects(@"+", tokens[4].value);
  XCTAssertEqualObjects(@"H", tokens[5].value);
  XCTAssertEqualObjects(@"{SPACE 2}", tokens[6].value);
}

- (void)testCurlyBraketTokenizing {
  NSArray <KPKToken *> *tokens = [KPKToken tokenizeString:@"{{}{}}{USERNAME}ABC"];
  XCTAssertEqual(6, tokens.count);
  XCTAssertEqualObjects(@"{{}", tokens[0].value);
  XCTAssertEqualObjects(@"{}}", tokens[1].value);
  XCTAssertEqualObjects(@"{USERNAME}", tokens[2].value);
  XCTAssertEqualObjects(@"A", tokens[3].value);
  XCTAssertEqualObjects(@"B", tokens[4].value);
  XCTAssertEqualObjects(@"C", tokens[5].value);
}

- (void)testMalformedTokenizing {
  NSArray <KPKToken *> *tokens = [KPKToken tokenizeString:@"{USERNAME}ABC{{TEST"];
  XCTAssertEqual(4, tokens.count);
  XCTAssertEqualObjects(@"{USERNAME}", tokens[0].value);
  XCTAssertEqualObjects(@"A", tokens[1].value);
  XCTAssertEqualObjects(@"B", tokens[2].value);
  XCTAssertEqualObjects(@"C", tokens[3].value);
}

- (void)testReferenceTokenizing {
  NSArray <KPKToken *> *tokens = [KPKToken tokenizeString:@"{REF:I@T:Test Title for Search}A BC{+}+"];
  XCTAssertEqual(7, tokens.count);
  XCTAssertEqualObjects(@"{REF:I@T:Test Title for Search}", tokens[0].value);
  XCTAssertEqualObjects(@"A", tokens[1].value);
  XCTAssertEqualObjects(@" ", tokens[2].value);
  XCTAssertEqualObjects(@"B", tokens[3].value);
  XCTAssertEqualObjects(@"C", tokens[4].value);
  XCTAssertEqualObjects(@"{+}", tokens[5].value);
  XCTAssertEqualObjects(@"+", tokens[6].value);
}

- (void)testEmojiTokenizing {
  NSArray <KPKToken *> *tokens = [KPKToken tokenizeString:@"{TAB}😀A👢B👴🏼C{🐱}{ENTER}"];
  XCTAssertEqual(9, tokens.count);
  XCTAssertEqualObjects(@"{TAB}", tokens[0].value);
  XCTAssertEqualObjects(@"😀", tokens[1].value);
  XCTAssertEqualObjects(@"A", tokens[2].value);
  XCTAssertEqualObjects(@"👢", tokens[3].value);
  XCTAssertEqualObjects(@"B", tokens[4].value);
  XCTAssertEqualObjects(@"👴🏼", tokens[5].value);
  XCTAssertEqualObjects(@"C", tokens[6].value);
  XCTAssertEqualObjects(@"{🐱}", tokens[7].value);
  XCTAssertEqualObjects(@"{ENTER}", tokens[8].value);
}

@end
