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

@implementation KPKIcon

/* Prevent autosynthesizeis on derrived properties */
@dynamic pngData;
@dynamic encodedString;

+ (BOOL)supportsSecureCoding {
  return YES;
}

#pragma mark Lifecycle

- (instancetype)init {
  self = [super init];
  if(self) {
    _uuid = [NSUUID UUID];
  }
  return self;
}

- (instancetype)initWithImageAtURL:(NSURL *)imageLocation {
  self = [self init];
  if(self) {
    _image = [[NSUIImage alloc] initWithData:[NSData dataWithContentsOfURL:imageLocation]];    /* convert the Image to be in our PNG representation */
    _image = [[NSUIImage alloc] initWithData:self.pngData];
  }
  return self;
}

- (instancetype)initWithUUID:(NSUUID *)uuid encodedString:(NSString *)encodedString {
  self = [self init];
  if(self) {
    _uuid = uuid;
    _image = [self _decodeString:encodedString];
  }
  return self;
}

- (instancetype)initWithData:(NSData *)data {
  self = [self init];
  if(self) {
    self.image =[[NSUIImage alloc] initWithData:data];
  }
  return self;
}

#pragma mark NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [[KPKIcon alloc] init];
  if(self) {
    NSData *imageData = [aDecoder decodeObjectOfClass:[NSData class] forKey:NSStringFromSelector(@selector(image))];
    _image = [[NSUIImage alloc] initWithData:imageData];
    _uuid = [aDecoder decodeObjectOfClass:[NSUUID class] forKey:NSStringFromSelector(@selector(uuid))];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  if([aCoder isKindOfClass:[NSKeyedArchiver class]]) {
    [aCoder encodeObject:self.pngData forKey:NSStringFromSelector(@selector(image))];
    [aCoder encodeObject:self.uuid forKey:NSStringFromSelector(@selector(uuid))];
  }
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
  KPKIcon *copy = [[KPKIcon alloc] init];
#if KPK_MAC
  copy.image = [self.image copyWithZone:zone];
#else
  copy.image = [self.image copy];
#endif
  copy.uuid = [self.uuid copyWithZone:zone];
  return copy;
}

#pragma mark Equality

- (BOOL)isEqual:(id)object {
  if([object isKindOfClass:[KPKIcon class]]) {
    return [self isEqualToIcon:object];
  }
  return NO;
}

- (BOOL)isEqualToIcon:(KPKIcon *)icon {
  if(self == icon) {
    return YES; // Pointers match, should be the same object
  }
  NSAssert([icon isKindOfClass:[KPKIcon class]], @"icon needs to be of class KPKIcon");
  BOOL equal = [self.uuid isEqual:icon.uuid] && [self.encodedString isEqualToString:icon.encodedString];
  return equal;
}

#pragma mark Properties

- (NSUInteger)hash {
  return (self.uuid.hash ^ self.encodedString.hash);
}

- (NSString *)encodedString {
  return [self.pngData base64EncodedStringWithOptions:0];
}

- (NSData *)pngData {
#if KPK_MAC
  NSImageRep *imageRep = (self.image).representations.lastObject;
  if([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
    NSBitmapImageRep *bitmapRep = (NSBitmapImageRep *)imageRep;
    //[bitmapRep setProperty:NSImageGamma withValue:@1.0];
    return [bitmapRep representationUsingType:NSPNGFileType properties:@{}];
  }
#endif
  return nil;
}

#pragma mark Private

- (NSUIImage *)_decodeString:(NSString *)imageString {
  NSData *data = [[NSData alloc] initWithBase64EncodedString:imageString options:NSDataBase64DecodingIgnoreUnknownCharacters];
  return [[NSUIImage alloc] initWithData:data];
}

@end
