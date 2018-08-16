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
#if KPK_MAC
  _image = [myBundle imageForResource:@"image.png"];
  _imageData = _image.kpk_pngData;
#else
  _image = [NSUIImage imageNamed:@"image.png" inBundle:myBundle compatibleWithTraitCollection:nil];
  _imageData = UIImagePNGRepresentation(_image);
#endif
}

- (void)tearDown {
  _image = nil;
  _imageData = nil;
}

- (void)testLoading {
  KPKIcon *icon = [[KPKIcon alloc] initWithImageAtURL:[self urlForImageResource:@"image.png"]];
  XCTAssertNotNil(icon, @"Icon should have been loaded");
  
#if KPK_MAC
  NSImageRep *imageRep = icon.image.representations.lastObject;
  XCTAssertNotNil(imageRep, @"One image rep should be there");
  XCTAssertTrue([imageRep isKindOfClass:NSBitmapImageRep.class], @"Representation should be bitmap");

  NSData *pngData = icon.image.kpk_pngData;
#else
  NSData *pngData = UIImagePNGRepresentation(icon.image);
#endif
  XCTAssertEqualObjects(pngData, _imageData, @"Image and PNG data shoudl be identical");
}

- (void)testPDFLoading {
  // FIXME: Load pdfs on UIKit!!!
#if KPK_MAC
  KPKIcon *icon = [[KPKIcon alloc] initWithImageAtURL:[self urlForImageResource:@"test.pdf"]];
  XCTAssertEqual(icon.image.representations.count,1);
  NSData *pngData = icon.image.kpk_pngData;
  XCTAssertNotNil(pngData);
  
  icon = [[KPKIcon alloc] initWithImageAtURL:[self urlForImageResource:@"aspect.pdf"]];
  XCTAssertEqual(icon.image.representations.count,1);
  pngData = icon.image.kpk_pngData;
  XCTAssertNotNil(pngData);
#endif
}

- (void)testIcnsLoading {
  /* only macOS hast native support for ICNS files */
#if KPK_MAC
  KPKIcon *icon = [[KPKIcon alloc] initWithImageAtURL:[self urlForImageResource:@"test.icns"]];
  XCTAssertEqual(icon.image.representations.count,10);
  XCTAssertNotNil(icon.image);
  XCTAssertNotNil(icon.image.kpk_pngData);
#endif
}

- (void)testIcoLoading {
  KPKIcon *icon = [[KPKIcon alloc] initWithImageAtURL:[self urlForImageResource:@"test.ico"]];
#if KPK_MAC
  XCTAssertEqual(icon.image.representations.count,5);
  XCTAssertNotNil(icon.image);
  XCTAssertNotNil(icon.image.kpk_pngData);
#else
  XCTAssertNotNil(icon.image);
  XCTAssertNotNil(icon.image.kpk_pngData);
#endif
}

- (NSURL *)urlForImageResource:(NSString *)imageName {
  NSBundle *myBundle = [NSBundle bundleForClass:self.class];
  NSString *file = imageName.lastPathComponent;
  NSString *extension = file.lastPathComponent.pathExtension;
  NSString *base = [file substringToIndex:(file.length - extension.length - 1)];
  return [myBundle URLForResource:base withExtension:extension];
}

@end

