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

+ (BOOL)supportsSecureCoding {
  return YES;
}

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

- (id)initWithData:(NSData *)data {
  self = [self init];
  if(self) {
    self.image =[[NSImage alloc] initWithData:data];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [[KPKIcon alloc] init];
  if(self) {
    _image = [aDecoder decodeObjectOfClass:[NSImage class] forKey:@"image"];
    _uuid = [aDecoder decodeObjectOfClass:[NSUUID class] forKey:@"uuid"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  if([aCoder isKindOfClass:[NSKeyedArchiver class]]) {
    [aCoder encodeObject:self.image forKey:@"image"];
    [aCoder encodeObject:self.uuid forKey:@"uuid"];
  }
}

- (id)copyWithZone:(NSZone *)zone {
  KPKIcon *copy = [[KPKIcon alloc] init];
  copy.image = [self.image copyWithZone:zone];
  copy.uuid = [self.uuid copyWithZone:zone];
  return copy;
}

- (BOOL)isEqual:(id)object {
  if([object isKindOfClass:[KPKIcon class]]) {
    return [self isEqualToIcon:object];
  }
  return NO;
}

- (BOOL)isEqualToIcon:(KPKIcon *)icon {
  NSAssert([icon isKindOfClass:[KPKIcon class]], @"icon needs to be of class KPKIcon");
  BOOL equal = [self.uuid isEqual:icon.uuid] && [[self encodedString] isEqualToString:[icon encodedString]];
  return equal;
}

- (NSUInteger)hash {
  return([self.uuid hash] ^ [self.encodedString hash]);
}

- (NSString *)encodedString {
  NSData *data = [self pngData];
  if(data) {
    NSData *encoded = [NSMutableData mutableDataWithBase64EncodedData:data];
    return [[NSString alloc] initWithData:encoded encoding:NSUTF8StringEncoding];
  }
  else {
    /* Wrong representation */
    return nil;
  }
}

- (NSData *)pngData {
  NSImageRep *imageRep = [[self.image representations] lastObject];
  if([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
    NSBitmapImageRep *bitmapRep = (NSBitmapImageRep *)imageRep;
    return [bitmapRep representationUsingType:NSPNGFileType properties:nil];
  }
  return nil;
}

- (NSImage *)_decodeString:(NSString *)imageString {
  NSData *data = [NSMutableData mutableDataWithBase64DecodedData:[imageString dataUsingEncoding:NSUTF8StringEncoding]];
  return [[NSImage alloc] initWithData:data];
}

@end
