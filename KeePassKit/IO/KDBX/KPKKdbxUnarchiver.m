//
//  KPKKdbxTreeUnarchiver.m
//  KeePassKit
//
//  Created by Michael Starke on 25/10/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKKdbxUnarchiver.h"
#import "KPKUnarchiver_Private.h"

#import "KPKDataStreamReader.h"

#import "KPKFormat.h"
#import "KPKKdbxFormat.h"
#import "KPKErrors.h"

#import "KPKCipher.h"
#import "KPKKeyDerivation.h"

#import "KPKXmlTreeReader.h"

#import "KPKTree.h"
#import "KPKMetaData.h"
#import "KPKCompositeKey.h"

#import "NSUUID+KeePassKit.h"

#import "NSData+CommonCrypto.h"
#import "NSData+Gzip.h"
#import "NSData+HashedData.h"

#import "KPKNumber.h"

#import <CommonCrypto/CommonCrypto.h>

@interface KPKKdbxUnarchiver ()
@property (copy) NSData *masterSeed;
@property (copy) NSData *streamStartBytes;
@property (copy) NSData *protectedStreamKey;
@property (copy) NSData *encryptionIV;
@property (strong) NSMutableDictionary *customData;
@property KPKRandomStreamType randomStreamID;
@property KPKCompression compressionAlgorithm;

@property NSUInteger headerLength;
@property (nonatomic,readonly,copy) NSData *headerData;
@end

@implementation KPKKdbxUnarchiver

- (instancetype)_initWithData:(NSData *)data version:(NSUInteger)version key:(KPKCompositeKey *)key error:(NSError *__autoreleasing *)error {
  if((version & kKPKKdbxFileVersionCriticalMask) > (kKPKKdbxFileVersion4CriticalMax & kKPKKdbxFileVersionCriticalMask)) {
    KPKCreateError(error, KPKErrorUnsupportedDatabaseVersion);
    self = nil;
    return self;
  }
  self = [super _initWithData:data version:version key:key error:error];
  if(self) {
    self.mutableKeyDerivationParameters = [[KPKAESKeyDerivation defaultParameters] mutableCopy];
    if(![self _parseHeader:data error:error]) {
      self = nil;
    }
  }
  return self;
}


