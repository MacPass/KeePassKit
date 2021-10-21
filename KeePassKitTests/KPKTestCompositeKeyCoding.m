//
//  KPKTestCompositeKeyCoding.m
//  KeePassKit
//
//  Created by Michael Starke on 17.09.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <KeePassKit/KeePassKit.h>

@interface KPKTestCompositeKeyCoding : XCTestCase

@end

@implementation KPKTestCompositeKeyCoding


- (void)testCodingAndDecoding {
  NSBundle *myBundle = [NSBundle bundleForClass:self.class];
  NSURL *keyUrl = [myBundle URLForResource:@"Kdb1HexKey" withExtension:@"key"];
  XCTAssertNotNil(keyUrl);
  NSError *error;
  NSData *keyFileData = [NSData dataWithContentsOfURL:keyUrl options:0 error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(keyFileData);
  KPKPasswordKey *passwordKey = [[KPKPasswordKey alloc] initWithPassword:@"secret"];
  KPKFileKey *fileKey = [[KPKFileKey alloc] initWithKeyFileData:keyFileData];
  KPKCompositeKey *compositeKey = [[KPKCompositeKey alloc] initWithKeys:@[passwordKey, fileKey]];
  XCTAssertNotNil(compositeKey);
    
  NSData* archivedData = [NSKeyedArchiver archivedDataWithRootObject:compositeKey requiringSecureCoding:YES error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(archivedData);
  KPKCompositeKey* decodedCompositeKey = [NSKeyedUnarchiver unarchivedObjectOfClass:KPKCompositeKey.class fromData:archivedData error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(decodedCompositeKey);
  XCTAssertTrue([decodedCompositeKey isEqualToKey:compositeKey]);
}
@end
