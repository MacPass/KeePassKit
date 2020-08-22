//
//  KPKTestCompositeKeyCoding.m
//  KeePassKitTests macOS
//
//  Created by Julius Zint on 22.08.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <KeePassKit/KeePassKit.h>

@interface KPKTestCompositeKeyCoding : XCTestCase

@end

@implementation KPKTestCompositeKeyCoding

- (void)setUp {
}

- (void)tearDown {
}

- (void)testCodingAndDecoding {
    NSBundle *myBundle = [NSBundle bundleForClass:self.class];
    NSURL *keyUrl = [myBundle URLForResource:@"Kdb1HexKey" withExtension:@"key"];
    XCTAssertNotNil(keyUrl);
    NSError *error;
    NSData *keyFileData = [NSData dataWithContentsOfURL:keyUrl options:0 error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(keyFileData);
    KPKCompositeKey *compositeKey = [[KPKCompositeKey alloc] initWithPassword:@"secret" keyFileData:keyFileData];
    XCTAssertNotNil(compositeKey);
    
    NSData* archivedData = [NSKeyedArchiver archivedDataWithRootObject:compositeKey];
    XCTAssertNotNil(archivedData);
    KPKCompositeKey* decodedCompositeKey = [NSKeyedUnarchiver unarchiveObjectWithData:archivedData];
    XCTAssertNotNil(decodedCompositeKey);
    bool equals = [decodedCompositeKey testPassword:@"secret" keyFileData:keyFileData forVersion:KPKDatabaseFormatKdbx];
    XCTAssertTrue(equals);
}

@end
