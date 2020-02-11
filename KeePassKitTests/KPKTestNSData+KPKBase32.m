//
//  KPKTestNSData+KPKBase32.m
//  KeePassKitTests macOS
//
//  Created by Michael Starke on 01.11.19.
//  Copyright © 2019 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit.h"
#import "KeePassKit_Private.h"

@interface KPKTestNSData_KPKBase32 : XCTestCase

@end

@implementation KPKTestNSData_KPKBase32


- (void)testExample {
  NSData *data = [[NSData alloc] initWithBase32EncodedString:@"ABCDEFGH"];
}

@end
