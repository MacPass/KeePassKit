//
//  NSColor+KeePassKit.m
//  MacPass
//
//  Created by Michael Starke on 05.08.13.
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

#import "NSUIColor+KPKAdditions.h"
#import "NSString+KPKHexdata.h"

@implementation NSUIColor (KPKAdditions)

+ (NSUIColor *)kpk_colorWithHexString:(NSString *)hex {
  if([hex hasPrefix:@"#"]) {
    hex = [hex substringFromIndex:1];
  }
  NSData *hexData = hex.kpk_dataFromHexString;
  return [self kpk_colorWithData:hexData];
}

+ (NSUIColor *)kpk_colorWithData:(NSData *)data {
  if(data.length != 3 && data.length != 4) {
    return nil; // Unsupported data format
  }
  uint8_t red,green,blue;
  [data getBytes:&red range:NSMakeRange(0, 1)];
  [data getBytes:&green range:NSMakeRange(1, 1)];
  [data getBytes:&blue range:NSMakeRange(2, 1)];
  
  if(red > 255 || green > 255 || blue > 255) {
    return nil;
  }

#if KPK_MAC
  return [NSUIColor colorWithCalibratedRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1];
#else
  return [NSUIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1];
#endif
}

+ (NSString *)kpk_hexStringFromColor:(NSUIColor *)color {
  return [color kpk_hexString];
}

- (NSString *)kpk_hexString {
#if KPK_MAC
  NSUIColor *rgbColor = [self colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]];
  if(!rgbColor) {
    return nil;
  }
  return [NSString stringWithFormat:@"#%02X%02X%02X",
          (int)(rgbColor.redComponent * 255),
          (int)(rgbColor.greenComponent * 255),
          (int)(rgbColor.blueComponent * 255)];
#else
  CGFloat red, green, blue;
  [self getRed:&red green:&green blue:&blue alpha:NULL];
  return [NSString stringWithFormat:@"#%02X%02X%02X",
          (int)(red * 255),
          (int)(green * 255),
          (int)(blue * 255)];
#endif
}

- (NSData *)kpk_colorData {
#if KPK_MAC
  NSUIColor *rgbColor = [self colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]];
  if(!rgbColor) {
    return nil;
  }
  uint8_t color[4] = { 0 };
  color[0] = (uint8_t)rgbColor.redComponent*255;
  color[1] = (uint8_t)rgbColor.greenComponent*255;
  color[2] = (uint8_t)rgbColor.blueComponent*255;
#else
  CGFloat red, green, blue;
  [self getRed:&red green:&green blue:&blue alpha:NULL];
  uint8_t color[4] = { 0 };
  color[0] = (uint8_t)red*255;
  color[1] = (uint8_t)green*255;
  color[2] = (uint8_t)blue*255;
#endif
  return [NSData dataWithBytes:&color length:4];
}

@end
