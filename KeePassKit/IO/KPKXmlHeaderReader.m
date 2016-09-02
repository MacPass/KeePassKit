//
//  KPKChipherInformation.m
//  KeePassKit
//
//  Created by Michael Starke on 21.07.13.
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

#import "KPKXmlHeaderReader.h"
#import "KPKFormat.h"
#import "KPKErrors.h"
#import "KPKXmlFormat.h"
#import "NSUUID+KeePassKit.h"

#import "KPKDataStreamReader.h"
#import "NSData+Random.h"
#import "NSData+CommonCrypto.h"

@interface KPKXmlHeaderReader () {
  NSData *_comment;
  NSUInteger _endOfHeader;
  NSData *_data;
  KPKDataStreamReader *_dataStreamer;
}

@end

@implementation KPKXmlHeaderReader

@dynamic headerHash;
@dynamic contentsHash;
@dynamic numberOfGroups;
@dynamic numberOfEntries;

@synthesize encryptionIV = _encryptionIV;
@synthesize masterSeed = _masterSeed;
@synthesize transformSeed = _transformSeed;
@synthesize cipherUUID = _cipherUUID;
@synthesize compressionAlgorithm = _compressionAlgorithm;
@synthesize streamStartBytes = _streamStartBytes;
@synthesize protectedStreamKey = _protectedStreamKey;
@synthesize rounds = _rounds;
@synthesize randomStreamID = _randomStreamID;

- (instancetype)init {
  self = [super init];
  if(self) {
    _masterSeed = [NSData dataWithRandomBytes:32];
    _transformSeed = [NSData dataWithRandomBytes:32];
    _encryptionIV = [NSData dataWithRandomBytes:16];
    _protectedStreamKey = [NSData dataWithRandomBytes:32];
    _streamStartBytes = [NSData dataWithRandomBytes:32];
  }
  return self;
}

- (instancetype)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error{
  self = [super init];
  if(self) {
    _data = data;
    _dataStreamer = [[KPKDataStreamReader alloc] initWithData:_data];
    if(![self _parseHeader:error]) {
      _data = nil;
      self = nil;
      return nil;
    }
  }
  return self;
}

- (NSData *)dataWithoutHeader {
  return [_data subdataWithRange:NSMakeRange(_endOfHeader, _data.length - _endOfHeader)];
}

- (BOOL)verifyHeader:(NSData *)hash {
  /* NOTE only works if header was parsed */
  NSData *myHash = [[self headerData] SHA256Hash];
  return [myHash isEqualToData:hash];
}

- (NSData *)headerData {
  if(_data.length < _endOfHeader) {
    return nil;
  }
  return [_data subdataWithRange:NSMakeRange(0, _endOfHeader)];
}

- (BOOL)_parseHeader:(NSError *__autoreleasing *)error {
  KPKFormat *format = [KPKFormat sharedFormat];
  KPKFileInfo info = [format fileInfoForData:_data];
  
  if ((info.version & kKPKXMLFileVersionCriticalMask) > (kKPKXMLFileVersion3CriticalMax & kKPKXMLFileVersionCriticalMask)) {
    KPKCreateError(error, KPKErrorUnsupportedDatabaseVersion, @"ERROR_UNSUPPORTED_DATABASER_VERSION", "");
    return NO;
  }
  
  /*
   We need to start reading after the version information,
   4bytes signature 1, 4 bytes signature , 4 bytes version
   Hence skipt first 12 bytes;
   */
  [_dataStreamer skipBytes:12];
  //NSUInteger location = 12;
  while (true) {
    uint8_t fieldType = [_dataStreamer readByte];
    uint16_t fieldSize = [_dataStreamer read2Bytes];
    fieldSize = CFSwapInt16LittleToHost(fieldSize);
  
    //NSRange readRange = NSMakeRange(location, fieldSize);

    switch (fieldType) {
      case KPKHeaderKeyEndOfHeader:
        [_dataStreamer skipBytes:fieldSize];
        _endOfHeader = _dataStreamer.location;
        return YES; // Done
        
      case KPKHeaderKeyComment:
        _comment = [_dataStreamer dataWithLength:fieldSize];
        break;
        
      case KPKHeaderKeyCipherId: {
        if(fieldSize == 16) {
          _cipherUUID = [[NSUUID alloc] initWithData:[_dataStreamer dataWithLength:fieldSize]];
        }
        else {
          KPKCreateError(error, KPKErrorXMLInvalidHeaderFieldSize, @"ERROR_INVALID_HEADER_FIELD_SIZE", "");
          return NO;
        }
        break;
      }
      case KPKHeaderKeyMasterSeed:
        if (fieldSize != 32) {
          KPKCreateError(error, KPKErrorXMLInvalidHeaderFieldSize, @"ERROR_INVALID_HEADER_FIELD_SIZE", "");
          return NO;
        }
        _masterSeed = [_dataStreamer dataWithLength:fieldSize];
        break;
      case KPKHeaderKeyTransformSeed:
        if (fieldSize != 32) {
          KPKCreateError(error, KPKErrorXMLInvalidHeaderFieldSize, @"ERROR_INVALID_HEADER_FIELD_SIZE", "");
          return NO;
        }
        _transformSeed =  [_dataStreamer dataWithLength:fieldSize];
        break;
        
      case KPKHeaderKeyEncryptionIV:
        _encryptionIV = [_dataStreamer dataWithLength:fieldSize];
        break;
        
      case KPKHeaderKeyProtectedKey:
        _protectedStreamKey = [_dataStreamer dataWithLength:fieldSize];
        break;
      case KPKHeaderKeyStartBytes:
        _streamStartBytes = [_dataStreamer dataWithLength:fieldSize];
        break;
        
      case KPKHeaderKeyTransformRounds:
        _rounds = [_dataStreamer read8Bytes];
        _rounds = CFSwapInt64LittleToHost(_rounds);
        break;
        
      case KPKHeaderKeyCompression:
        _compressionAlgorithm = [_dataStreamer read4Bytes];
        _compressionAlgorithm = CFSwapInt32LittleToHost(_compressionAlgorithm);
        if (_compressionAlgorithm >= KPKCompressionCount) {
          KPKCreateError(error, KPKErrorUnsupportedCompressionAlgorithm, @"ERROR_UNSUPPORTED_KDBX_COMPRESSION_ALGORITHM", "");
          return NO;
        }
        break;
      case KPKHeaderKeyRandomStreamId:
        _randomStreamID = [_dataStreamer read4Bytes];
        _randomStreamID = CFSwapInt32LittleToHost(_randomStreamID);
        if (_randomStreamID >= KPKRandomStreamCount) {
          KPKCreateError(error,KPKErrorUnsupportedRandomStream, @"ERROR_UNSUPPORTED_KDBX_RANDOM_STREAM", "");
          return NO;
        }
        break;
        
      default:
        KPKCreateError(error,KPKErrorXMLInvalidHeaderFieldType, @"ERROR_INVALID_HEADER_FIELD_TYPE", "");
        return NO;
    }
  }
}

@end
