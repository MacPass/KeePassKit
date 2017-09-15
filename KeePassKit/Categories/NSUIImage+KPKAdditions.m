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
#ifdef KPK_MAC
  if(!self.isValid) {
    return nil;
  }
  
  NSImageRep *bestRep = nil;
  
  for(NSImageRep *imageRep in self.representations) {
    if(imageRep.pixelsWide > bestRep.pixelsWide || imageRep.pixelsHigh > bestRep.pixelsHigh) {
      bestRep = imageRep;
    }
  }
  
  if(![bestRep isKindOfClass:[NSBitmapImageRep class]]) {
    NSSize renderSize = NSMakeSize(256, 256);
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
  return [(NSBitmapImageRep *)bestRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
#else
  NSAssert(NO, @"Property not implemented on this plattform!");
  return nil; // TODO: Add UIKit compatible getter
#endif
}

@end
