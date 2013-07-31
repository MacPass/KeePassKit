//
//  KPKXmlHeaderWriter.m
//  KeePassKit
//
//  Created by Michael Starke on 31.07.13.
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

#import "KPKXmlHeaderWriter.h"
#import "KPKTree.h"
#import "KPKDataStreamWriter.h"
#import "KPKHeaderFields.h"
#import "KPKFormat.h"

#import "NSData+CommonCrypto.h"
#import "NSUUID+KeePassKit.h"

@interface KPKXmlHeaderWriter () {
  KPKDataStreamWriter *_writer;
}
@end;

@implementation KPKXmlHeaderWriter

- (id)initWithTree:(KPKTree *)tree {
  return nil;
}

- (NSData *)headerHash {
  return [[_writer data] SHA256Hash];
}

- (void)writeHeaderData:(NSMutableData *)data {
  _writer = [[KPKDataStreamWriter alloc] initWithData:data];

  /* Version and Signature */
  [_writer write4Bytes:CFSwapInt32HostToLittle(KPKVersion2Signature1)];
  [_writer write4Bytes:CFSwapInt32HostToLittle(KPKVersion2Signature2)];
  [_writer write4Bytes:CFSwapInt32HostToLittle(KPKFileVersion2)];
  
  uuid_t uuidBytes;
  [[NSUUID AESUUID] getUUIDBytes:uuidBytes];
  [self _writerHeaderField:KPKHeaderKeyCipherId data:uuidBytes length:16];
  /*
   i32 = CFSwapInt32HostToLittle(tree.compressionAlgorithm);
   [self writeHeaderField:outputStream headerId:HEADER_COMPRESSION data:&i32 length:4];
   
   [self writeHeaderField:outputStream headerId:HEADER_MASTERSEED data:masterSeed.bytes length:masterSeed.length];
   
   [self writeHeaderField:outputStream headerId:HEADER_TRANSFORMSEED data:transformSeed.bytes length:transformSeed.length];
   
   i64 = CFSwapInt64HostToLittle(tree.rounds);
   [self writeHeaderField:outputStream headerId:HEADER_TRANSFORMROUNDS data:&i64 length:8];
   
   [self writeHeaderField:outputStream headerId:HEADER_ENCRYPTIONIV data:encryptionIv.bytes length:encryptionIv.length];
   
   [self writeHeaderField:outputStream headerId:HEADER_PROTECTEDKEY data:protectedStreamKey.bytes length:protectedStreamKey.length];
   
   [self writeHeaderField:outputStream headerId:HEADER_STARTBYTES data:streamStartBytes.bytes length:streamStartBytes.length];
   */
  uint32 randomStreamId = CFSwapInt32HostToLittle(KPKRandomStreamSalsa20);
  [self _writerHeaderField:KPKHeaderKeyRandomStreamId data:&randomStreamId length:4];
  
  uint8 endBuffer[] = { NSCarriageReturnCharacter, NSNewlineCharacter, NSCarriageReturnCharacter, NSNewlineCharacter };
  [self _writerHeaderField:KPKHeaderKeyEndOfHeader data:endBuffer length:4];
  
}

- (void)_writerHeaderField:(KPKHeaderKey)key data:(void *)buffer length:(NSUInteger)length {
}

@end
