//
//  KPKTestHexColor.m
//  MacPass
//
//  Created by Michael Starke on 05.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"
#import "NSString+KPKHexdata.h"

@interface KPKTestHexColor : XCTestCase

@end

@implementation KPKTestHexColor

- (void)testHexColorFormat {
  NSArray<NSString *> *hexStrings = @[ @"000000", @"abcabcxx", @"9999x0", @"ABCDEFGH" ];
  BOOL results[] = { YES, NO, NO, NO };
  for(NSUInteger index = 0; index < hexStrings.count; index++) {
    if(results[index]) {
      XCTAssertTrue(hexStrings[index].kpk_isValidHexString, @"Is valid hex string!");
    }
    else {
      XCTAssertFalse(hexStrings[index].kpk_isValidHexString, @"Is invalid hex string!");
    }
  }
}

#if KPK_MAC

- (void)testHexToColor {
  NSString *redHex = @"ff000000";
  NSString *greeHex = @"00FF0000";
  NSString *blueHex = @"0000ff00";
  
  NSColor *red = [NSColor kpk_colorWithHexString:redHex];
  NSColor *green = [NSColor kpk_colorWithHexString:greeHex];
  NSColor *blue = [NSColor kpk_colorWithHexString:blueHex];
  
  XCTAssertEqual(red.redComponent, 1.0, @"Red color should have 100%% red");
  XCTAssertEqual(red.blueComponent, 0.0, @"Red color should have 0%% blue");
  XCTAssertEqual(red.greenComponent, 0.0, @"Red color should have 0%% green");
  
  XCTAssertEqual(green.redComponent, 0.0, @"Green color should have 0%% red");
  XCTAssertEqual(green.greenComponent, 1.0, @"Green color should have 100%% green");
  XCTAssertEqual(green.blueComponent, 0.0, @"Green color should have 0%% blue");
  
  XCTAssertEqual(blue.redComponent, 0.0, @"Blue color should have 0%% red");
  XCTAssertEqual(blue.greenComponent, 0.0, @"Blue color should have 0%% green");
  XCTAssertEqual(blue.blueComponent, 1.0, @"Blue color should have 100%% blue");
}

- (void)testColorRefReading {
  uint32_t colorBytes = 0x000000FF;
  NSData *colorData = [NSData dataWithBytesNoCopy:&colorBytes length:3 freeWhenDone:NO];
  NSColor *color = [NSColor kpk_colorWithData:colorData];
  XCTAssertEqual([color redComponent], 1.0, @"Red 100%%");
  XCTAssertEqual([color greenComponent], 0.0, @"Green 0%%");
  XCTAssertEqual([color blueComponent], 0.0, @"Blue 100%%");
}

- (void)testColorRefWriting {
  uint32_t colorBytes = 0x000000FF;
  NSData *colorData = [NSData dataWithBytesNoCopy:&colorBytes length:4 freeWhenDone:NO];
  NSColor *color = [NSColor kpk_colorWithData:colorData];
  XCTAssertEqualObjects(colorData, color.kpk_colorData, @"Conversion should result in same data");
}

#endif

@end

