//
//  NSImage+KPKAdditions.m
//  KeePassKit
//
//  Created by Michael Starke on 14.09.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "NSImage+KPKAdditions.h"

@implementation NSImage (KPKAdditions)

+ (NSImage *)resizedImage:(NSImage *)sourceImage toPixelDimensions:(NSSize)newSize {
  if(!sourceImage.isValid) {
    return nil;
  }
  
  NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                  pixelsWide:newSize.width
                                                                  pixelsHigh:newSize.height
                                                               bitsPerSample:8
                                                             samplesPerPixel:4
                                                                    hasAlpha:YES
                                                                    isPlanar:NO
                                                              colorSpaceName:NSCalibratedRGBColorSpace
                                                                 bytesPerRow:0
                                                                bitsPerPixel:0];
  rep.size = newSize;
  
  NSImageRep *fittingRep = [sourceImage bestRepresentationForRect:NSMakeRect(0, 0, newSize.width, newSize.height) context:nil hints:nil];
  NSSize sourceSize = NSMakeSize(fittingRep.pixelsWide, fittingRep.pixelsHigh);
  
  if(sourceSize.height <= newSize.height && sourceSize.width <= newSize.width) {
    for(NSImageRep *rep in sourceImage.representations.reverseObjectEnumerator) {
      if(rep != fittingRep) {
        [sourceImage removeRepresentation:rep];
      }
    }
    NSAssert(sourceImage.representations.count == 1, @"Resizing should leave only one representation!");
    return sourceImage; // image is exactly the size we want it to be.
  }
  
  [NSGraphicsContext saveGraphicsState];
  [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:rep]];
  [sourceImage drawInRect:NSMakeRect(0, 0, newSize.width, newSize.height) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
  [NSGraphicsContext restoreGraphicsState];
  
  NSImage *newImage = [[NSImage alloc] initWithSize:newSize];
  [newImage addRepresentation:rep];
  return newImage;
}

@end
