//
//  NSImage+KPKAdditions.m
//  KeePassKit
//
//  Created by Michael Starke on 14.09.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "NSUIImage+KPKAdditions.h"

@implementation NSUIImage (KPKAdditions)

- (NSData *)kpk_pngData {
#if KPK_MAC
  static NSData *gammaChunkData;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    uint8_t bytes[] = {0x67, 0x41, 0x4D, 0x41};
    gammaChunkData = [NSData dataWithBytes:bytes length:4];
  });
  if(!self.isValid) {
    return nil;
  }
  
  NSImageRep *bestRep = nil;
  
  for(NSImageRep *imageRep in self.representations) {
    if(imageRep.pixelsWide > bestRep.pixelsWide || imageRep.pixelsHigh > bestRep.pixelsHigh) {
      bestRep = imageRep;
    }
  }
  
  if(![bestRep isKindOfClass:NSBitmapImageRep.class]) {
    NSSize renderSize = NSMakeSize(256, 256);
    bestRep = [self bestRepresentationForRect:NSMakeRect(0, 0, renderSize.width, renderSize.height) context:nil hints:nil];
    NSAssert(bestRep, @"No image representation present to render image!");
    if(!bestRep) {
      return nil;
    }
    CGFloat aspect = bestRep.size.width / bestRep.size.height;
    if(aspect > 1) {
      renderSize.height = (renderSize.width / aspect);
    }
    else {
      renderSize.width = (renderSize.height * aspect);
    }
    bestRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                      pixelsWide:renderSize.width
                                                      pixelsHigh:renderSize.height
                                                   bitsPerSample:8
                                                 samplesPerPixel:4
                                                        hasAlpha:YES
                                                        isPlanar:NO
                                                  colorSpaceName:NSCalibratedRGBColorSpace
                                                     bytesPerRow:0
                                                    bitsPerPixel:0];
    bestRep.size = renderSize;
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:(NSBitmapImageRep *)bestRep]];
    [self drawInRect:NSMakeRect(0, 0, renderSize.width, renderSize.height) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
  }
  NSBitmapImageRep *bitmapRep = (NSBitmapImageRep *)bestRep;
  return [bitmapRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
#else
  /* test for bitmap content, if so, just use simple API to generate PNG */
  CGImageRef cgImageRef = self.CGImage;
  if(cgImageRef) {
    return UIImagePNGRepresentation(self);
  }
  return nil;
  /* no bitmap data is present, we need to render it first */
#endif
}

@end
