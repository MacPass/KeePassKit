//
//  KPKDataStreamWriter.h
//  KeePassKit
//
//  Created by Michael Starke on 29.07.13.
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

#import <Foundation/Foundation.h>

@interface KPKDataStreamWriter : NSObject

+ (instancetype)streamWriterWithData:(NSMutableData *)data;
+ (instancetype)streamWriter;

- (instancetype)init;
- (instancetype)initWithData:(NSMutableData *)data;

- (void)writeData:(NSData *)data;
- (void)writeStringAsNullTerminatedCString:(NSString *)string encoding:(NSStringEncoding)encoding;
- (void)writeStringData:(NSString *)string encoding:(NSStringEncoding)encoding;
- (void)writeBytes:(const void *)buffer length:(NSUInteger)lenght;
- (void)writeByte:(uint8_t)byte;
- (void)write2Bytes:(uint16_t)bytes;
- (void)write4Bytes:(uint32_t)bytes;
- (void)write8Bytes:(uint64_t)bytes;
- (void)writeInteger:(NSUInteger)integer;

@property (nonatomic, readonly, copy) NSData *data;
@property (nonatomic, readonly, copy) NSData *writtenData;
@property (nonatomic, readonly) NSUInteger location;

@end
