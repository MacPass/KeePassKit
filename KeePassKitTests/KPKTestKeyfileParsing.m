//
//  KPKTestKeyfileParsing.m
//  MacPass
//
//  Created by Michael Starke on 13.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"
#import "NSString+KPKHexdata.h"

#import <KissXML/KissXML.h>

@interface KPKTestKeyfileParsing : XCTestCase

@end

@implementation KPKTestKeyfileParsing

- (void)testXmlKeyfileLoadingValidFile {
  NSBundle *myBundle = [NSBundle bundleForClass:self.class];
  NSURL *url = [myBundle URLForResource:@"Keepass2Key" withExtension:@"xml"];
  NSError *error;
  NSData *keyFileData = [NSData dataWithContentsOfURL:url options:0 error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(keyFileData);
  NSData *data = [NSData kpk_keyDataForData:keyFileData version:KPKDatabaseFormatKdb error:&error];
  XCTAssertNotNil(data, @"Data should be loaded");
  XCTAssertNil(error, @"No error should occur on keyfile loading");
}

- (void)testXmlKeyfileLoadingCorruptData {
  XCTAssertFalse(NO, @"Not Implemented");
}

- (void)testXmlKeyfileLoadingMissingVersion {
  XCTAssertFalse(NO, @"Not Implemented");
}

- (void)testXmlKeyfileLoadingLowerVersion {
  XCTAssertFalse(NO, @"Not Implemented");
}

- (void)testXml1KeyfilGeneration {
  NSData *data = [NSData kpk_generateKeyfileDataOfType:KPKKeyFileTypeXMLVersion1];
  // test if structure is sound;
  XCTAssertNotNil(data, @"Keydata should have been generated");
  NSError *error;
  
  DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:data options:0 error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(document);
  
  DDXMLElement *root = [document rootElement];
  XCTAssertEqualObjects(root.name, kKPKXmlKeyFile);
  XCTAssertEqual(root.childCount, 2);
    
  DDXMLElement *metaElement = [root elementForName:kKPKXmlMeta];
  XCTAssertEqual(metaElement.childCount, 1);
  
  DDXMLElement *versionElement = [metaElement elementForName:kKPKXmlVersion];
  XCTAssertEqualObjects(versionElement.stringValue, @"1.00");
  
  DDXMLElement *keyElement = [root elementForName:kKPKXmlKey];
  XCTAssertEqual(keyElement.childCount, 1);
  
  DDXMLElement *dataElement = [keyElement elementForName:kKPKXmlData];
  XCTAssertEqual(dataElement.attributes.count, 0);
  XCTAssertEqual(dataElement.childCount, 1);
}

- (void)testXml2KeyfilGeneration {
  NSData *data = [NSData kpk_generateKeyfileDataOfType:KPKKeyFileTypeXMLVersion2];
  // test if structure is sound;
  XCTAssertNotNil(data, @"Keydata should have been generated");
  NSError *error;
  
  DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:data options:0 error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(document);
  
  DDXMLElement *root = [document rootElement];
  XCTAssertEqualObjects(root.name, kKPKXmlKeyFile);
  XCTAssertEqual(root.childCount, 2);
    
  DDXMLElement *metaElement = [root elementForName:kKPKXmlMeta];
  XCTAssertEqual(metaElement.childCount, 1);
  
  DDXMLElement *versionElement = [metaElement elementForName:kKPKXmlVersion];
  XCTAssertEqualObjects(versionElement.stringValue, @"2.00");
  
  DDXMLElement *keyElement = [root elementForName:kKPKXmlKey];
  XCTAssertEqual(keyElement.childCount, 1);
  
  DDXMLElement *dataElement = [keyElement elementForName:kKPKXmlData];
  XCTAssertEqual(dataElement.attributes.count, 1);
  XCTAssertEqual(dataElement.childCount, 1);
  
  DDXMLNode *hashAttribute = [dataElement attributeForName:kKPKXmlHash];
  XCTAssertEqual(hashAttribute.stringValue.length, 8);
}

- (void)testBinaryKeyFileGeneration {
  NSData *data = [NSData kpk_generateKeyfileDataOfType:KPKKeyFileTypeBinary];
  XCTAssertNotNil(data, @"Keydata should have been generated");
  XCTAssertEqual(data.length, 32);
}

- (void)testHexKeyFileGeneration {
  NSData *data = [NSData kpk_generateKeyfileDataOfType:KPKKeyFileTypeHex];
  XCTAssertNotNil(data, @"Keydata should have been generated");
  XCTAssertEqual(data.length, 64);
  NSString *hexString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  XCTAssertTrue(hexString.kpk_isValidHexString, @"Key data needs to be in hex format");
}

@end
