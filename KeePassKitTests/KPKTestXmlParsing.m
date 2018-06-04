//
//  KPKTestXmlParsing.m
//  MacPass
//
//  Created by Michael Starke on 03.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//


@import XCTest;
@import KissXML;

#import "KeePassKit.h"
#import "KeePassKit_Private.h"

@interface KPKTestXmlParsing : XCTestCase

@end

@implementation KPKTestXmlParsing

- (void)testEmptyXmlFile {
  DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:@"" options:0 error:NULL];
  KPKXmlTreeReader *reader = [[KPKXmlTreeReader alloc] initWithData:[document XMLData]];
  NSError *error;
  KPKTree *tree = [reader tree:&error];
  XCTAssertNil(tree, @"No Tree from empty data");
  XCTAssertNotNil(error, @"Error Object should be provided");
  XCTAssertTrue([error code] == KPKErrorNoData, @"Error Code should be No Data");
}

- (void)testNoNodeXmlFile {
  DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><root></root>" options:0 error:NULL];
  KPKXmlTreeReader *reader = [[KPKXmlTreeReader alloc] initWithData:[document XMLData]];
  NSError *error;
  KPKTree *tree = [reader tree:&error];
  XCTAssertNil(tree, @"No Tree from empty data");
  XCTAssertNotNil(error, @"Error Object should be provided");
  XCTAssertTrue([error code] == KPKErrorKdbxKeePassFileElementMissing, @"Error Code should be KeePassFile root missing");
}

- (void)testNoMetaElementXmlFile {
  DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><KeePassFile><Root></Root></KeePassFile>" options:0 error:NULL];
  KPKXmlTreeReader *reader = [[KPKXmlTreeReader alloc] initWithData:[document XMLData]];
  NSError *error;
  KPKTree *tree = [reader tree:&error];
  XCTAssertNil(tree, @"No Tree from empty data");
  XCTAssertNotNil(error, @"Error Object should be provided");
  XCTAssertTrue([error code] == KPKErrorKdbxMetaElementMissing, @"Error Code should be KeePassFile root missing");
}

@end
