//
//  NSColor+KeePassKit.h
//  MacPass
//
//  Created by Michael Starke on 05.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (KeePassKit)
/**
 *	Create an NSColor object form a hexadeciaml (eg #FF0000)
 *  Representation of a String
 *	@param	hex	The String to parse
 *	@return	NSColor created form the hex string
 */
+ (NSColor *)colorWithHexString:(NSString *)hex;
/**
 *	Creates an NSCOlor object form the Data provieded
 *  data shoule be of the following format:
 *  4 bytes 0xAABBGGRR or
 *  3 bytes 0xBBGGRR
 *	@param	data	Date to parse as color
 *	@return	NSColor object with the suplied values set
 */
+ (NSColor *)colorWithData:(NSData *)data;
/**
 *	Generates a Hexstring representing the color
 *	@param	color	Color to convert to hexadecimal format
 *	@return	string with color encoded in hexadecimal format
 */
+ (NSString *)hexStringFromColor:(NSColor *)color;
/**
 *	Return a hexadecimal string representation of the color
 *	@return	hexadecimal string of the recieving NSColor object 
 */
- (NSString *)hexString;

@end
