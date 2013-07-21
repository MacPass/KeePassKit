//
//  KPKChipherInformation.m
//  MacPass
//
//  Created by Michael Starke on 21.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKXmlCipherInformation.h"
#import "KPKFormat.h"
#import "KPKErrors.h"
#import "KPKHeaderFields.h"
#import "NSUUID+KeePassKit.h"

#import "NSData+Random.h"

@interface KPKXmlCipherInformation () {
  NSData *_comment;
  NSUInteger _endOfHeader;
  NSData *_data;

}

@end

@implementation KPKXmlCipherInformation

- (id)init {
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

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error{
  self = [super init];
  if(self) {
    _data = data;
    if(![self _parseHeader:error]) {
      _data = nil;
      self = nil;
      return nil;
    }
  }
  return self;
}

- (NSData *)dataWithoutHeader {
  return [_data subdataWithRange:NSMakeRange(_endOfHeader, [_data length] - _endOfHeader)];
}

- (BOOL)_parseHeader:(NSError *__autoreleasing *)error {
  KPKFormat *format = [KPKFormat sharedFormat];
  uint32_t version = [format fileVersionForData:_data];
  
  if ((version & VERSION2_CRITICAL_MASK) > (VERSION2_CRITICAL_MAX_32 & VERSION2_CRITICAL_MASK)) {
    if(error != NULL) {
      *error = KPKCreateError(KPKErrorKDBDatabaseVersionUnsupported, @"ERROR_UNSUPPORTED_KDB_DATABASER_VERION", "");
    }
    return NO;
  }
  
  /*
   We need to start reading after the version information,
   4bytes signature 1, 4 bytes signature , 4 bytes version
   Hence start at 16;
   */
  NSUInteger location = 12;
  while (true) {
    uint8_t fieldType;
    uint16_t fieldSize;
    
    [_data getBytes:&fieldType range:NSMakeRange(location, 1)];
    location ++;
    
    [_data getBytes:&fieldSize range:NSMakeRange(location, 2)];
    fieldSize = CFSwapInt16LittleToHost(fieldSize);
    location +=2;
    NSRange readRange = NSMakeRange(location, fieldSize);

    switch (fieldType) {
      case KPKHeaderKeyEndOfHeader:
        _endOfHeader = location + fieldSize;
        return YES; // Done
        
      case KPKHeaderKeyComment:
        _comment = [_data subdataWithRange:readRange];
        break;
        
      case KPKHeaderKeyCipherId: {
        BOOL cipherOk = YES;
        if(fieldSize == 16) {
          _cipherUUID = [[NSUUID alloc] initWithData:[_data subdataWithRange:readRange]];
          cipherOk = [[NSUUID AESUUID] isEqual:_cipherUUID];
        }
        else {
          cipherOk = NO;
        }
        if(!cipherOk) {
          if(error != NULL) {
            *error = KPKCreateError(KPKErrorKDBXChipherUnsupported, @"ERROR_UNSUPPORTED_KDBX_CHIPHER", "");
          }
          return NO;
        }
        break;
      }
      case KPKHeaderKeyMasterSeed:
        if (fieldSize != 32) {
          // FIXME: Error invalid field size
          return NO;
        }
        _masterSeed = [_data subdataWithRange:readRange];
        break;
      case KPKHeaderKeyTransformSeed:
        if (fieldSize != 32) {
          // FIXME: Error invalid field size
          return NO;
        }
        _transformSeed = [_data subdataWithRange:readRange];
        break;
        
      case KPKHeaderKeyEncryptionIV:
        _encryptionIV = [_data subdataWithRange:readRange];
        break;
        
      case KPKHeaderKeyProtectedKey:
        _protectedStreamKey = [_data subdataWithRange:readRange];
        break;
      case KPKHeaderKeyStartBytes:
        _streamStartBytes = [_data subdataWithRange:readRange];
        break;
        
      case KPKHeaderKeyTransformRounds:
        [_data getBytes:&_rounds range:NSMakeRange(location, 8)];
        _rounds = CFSwapInt64LittleToHost(_rounds);
        break;
        
      case KPKHeaderKeyCompression:
        [_data getBytes:&_compressionAlgorithm range:NSMakeRange(location, 4)];
        _compressionAlgorithm = CFSwapInt32LittleToHost(_compressionAlgorithm);
        if (_compressionAlgorithm >= KPKCompressionCount) {
          if(error != NULL) {
            // FIXME: Error creation
            *error = KPKCreateError(KPKErrorKDBXUnsupportedCompressionAlgorithm, @"ERROR_UNSUPPORTED_KDBX_COMPRESSION_ALGORITHM", "");
          }
          return NO;
        }
        break;
      case KPKHeaderKeyRandomStreamId:
        [_data getBytes:&_randomStreamID range:NSMakeRange(location, 4)];
        _randomStreamID = CFSwapInt32LittleToHost(_randomStreamID);
        if (_randomStreamID >= KPKRandomStreamCount) {
          if(error != NULL) {
            *error = KPKCreateError(KPKErrorKDBXUnsupportedRandomStream, @"ERROR_UNSUPPORTED_KDBX_RANDOM_STREAM", "");
          }
          return NO;
        }
        break;
        
      default:
        if(error != NULL) {
          *error = KPKCreateError(KPKErrorKDBXHeaderCorrupted, @"ERROR_HEADER_CORRUPTED", "");
        }
        return NO;
    }
    /*
     Increment the location
     */
    location += fieldSize;
  }
}

- (void)writeHeaderData:(NSMutableData *)data {
  
}

@end
