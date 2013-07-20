//
//  KPKIcon.m
//  KeePassKit
//
//  Created by Michael Starke on 20.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
