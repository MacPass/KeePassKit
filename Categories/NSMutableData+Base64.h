//
//  NSMutableData+Base64.h
//  MacPass
//
//  Created by Michael Starke on 25.06.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//
//  Based on the answer
//  http://stackoverflow.com/questions/11386876/how-to-encode-and-decode-files-as-base64-in-cocoa-objective-c
//  by user http://stackoverflow.com/users/200321/denis2342
//

#import <Foundation/Foundation.h>

/**
 *	Support for Base64 Encoding and Decoding of mutable data objects
 */
@interface NSMutableData (Base64)

/**
 *	Encodes the profieded data as Base64
 *	@param	inputData	data to be encoded
 *	@return	data encoded with base64 encoding
 */
+ (NSMutableData*)mutableDataWithBase64EncodedData:(NSData*)inputData;

/**
 *	Decodes the given base64 encoded data
 *	@param	inputData	base64 encoded data to decode
 *	@return	decoded data
 */
+ (NSMutableData*)mutableDataWithBase64DecodedData:(NSData*)inputData;

/**
 *	Encoded the Data in place with base64 encoding
 */
- (void)encodeBase64;

/**
 *	Decodes the base64 encoded data in place
 */
- (void)decodeBase64;

/**
 *	Extracts the data from an NSString object representing the base64 encoding of data
 *	@param	string	the string that represents the base64 encoded data.
 *	@param	encoding	the encoding to use for the string
 *	@return	base64 encoded data.
 */
+ (NSData *)dataFromBase64EncodedString:(NSString *)string encoding:(NSStringEncoding)encoding;

@end
