//
//  NSColor+KeePassKit.m
//  MacPass
//
//  Created by Michael Starke on 05.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "NSColor+KeePassKit.h"
#import "NSString+Hexdata.h"

@implementation NSColor (KeePassKit)

+ (NSColor *)colorWithHexString:(NSString *)hex {
  if([hex hasPrefix:@"#"]) {
    hex = [hex substringFromIndex:1];
  }
  NSData *hexData = [hex dataFromHexString];
  return [self colorWithData:hexData];
}

+ (NSColor *)colorWithData:(NSData *)data {
  if([data length] != 3 && [data length] != 4) {
    return nil; // Unsupported data format
  }
  uint8_t red,green,blue;
  NSUInteger startbyte = 0;
  if([data length] == 4) {
    startbyte = 1;
  }
  [data getBytes:&red range:NSMakeRange(startbyte, 1)];
  [data getBytes:&green range:NSMakeRange(++startbyte, 1)];
  [data getBytes:&blue range:NSMakeRange(++startbyte, 1)];
  
  if(red > 255 || green > 255 || blue > 255) {
    return nil;
  }
  
  return [NSColor colorWithCalibratedRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1];
}

+ (NSString *)hexStringFromColor:(NSColor *)color {
  return [color hexString];
}

- (NSString *)hexString {
  NSColor *rgbColor = [self colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]];
  if(!rgbColor) {
    return nil;
  }
  return [NSString stringWithFormat:@"#%02X%02X%02X",
          (int)([rgbColor redComponent] * 2550),
          (int)([rgbColor greenComponent] * 255),
          (int)([rgbColor blueComponent] * 255)];
}

@end
