//
//  KPKTestModifiedString.m
//  KeePassKitTests macOS
//
//  Created by Michael Starke on 07.10.21.
//  Copyright © 2021 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <KeePassKit/KeePassKit.h>

@interface KPKTestModifiedString : XCTestCase

@end

@implementation KPKTestModifiedString

- (void)testCoding {
  KPKModifiedString *string = [[KPKModifiedString alloc] init];
  string.value = @"Hello";
  
  NSError *error;
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:string requiringSecureCoding:YES error:&error];
  XCTAssertNotNil(data);
  XCTAssertNil(error);
  
  KPKModifiedString *decodedString = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  
  XCTAssertNotNil(decodedString);
  XCTAssertEqualObjects(string, decodedString);
}

- (void)testCopying {
  KPKModifiedString *string = [[KPKModifiedString alloc] init];

  string.value = @"value";
  
  KPKModifiedString *copy = [string copy];
  
  XCTAssertEqualObjects(string, copy);
}

- (void)testEquality {
  NSDate *date = [NSDate date];
  
  KPKModifiedString *stringA1 = [[KPKModifiedString alloc] initWithValue:@"A" modificationDate:date];
  KPKModifiedString *stringA2 = [[KPKModifiedString alloc] initWithValue:@"A" modificationDate:date];
  KPKModifiedString *stringB = [[KPKModifiedString alloc] initWithValue:@"B" modificationDate:date];
  KPKModifiedString *stringC = [[KPKModifiedString alloc] initWithValue:@"A" modificationDate:[NSDate date]];
  
  XCTAssertEqualObjects(stringA1, stringA2);
  XCTAssertNotEqualObjects(stringA1, stringB);
  XCTAssertNotEqualObjects(stringA2, stringB);
  XCTAssertNotEqualObjects(stringA1, stringC);
  XCTAssertNotEqualObjects(stringA2, stringC);
  XCTAssertNotEqualObjects(stringB, stringC);
}

- (void)testModificationTracking {
  KPKModifiedString *ms = [[KPKModifiedString alloc] initWithValue:@"1"];
  XCTAssertNil(ms.modificationDate);
  
  NSDate *before = [NSDate date];
  ms.value = @"2";
  
  XCTAssertEqualObjects(@"2", ms.value);
  XCTAssertNotNil(ms.modificationDate);
  XCTAssertTrue(NSOrderedSame <= [ms.modificationDate compare:before]);
}

@end
