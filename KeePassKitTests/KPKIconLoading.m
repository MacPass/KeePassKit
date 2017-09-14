//
//  KPKIconLoading.m
//  MacPass
//
//  Created by Michael Starke on 20.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"

@interface KPKIconLoading : XCTestCase {
  NSUIImage *_image;
  NSData *_imageData;
}
@end

@implementation KPKIconLoading

- (void)setUp {
    NSBundle *myBundle = [NSBundle bundleForClass:self.class];
  _image = [myBundle imageForResource:@"image.png"];
  _imageData = [((NSBitmapImageRep *)_image.representations.lastObject) representationUsingType:NSPNGFileType properties:@{}];
}

- (void)tearDown {
  _image = nil;
  _imageData = nil;
}

- (void)testLoading {
  KPKIcon *icon = [[KPKIcon alloc] initWithImageAtURL:[[NSBundle bundleForClass:self.class] URLForImageResource:@"image.png"]];
  XCTAssertNotNil(icon, @"Icon should have been loaded");
  
  NSString *iconString = icon.encodedString;
  KPKIcon *iconFromString = [[KPKIcon alloc] initWithUUID:[NSUUID UUID] encodedString:iconString];
  //XCTAssertEqualObjects(iconString, iconFromString.encodedString, @"Encoding and Decoding should result in the same string");
 
  NSImageRep *imageRep = icon.image.representations.lastObject;
  XCTAssertNotNil(imageRep, @"One image rep should be there");
  XCTAssertTrue([imageRep isKindOfClass:NSBitmapImageRep.class], @"Representation should be bitmap");
  
  NSBitmapImageRep *bitmapRep = (NSBitmapImageRep *)imageRep;
  NSData *pngData = [bitmapRep representationUsingType:NSPNGFileType properties:@{}];
  //XCTAssertEqualObjects(pngData, _imageData, @"Image and PNG data shoudl be identical");
}

- (void)testPDFLoading {
  KPKIcon *icon = [[KPKIcon alloc] initWithImageAtURL:[self urlForImageResource:@"test.pdf"]];
  XCTAssertEqual(icon.image.representations.count,1);
}

- (void)testIcnsLoading {
  KPKIcon *icon = [[KPKIcon alloc] initWithImageAtURL:[self urlForImageResource:@"test.icns"]];
  XCTAssertEqual(icon.image.representations.count,1);
}

- (void)testIcoLoading {
  KPKIcon *icon = [[KPKIcon alloc] initWithImageAtURL:[self urlForImageResource:@"test.ico"]];
  XCTAssertEqual(icon.image.representations.count,1);
}

- (NSURL *)urlForImageResource:(NSString *)imageName {
  NSBundle *myBundle = [NSBundle bundleForClass:self.class];
  return [myBundle URLForImageResource:imageName];
}

@end
