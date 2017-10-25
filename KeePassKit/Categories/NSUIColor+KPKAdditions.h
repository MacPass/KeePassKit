//
//  NSColor+KeePassKit.h
//  KeePassKit
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

#import "KPKPlatformIncludes.h"
@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NSUIColor (KPKAdditions)
/**
 *	Create an NSColor object form a hexadeciaml (eg #FF0000)
 *  Representation of a String
 *	@param	hex	The String to parse
 *	@return	NSColor created form the hex string
 */
+ (nullable NSUIColor *)kpk_colorWithHexString:(NSString *)hex;
/**
 *  Creates an NSCOlor object form the Data provieded
 *  data shoule be of the following format:
 *  4 bytes 0xAABBGGRR or
 *  3 bytes 0xBBGGRR
 *  @param	data	Date to parse as color
 *  @return	NSColor object with the suplied values set
 */
+ (nullable NSUIColor *)kpk_colorWithData:(NSData *)data;
/**
 *  Generates a Hexstring representing the color
 *  @param	color	Color to convert to hexadecimal format
 *  @return	string with color encoded in hexadecimal format
 */
+ (nullable NSString *)kpk_hexStringFromColor:(NSUIColor *)color;
/**
 *  Return a hexadecimal string representation of the color
 *  @return	hexadecimal string of the recieving NSColor object
 */
@property (nonatomic, readonly, copy, nullable) NSString *kpk_hexString;
/**
 *  Returns the color represented as 4 byte data. This format is used in KDB files
 *  @return	NSData for the receiving color
 */
@property (nonatomic, readonly, copy, nullable) NSData *kpk_colorData;

@end

NS_ASSUME_NONNULL_END
