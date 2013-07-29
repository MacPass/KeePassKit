//
//  KPKDataStreamer.h
//  MacPass
//
//  Created by Michael Starke on 24.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KPKDataStreamReader : NSObject

- (id)initWithData:(NSData *)data;

- (NSData *)dataWithLength:(NSUInteger)length;
- (NSString *)stringWithLenght:(NSUInteger)length encoding:(NSStringEncoding)encoding;
- (void)readBytes:(void *)buffer length:(NSUInteger)length;
- (uint8)readByte;
- (uint16)read2Bytes;
- (uint32)read4Bytes;
- (uint64)read8Bytes;
- (NSUInteger)integer;

- (NSUInteger)location;
- (void)skipBytes:(NSUInteger)numberOfBytes;
- (BOOL)endOfData;
- (void)reset;

@end
