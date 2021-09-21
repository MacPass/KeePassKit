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
  if(!self.isValid) {
    return nil;
  }
  
  NSMutableData *imageData = [[NSMutableData alloc] init];
  
  CGImageRef imageRef = [self CGImageForProposedRect:nil context:nil hints:nil];
  CGImageDestinationRef imageDestinationRef = CGImageDestinationCreateWithData((CFMutableDataRef)imageData, (CFStringRef)kUTTypePNG, 1, NULL);
  CGImageDestinationAddImage(imageDestinationRef, imageRef, NULL);
  if(!CGImageDestinationFinalize(imageDestinationRef)) {
    NSLog(@"Error while trying to store PNG image files");
    CFRelease(imageDestinationRef);
    return nil;
  }
  CFRelease(imageDestinationRef);
  return [imageData copy];
#else
  /* test for bitmap content, if so, just use simple API to generate PNG */
  CGImageRef cgImageRef = self.CGImage;
  if(cgImageRef) {
    return UIImagePNGRepresentation(self);
  }
  return nil;
  /* TODO: no bitmap data is present, we need to render it first */
#endif
}

@end
