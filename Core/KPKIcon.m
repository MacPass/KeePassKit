//
//  KPKIcon.m
//  MacPass
//
//  Created by Michael Starke on 20.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKIcon.h"
#import "NSMutableData+Base64.h"

@implementation KPKIcon

- (id)init {
  self = [super init];
  if(self) {
    _uuid = [NSUUID UUID];
  }
  return self;
}

- (id)initWithImageAtURL:(NSURL *)imageLocation {
  self = [self init];
  if(self) {
    _image = [[NSImage alloc] initWithContentsOfURL:imageLocation];
  }
  return self;
}

- (id)initWithUUID:(NSUUID *)uuid encodedString:(NSString *)encodedString {
  self = [self init];
  if(self) {
    _uuid = uuid;
    _image = [self _decodeString:encodedString];
  }
  return self;
}

- (NSString *)encodedString {
  NSImageRep *imageRep = [[self.image representations] lastObject];
  if([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
    NSBitmapImageRep *bitmapRep = (NSBitmapImageRep *)imageRep;
    NSData *data = [bitmapRep representationUsingType:NSPNGFileType properties:nil];
    NSData *encoded = [NSMutableData mutableDataWithBase64EncodedData:data];
    return [[NSString alloc] initWithData:encoded encoding:NSUTF8StringEncoding];
  }
  else {
    /* Wrong representation */
    return nil;
  }
}

- (NSImage *)_decodeString:(NSString *)imageString {
  NSData *data = [NSMutableData mutableDataWithBase64DecodedData:[imageString dataUsingEncoding:NSUTF8StringEncoding]];
  return [[NSImage alloc] initWithData:data];
}

@end
