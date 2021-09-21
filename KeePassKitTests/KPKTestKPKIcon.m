//
//  KPKTestKPKIcon.m
//  KeePassKit
//
//  Created by Michael Starke on 21.09.21.
//  Copyright © 2021 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <KeePassKit/KeePassKit.h>

@interface KPKTestKPKIcon : XCTestCase

@end

@implementation KPKTestKPKIcon

- (void)testEquality {
  
  NSData *imageData = [NSImage imageNamed:NSImageNameCaution].kpk_pngData;
  XCTAssertNotNil(imageData);
  NSUUID *iconUUID = [[NSUUID alloc] init];
  
  KPKIcon *icon = [[KPKIcon alloc] initWithUUID:iconUUID imageData:imageData];
  XCTAssertNotNil(icon);
  XCTAssertNotNil(icon.uuid);
  XCTAssertNotNil(icon.image);
  
  KPKIcon *iconCopy = [icon copy];
  XCTAssertTrue([icon isEqualToIcon:iconCopy]);
  
  icon.name = @"The icon has a new name";
  XCTAssertFalse([icon isEqualToIcon:iconCopy]);
  
  iconCopy = [icon copy];
  XCTAssertTrue([icon isEqualToIcon:iconCopy]);
}

@end
