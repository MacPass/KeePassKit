//
//  KPKTestEmptyString.m
//  KeePassKit
//
//  Created by Michael Starke on 30/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit.h"

@interface KPKTestEmptyString : XCTestCase

@end

@implementation KPKTestEmptyString

- (void)testEmptryStrings {
  NSString *nilString = nil;
  XCTAssertFalse([nilString kpk_isNotEmpty]);
  XCTAssertFalse(@"".kpk_isNotEmpty);
  XCTAssertTrue(@"Empty".kpk_isNotEmpty);
}
@end
