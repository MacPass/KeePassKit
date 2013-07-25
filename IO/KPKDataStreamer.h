//
//  KPKDataStreamer.h
//  MacPass
//
//  Created by Michael Starke on 24.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KPKDataStreamer : NSObject

- (id)initWithData:(NSData *)data;

- (NSData *)dataWithRange:(NSRange)range;
- (NSData *)dataWithLength:(NSUInteger)length;
- (void)readBytes:(void *)buffer length:(NSUInteger)length;
- (uint8)readByte;
- (uint16)read2Bytes;
- (uint32)read4Bytes;
- (NSUInteger)integer;

- (void)skipBytes:(NSUInteger)numberOfBytes;
- (BOOL)endOfData;
- (void)reset;

@end