- (KPKTree *)tree:(NSError * _Nullable __autoreleasing *)error {
  KPKKeyDerivation *keyDerivation = [[KPKKeyDerivation alloc] initWithParameters:self.mutableKeyDerivationParameters];
  if(!keyDerivation) {
    KPKCreateError(error, KPKErrorUnsupportedKeyDerivation);
    return nil;
  }
  
  NSData *keyData = [self.key transformForFormat:KPKDatabaseFormatKdbx seed:self.masterSeed keyDerivation:keyDerivation error:error];
  if(!keyData) {
    return nil;
  }
  
  KPKCipher *cipher = [[KPKCipher alloc] initWithUUID:self.cipherUUID];
  if(!cipher) {
    KPKCreateError(error, KPKErrorUnsupportedCipher);
    return nil;
  }
  
  if(self.version < kKPKKdbxFileVersion4) {
    
    /* header | encrypted(hashed(zipped(data))) */
    
    
    NSData *encryptedData = [self.data subdataWithRange:NSMakeRange(self.headerLength, self.data.length - self.headerLength)];
    
    NSData *decryptedData = [cipher decryptData:encryptedData withKey:keyData initializationVector:self.encryptionIV error:error];
    if(!decryptedData) {
      return nil;
    }
    /* KDBX 3.1 */
    NSData *startBytes = [decryptedData subdataWithRange:NSMakeRange(0, 32)];
    if(![self.streamStartBytes isEqualToData:startBytes]) {
      KPKCreateError(error, KPKErrorPasswordAndOrKeyfileWrong);
      return nil;
    }
    
    NSData *unhashedData = [[decryptedData subdataWithRange:NSMakeRange(32, decryptedData.length - 32)] unhashedSha256Data];
    if(self.compressionAlgorithm == KPKCompressionGzip) {
      unhashedData = [unhashedData gzipInflate];
    }
    
    if(!unhashedData) {
      KPKCreateError(error, KPKErrorIntegrityCheckFailed);
      return nil;
    }
    KPKXmlTreeReader *reader = [[KPKXmlTreeReader alloc] initWithData:unhashedData randomStreamType:self.randomStreamID randomStreamKey:self.protectedStreamKey compression:self.compressionAlgorithm];
    KPKTree *tree = [reader tree:error];
    if(tree) {
      tree.metaData.keyDerivationParameters = self.mutableKeyDerivationParameters;
      tree.metaData.compressionAlgorithm = self.compressionAlgorithm;
      tree.metaData.cipherUUID = self.cipherUUID;
      
      /* todo header hash might be missing! */
      if(![self.headerData.SHA256Hash isEqualToData:reader.headerHash]) {
        KPKCreateError(error, KPKErrorKdbxHeaderHashVerificationFailed);
        return nil;
      }
    }
    return tree;
  }
  else {
    /*  header | sha256(header) | hmacsha256(header) | hashed(encrypted(zipped(data))) */
    
    NSData *exptectedHash = [self.data subdataWithRange:NSMakeRange(self.headerLength, 32)];
    NSData *actualHash = [self.data subdataWithRange:NSMakeRange(0, self.headerLength)].SHA256Hash;
    if(![exptectedHash isEqualToData:actualHash]) {
      KPKCreateError(error, KPKErrorKdbxHeaderHashVerificationFailed);
      return nil;
    }
    NSData *expectedHeaderHmac = [self.data subdataWithRange:NSMakeRange(self.headerLength + 32, 32)];
    /* compute hmac */
    
    /* unhash stream */
    
    /* decrypt stream */
    
    /* take binaries */
    
    /* build tree */
    return nil;
  }
  return nil;
}

- (NSData *)headerData {
  return [self.data subdataWithRange:NSMakeRange(0, self.headerLength)];
}

