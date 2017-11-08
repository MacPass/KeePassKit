//
//  KPKTextXMLUtilities.m
//  MacPass
//
//  Created by Michael Starke on 12/12/14.
//  Copyright (c) 2014 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"

@interface KPKTestXMLUtilities : XCTestCase

@end

@implementation KPKTestXMLUtilities

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testUnsaveEscaping {
  NSString *unsave = @"*EORDIE\x10\x16\x12\x10";
  XCTAssertEqualObjects(@"*EORDIE", unsave.kpk_xmlCompatibleString);
}

@end
