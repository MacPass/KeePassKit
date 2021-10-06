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

- (void)testValidXmlv1KeyfileLoading {
  NSBundle *myBundle = [NSBundle bundleForClass:self.class];
  NSURL *url = [myBundle URLForResource:@"Keepass2Key_v1" withExtension:@"xml"];
  NSError *error;
  NSData *keyFileData = [NSData dataWithContentsOfURL:url options:0 error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(keyFileData);
  KPKFileKey *fileKey = [[KPKFileKey alloc] initWithKeyFileData:keyFileData error:&error];
  XCTAssertNotNil(fileKey, @"Data should be loaded");
  XCTAssertNil(error, @"No error should occur on keyfile loading");
}

- (void)testValidXmlv2KeyfileLoading {
  NSBundle *myBundle = [NSBundle bundleForClass:self.class];
  NSURL *url = [myBundle URLForResource:@"Keepass2Key_v2" withExtension:@"keyx"];
  NSError *error;
  NSData *keyFileData = [NSData dataWithContentsOfURL:url options:0 error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(keyFileData);
  KPKFileKey *fileKey = [[KPKFileKey alloc] initWithKeyFileData:keyFileData error:&error];
  XCTAssertNotNil(fileKey, @"Data should be loaded");
  XCTAssertNil(error, @"No error should occur on keyfile loading");
}


- (void)testXmlv1KeyfileLoadingCorruptData {
  NSString *file = @"<KeyFile><Meta><Version>1.0</Version></Meta><Key><Data>ThisIsNoBase64Data</Data></Key></KeyFile>";
  NSError *error;
  DDXMLDocument *doc = [[DDXMLDocument alloc] initWithXMLString:file options:0 error:&error];
  
  XCTAssertNil(error);
  XCTAssertNotNil(doc);
  
  NSData *fileData = [doc XMLData];
  KPKFileKey *fileKey = [[KPKFileKey alloc] initWithKeyFileData:fileData error:&error];
  XCTAssertNotNil(fileKey);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, KPKErrorKdbxKeyDataParsingError);
}

- (void)testXmlKeyfileLoadingMissingVersion {
  NSString *file = @"<KeyFile><Meta></Meta><Key><Data>NODATA</Data></Key></KeyFile>";
  NSError *error;
  DDXMLDocument *doc = [[DDXMLDocument alloc] initWithXMLString:file options:0 error:&error];
  
  XCTAssertNil(error);
  XCTAssertNotNil(doc);
  
  NSData *fileData = [doc XMLData];
  KPKFileKey *fileKey = [[KPKFileKey alloc] initWithKeyFileData:fileData error:&error];
  XCTAssertNotNil(fileKey);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, KPKErrorKdbxKeyVersionElementMissing);
}

- (void)testXmlKeyfileLoadingUnsupportedVersion {
  NSString *file = @"<KeyFile><Meta><Version>1.5</Version></Meta><Key><Data>NODATA</Data></Key></KeyFile>";
  NSError *error;
  DDXMLDocument *doc = [[DDXMLDocument alloc] initWithXMLString:file options:0 error:&error];
  
  XCTAssertNil(error);
  XCTAssertNotNil(doc);
  
  NSData *fileData = [doc XMLData];
  KPKFileKey *fileKey = [[KPKFileKey alloc] initWithKeyFileData:fileData error:&error];
  XCTAssertNotNil(fileKey);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, KPKErrorKdbxKeyUnsupportedVersion);
}

- (void)testXmlv2KeyfileMissingHash {
  NSString *file = @"<KeyFile><Meta><Version>2.0</Version></Meta><Key><Data>NODATA</Data></Key></KeyFile>";
  NSError *error;
  DDXMLDocument *doc = [[DDXMLDocument alloc] initWithXMLString:file options:0 error:&error];
  
  XCTAssertNil(error);
  XCTAssertNotNil(doc);
  
  NSData *fileData = [doc XMLData];
  KPKFileKey *fileKey = [[KPKFileKey alloc] initWithKeyFileData:fileData error:&error];
  XCTAssertNotNil(fileKey);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, KPKErrorKdbxKeyHashAttributeMissing);
}

- (void)testXmlv2KeyfileWrongHashSize {
  NSString *file = @"<KeyFile><Meta><Version>2.0</Version></Meta><Key><Data Hash=\"FF\">NODATA</Data></Key></KeyFile>";
  NSError *error;
  DDXMLDocument *doc = [[DDXMLDocument alloc] initWithXMLString:file options:0 error:&error];
  
  XCTAssertNil(error);
  XCTAssertNotNil(doc);
  
  NSData *fileData = [doc XMLData];
  KPKFileKey *fileKey = [[KPKFileKey alloc] initWithKeyFileData:fileData error:&error];
  XCTAssertNotNil(fileKey);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, KPKErrorKdbxKeyHashAttributeWrongSize);
}

- (void)testXmlv2KeyfileCorruptedHashOrData {
  NSString *file = @"<KeyFile><Meta><Version>2.0</Version></Meta><Key><Data Hash=\"00000000\">0123456789abcdef</Data></Key></KeyFile>";
  NSError *error;
  DDXMLDocument *doc = [[DDXMLDocument alloc] initWithXMLString:file options:0 error:&error];
  
  XCTAssertNil(error);
  XCTAssertNotNil(doc);
  
  NSData *fileData = [doc XMLData];
  KPKFileKey *fileKey = [[KPKFileKey alloc] initWithKeyFileData:fileData error:&error];
  XCTAssertNotNil(fileKey);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, KPKErrorKdbxKeyDataCorrupted);
}

- (void)testValidXmlv2Keyfile {
  NSString *file = @"<KeyFile><Meta><Version>2.0</Version></Meta><Key><Data Hash=\"55c53f5d\">0123456789abcdef</Data></Key></KeyFile>";
  NSError *error;
  DDXMLDocument *doc = [[DDXMLDocument alloc] initWithXMLString:file options:0 error:&error];
  
  XCTAssertNil(error);
  XCTAssertNotNil(doc);
  
  NSData *fileData = [doc XMLData];
  KPKFileKey *fileKey = [[KPKFileKey alloc] initWithKeyFileData:fileData error:&error];
  XCTAssertNotNil(fileKey);
  XCTAssertNil(error);
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
