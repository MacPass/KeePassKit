//
//  NSColor+KeePassKit.h
//  MacPass
//
//  Created by Michael Starke on 05.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (KeePassKit)

+ (NSColor *)colorWithHexString:(NSString *)hex;
+ (NSColor *)colorWithData:(NSData *)data;
@end
