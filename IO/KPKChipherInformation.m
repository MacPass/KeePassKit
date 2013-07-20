//
//  KPKChipherInformation.m
//  MacPass
//
//  Created by Michael Starke on 21.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKChipherInformation.h"
#import "KPKFormat.h"
#import "KPKErrors.h"
#import "KPKHeaderFields.h"
#import "NSUUID+KeePassKit.h"

@implementation KPKChipherInformation

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error{
  self = [super init];
  if(self) {
    if(![self _parseHeader:error]) {
      self = nil;
      return nil;
    }
    _data = data;
  }
  return self;
}

- (NSData *)payload {
  // return data minus header
  return nil;
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
  NSUInteger location = 16;
  uint8_t buffer[16];
  
  BOOL eoh = NO;
  
  while (!eoh) {
    uint8_t fieldType;
    uint16_t fieldSize;
    
    [_data getBytes:&fieldType range:NSMakeRange(location, 2)];
    location +=2;
    
    [_data getBytes:&fieldSize range:NSMakeRange(location, 3)];
    fieldSize = CFSwapInt16LittleToHost(fieldSize);
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
          cipherUuid = [[NSUUID alloc] initWithData:[_data subdataWithRange:readRange]];
          cipherOk = [[NSUUID AESUUID] isEqual:cipherUuid];
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
        masterSeed = [_data subdataWithRange:readRange];
        break;
      case KPKHeaderKeyTransformSeed:
        if (fieldSize != 32) {
          // FIXME: Error invalid field size
          return NO;
        }
        transformSeed = [_data subdataWithRange:readRange];
        break;
        
      case KPKHeaderKeyEncryptionIV:
        encryptionIv = [_data subdataWithRange:readRange];
        break;
        
      case KPKHeaderKeyProtectedKey:
        protectedStreamKey = [_data subdataWithRange:readRange];
        break;
      case KPKHeaderKeyStartBytes:
        streamStartBytes = [_data subdataWithRange:readRange];
        break;
        
      case KPKHeaderKeyTransformRounds:
        [_data getBytes:&rounds range:NSMakeRange(location, 8)];
        rounds = CFSwapInt64LittleToHost(rounds);
        break;
        
      case KPKHeaderKeyCompression:
        _data getBytes:&compressionAlgorithm range:NSMakeRange(location, 4)];
        compressionAlgorithm = CFSwapInt32LittleToHost(compressionAlgorithm);
        if (compressionAlgorithm >= KPKCompressionCount) {
          if(error != NULL) {
            // FIXME: Error creation
            *error = KPKCreateError(KPKErrorDatabseParsingFailed, @"", "");
          }
          return NO;
        }
        break;
      case KPKHeaderKeyRandomStreamId:
        randomStreamID = [inputStream readInt32];
        randomStreamID = CFSwapInt32LittleToHost(randomStreamID);
        if (randomStreamID >= CSR_COUNT) {
          @throw [NSException exceptionWithName:@"IOException" reason:@"Invalid CSR algorithm" userInfo:nil];
        }
        break;
        
      default:
        @throw [NSException exceptionWithName:@"InvalidHeader" reason:@"InvalidField" userInfo:nil];
    }
    
    location += fieldSize;
    //  if (![cipherUuid isEqual:[UUID getAESUUID]]) {
    //    @throw [NSException exceptionWithName:@"IOException" reason:@"Unsupported cipher" userInfo:nil];
    //  }
    
  }
}
@end