- (BOOL)_parseHeader:(NSData *)data error:(NSError **)error {
  /*
   We need to start reading after the version information,
   4bytes signature 1, 4 bytes signature , 4 bytes version
   Hence skipt first 12 bytes;
   */
  KPKDataStreamReader *dataReader = [[KPKDataStreamReader alloc] initWithData:data];
  BOOL isVersion4 = (self.version >= kKPKKdbxFileVersion4);
  [dataReader skipBytes:12];
  while(true) {
    
    uint8_t fieldType = [dataReader readByte];
    uint32_t fieldSize;
    if(isVersion4) {
      fieldSize = CFSwapInt32LittleToHost([dataReader read4Bytes]);
    }
    else {
      fieldSize = CFSwapInt16LittleToHost([dataReader read2Bytes]);
    }
    
    //NSRange readRange = NSMakeRange(location, fieldSize);
    
    switch (fieldType) {
      case KPKHeaderKeyEndOfHeader:
        [dataReader skipBytes:fieldSize];
        self.headerLength = dataReader.offset;
        return YES; // done!
        
      case KPKHeaderKeyComment:
        /* we do not use the comment */
        [dataReader skipBytes:fieldSize];
        break;
        
      case KPKHeaderKeyCipherId: {
        if(fieldSize == 16) {
          self.cipherUUID = [[NSUUID alloc] initWithData:[dataReader readDataWithLength:fieldSize]];
          KPKCipher *cipher = [[KPKCipher alloc] initWithUUID:self.cipherUUID];
          if(!cipher) {
            KPKCreateError(error, KPKErrorUnsupportedCipher);
          }
        }
        else {
          KPKCreateError(error, KPKErrorKdbxInvalidHeaderFieldSize);
          return NO;
        }
        break;
      }
      case KPKHeaderKeyMasterSeed:
        if (fieldSize != 32) {
          KPKCreateError(error, KPKErrorKdbxInvalidHeaderFieldSize);
          return NO;
        }
        self.masterSeed = [dataReader readDataWithLength:fieldSize];
        break;
      case KPKHeaderKeyTransformSeed:
        if(isVersion4) {
          KPKCreateError(error, KPKErrorKdbxInvalidHeaderFieldType);
          return NO;
        }
        if(fieldSize != 32) {
          KPKCreateError(error, KPKErrorKdbxInvalidHeaderFieldSize);
          return NO;
        }
        self.mutableKeyDerivationParameters[KPKAESSeedOption] = [dataReader readDataWithLength:fieldSize];
        break;
        
      case KPKHeaderKeyEncryptionIV: {
        KPKCipher *cipher = [[KPKCipher alloc] initWithUUID:self.cipherUUID];
        if( fieldSize != cipher.IVLength ) {
          KPKCreateError(error, KPKErrorWrongIVVectorSize);
          return NO;
        }
        self.encryptionIV = [dataReader readDataWithLength:fieldSize];
        break;
      }
      case KPKHeaderKeyProtectedKey:
        self.protectedStreamKey = [dataReader readDataWithLength:fieldSize];
        break;
        
      case KPKHeaderKeyStartBytes:
        self.streamStartBytes = [dataReader readDataWithLength:fieldSize];
        break;
        
      case KPKHeaderKeyTransformRounds:
        if(isVersion4) {
          return NO;
        }
        else {
          if(fieldSize != 8) {
            KPKCreateError(error, KPKErrorKdbxInvalidHeaderFieldSize);
            return NO;
          }
          self.mutableKeyDerivationParameters[KPKAESRoundsOption] = [KPKNumber numberWithInteger64:CFSwapInt64LittleToHost([dataReader read8Bytes])];
        }
        break;
        
      case KPKHeaderKeyCompression:
        if(fieldSize != 4) {
          KPKCreateError(error, KPKErrorKdbxInvalidHeaderFieldSize);
          return NO;
        }
        self.compressionAlgorithm = CFSwapInt32LittleToHost([dataReader read4Bytes]);
        if (self.compressionAlgorithm >= KPKCompressionCount) {
          KPKCreateError(error, KPKErrorUnsupportedCompressionAlgorithm);
          return NO;
        }
        break;
      case KPKHeaderKeyRandomStreamId:
        if(fieldSize != 4) {
          KPKCreateError(error, KPKErrorKdbxInvalidHeaderFieldSize);
          return NO;
        }
        self.randomStreamID = CFSwapInt32LittleToHost([dataReader read4Bytes]);
        if (self.randomStreamID >= KPKRandomStreamCount) {
          KPKCreateError(error,KPKErrorUnsupportedRandomStream);
          return NO;
        }
        break;
        
      case KPKHeaderKeyKdfParameters:
        NSAssert(self.version >= kKPKKdbxFileVersion4, @"File version doesn allow KDFParameter header field");
        self.mutableKeyDerivationParameters = [[NSMutableDictionary alloc] initWithVariantDictionaryData:[dataReader readDataWithLength:fieldSize]];
        if(!self.mutableKeyDerivationParameters || !self.mutableKeyDerivationParameters.isValidVariantDictionary) {
          KPKCreateError(error,KPKErrorKdbxInvalidKeyDerivationData);
          return NO;
        }
        break;
        
      case KPKHeaderKeyPublicCustomData:
        NSAssert(self.version >= kKPKKdbxFileVersion4, @"File version doesn allow PublictCustomData header field");
        self.customData = [[NSMutableDictionary alloc] initWithVariantDictionaryData:[dataReader readDataWithLength:fieldSize]];
        if(!self.customData) {
          KPKCreateError(error, KPKErrorKdbxCorrutpedPublicCustomData);
          return NO;
        }
      default:
        KPKCreateError(error,KPKErrorKdbxInvalidHeaderFieldType);
        return NO;
    }
  }
}


@end
