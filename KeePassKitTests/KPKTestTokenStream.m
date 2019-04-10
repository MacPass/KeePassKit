//
//  MPTestToken.m
//  MacPassTests
//
//  Created by Michael Starke on 07.11.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KPKToken.h"
#import "KPKTokenStream.h"

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
  KPKTokenStream *stream = [KPKTokenStream tokenStreamWithValue:@"{^}{USERNAME}^S+H{SPACE}"];
  XCTAssertEqual(7, stream.tokenCount);
  
  XCTAssertEqual(7, stream.tokenCount);
  XCTAssertEqualObjects(@"{^}", stream.tokens[0].value);
  XCTAssertEqualObjects(@"{USERNAME}", stream.tokens[1].value);
  XCTAssertEqualObjects(@"^", stream.tokens[2].value);
  XCTAssertEqualObjects(@"S", stream.tokens[3].value);
  XCTAssertEqualObjects(@"+", stream.tokens[4].value);
  XCTAssertEqualObjects(@"H", stream.tokens[5].value);
  XCTAssertEqualObjects(@"{SPACE}", stream.tokens[6].value);
  
  stream = [KPKTokenStream tokenStreamWithValue:@"{^}{USERNAME 2}^S+H{SPACE 2}"];
  XCTAssertEqual(7, stream.tokenCount);
  XCTAssertEqualObjects(@"{^}", stream.tokens[0].value);
  XCTAssertEqualObjects(@"{USERNAME 2}", stream.tokens[1].value);
  XCTAssertEqualObjects(@"^", stream.tokens[2].value);
  XCTAssertEqualObjects(@"S", stream.tokens[3].value);
  XCTAssertEqualObjects(@"+", stream.tokens[4].value);
  XCTAssertEqualObjects(@"H", stream.tokens[5].value);
  XCTAssertEqualObjects(@"{SPACE 2}", stream.tokens[6].value);
}

- (void)testCurlyBraketTokenizing {
  KPKTokenStream *stream = [KPKTokenStream tokenStreamWithValue:@"{{}{}}{USERNAME}ABC"];
  XCTAssertEqual(6, stream.tokenCount);
  XCTAssertEqualObjects(@"{{}", stream.tokens[0].value);
  XCTAssertEqualObjects(@"{}}", stream.tokens[1].value);
  XCTAssertEqualObjects(@"{USERNAME}", stream.tokens[2].value);
  XCTAssertEqualObjects(@"A", stream.tokens[3].value);
  XCTAssertEqualObjects(@"B", stream.tokens[4].value);
  XCTAssertEqualObjects(@"C", stream.tokens[5].value);
}

- (void)testMalformedTokenizing {
  KPKTokenStream *stream = [KPKTokenStream tokenStreamWithValue:@"{USERNAME}ABC{{TEST"];
  XCTAssertEqual(4, stream.tokenCount);
  XCTAssertEqualObjects(@"{USERNAME}", stream.tokens[0].value);
  XCTAssertEqualObjects(@"A", stream.tokens[1].value);
  XCTAssertEqualObjects(@"B", stream.tokens[2].value);
  XCTAssertEqualObjects(@"C", stream.tokens[3].value);
}

- (void)testReferenceTokenizing {
  KPKTokenStream *stream = [KPKTokenStream tokenStreamWithValue:@"{REF:I@T:Test Title for Search}A BC{+}+"];
  XCTAssertEqual(7, stream.tokenCount);
  XCTAssertEqualObjects(@"{REF:I@T:Test Title for Search}", stream.tokens[0].value);
  XCTAssertEqualObjects(@"A", stream.tokens[1].value);
  XCTAssertEqualObjects(@" ", stream.tokens[2].value);
  XCTAssertEqualObjects(@"B", stream.tokens[3].value);
  XCTAssertEqualObjects(@"C", stream.tokens[4].value);
  XCTAssertEqualObjects(@"{+}", stream.tokens[5].value);
  XCTAssertEqualObjects(@"+", stream.tokens[6].value);
}

- (void)testEmojiTokenizing {
  KPKTokenStream *stream = [KPKTokenStream tokenStreamWithValue:@"👴🏼{TAB}😀A👢BC{🐱}{ENTER}ṓ"];
  NSUInteger index = 0;
#if __LP64__ || NS_BUILD_32_LIKE_64
  XCTAssertEqual(10, stream.tokenCount);
  XCTAssertEqualObjects(@"👴🏼", stream.tokens[index++].value);
#else
  XCTAssertEqual(11, stream.tokenCount);
  XCTAssertEqualObjects(@"👴", stream.tokens[index++].value);
  XCTAssertEqualObjects(@"🏼", stream.tokens[index++].value);
#endif
  XCTAssertEqualObjects(@"{TAB}", stream.tokens[index++].value);
  XCTAssertEqualObjects(@"😀", stream.tokens[index++].value);
  XCTAssertEqualObjects(@"A", stream.tokens[index++].value);
  XCTAssertEqualObjects(@"👢", stream.tokens[index++].value);
  XCTAssertEqualObjects(@"B", stream.tokens[index++].value);
  XCTAssertEqualObjects(@"C", stream.tokens[index++].value);
  XCTAssertEqualObjects(@"{🐱}", stream.tokens[index++].value);
  XCTAssertEqualObjects(@"{ENTER}", stream.tokens[index++].value);
  XCTAssertEqualObjects(@"ṓ", stream.tokens[index++].value);
}

@end
