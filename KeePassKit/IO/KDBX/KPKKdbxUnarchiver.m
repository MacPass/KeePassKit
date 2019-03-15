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
#import "KPKAESKeyDerivation.h"

#import "KPKArc4RandomStream.h"
#import "KPKSalsa20RandomStream.h"
#import "KPKChaCha20RandomStream.h"

#import "KPKXmlTreeReader.h"

#import "KPKTree.h"
#import "KPKMetaData.h"
#import "KPKMetaData_Private.h"
#import "KPKCompositeKey.h"
#import "KPKBinary.h"

#import "NSUUID+KPKAdditions.h"

#import "NSData+CommonCrypto.h"
#import "NSData+KPKGzip.h"
#import "NSData+KPKHashedData.h"
#import "NSData+KPKKeyComputation.h"

#import "NSDictionary+KPKVariant.h"

#import "KPKData.h"
#import "KPKNumber.h"

#import <CommonCrypto/CommonCrypto.h>

@interface KPKKdbxUnarchiver () <KPKXmlTreeReaderDelegate>
@property (copy) NSData *masterSeed;
@property (copy) NSData *streamStartBytes;
@property (copy) NSData *encryptionIV;
@property (copy) NSData *randomStreamKey;
@property KPKRandomStreamType randomStreamID;
@property KPKCompression compressionAlgorithm;

@property (strong) NSMutableDictionary *customPublicData;
@property (strong) NSMutableArray<KPKData *> *binaryData;

@property NSUInteger headerLength;
@property (nonatomic,readonly,copy) NSData *headerData;
@property (strong) KPKRandomStream *randomStream;
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

#pragma mark -
#pragma mark KPKXmlTreeReaderDelegate

- (KPKData *)reader:(KPKXmlTreeReader *)reader binaryDataForReference:(NSUInteger)reference {
  if(self.binaryData.count <= reference) {
    return nil;
  }
  return self.binaryData[reference];
}

- (KPKRandomStream *)randomStreamForReader:(KPKXmlTreeReader *)reader {
  return self.randomStream;
}

- (NSUInteger)fileVersionForReader:(KPKXmlTreeReader *)reader {
  return self.version;
}

#pragma mark -
#pragma mark Deserilization


- (KPKTree *)tree:(NSError * _Nullable __autoreleasing *)error {
  KPKKeyDerivation *keyDerivation = [[KPKKeyDerivation alloc] initWithParameters:self.mutableKeyDerivationParameters];
  if(!keyDerivation) {
    KPKCreateError(error, KPKErrorUnsupportedKeyDerivation);
    return nil;
  }
  
  KPKCipher *cipher = [[KPKCipher alloc] initWithUUID:self.cipherUUID];
  NSData *hmacKey;
  NSData *keyData = [self.key computeKeyDataForFormat:KPKDatabaseFormatKdbx
                                           masterseed:self.masterSeed
                                               cipher:cipher
                                        keyDerivation:keyDerivation
                                              hmacKey:&hmacKey
                                                error:error];
  
  if(!keyData) {
    return nil;
  }
  
  if(!cipher) {
    KPKCreateError(error, KPKErrorUnsupportedCipher);
    return nil;
  }
  NSData *xmlData;
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
    
    xmlData = [decryptedData subdataWithRange:NSMakeRange(32, decryptedData.length - 32)].kpk_unhashedSha256Data;
    if(self.compressionAlgorithm == KPKCompressionGzip) {
      xmlData = xmlData.kpk_gzipInflated;
    }
    
    if(!xmlData) {
      KPKCreateError(error, KPKErrorIntegrityCheckFailed);
      return nil;
    }
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
    NSData *headerMac = [self.headerData kpk_headerHmacWithKey:hmacKey];
    if(![headerMac isEqualToData:expectedHeaderHmac]) {
      KPKCreateError(error, KPKErrorKdbxHeaderHashVerificationFailed);
      return nil;
    }
    
    NSData *hashedData = [self.data subdataWithRange:NSMakeRange(self.headerLength + 64, self.data.length - self.headerLength - 64)];
    NSData *unhashedData = [hashedData kpk_unhashedHmacSha256DataWithKey:hmacKey error:error];
    if(!unhashedData) {
      return nil;
    }
    NSData *decryptedData = [cipher decryptData:unhashedData withKey:keyData initializationVector:self.encryptionIV error:error];
    if(self.compressionAlgorithm == KPKCompressionGzip) {
      decryptedData = decryptedData.kpk_gzipInflated;
    }
    NSUInteger xmlOffset = [self _parseInnerHeader:decryptedData error:error];
    if(xmlOffset == 0) {
      return nil;
    }
    xmlData = [decryptedData subdataWithRange:NSMakeRange(xmlOffset, decryptedData.length - xmlOffset)];
  }
  
  /* setup the random stream */
  switch(self.randomStreamID) {
    case KPKRandomStreamArc4:
      self.randomStream = [[KPKArc4RandomStream alloc] initWithKeyData:self.randomStreamKey];
      break;
      
    case KPKRandomStreamSalsa20:
      self.randomStream = [[KPKSalsa20RandomStream alloc] initWithKeyData:self.randomStreamKey];
      break;
      
    case KPKRandomStreamChaCha20:
      self.randomStream = [[KPKChaCha20RandomStream alloc] initWithKeyData:self.randomStreamKey];
      break;
      
    default:
      KPKCreateError(error, KPKErrorUnsupportedRandomStream);
      return nil;
  }
   
  KPKXmlTreeReader *reader = [[KPKXmlTreeReader alloc] initWithData:xmlData delegate:self];
  
  KPKTree *tree = [reader tree:error];
  if(tree) {
    tree.metaData.keyDerivationParameters = self.mutableKeyDerivationParameters;
    tree.metaData.compressionAlgorithm = self.compressionAlgorithm;
    tree.metaData.cipherUUID = self.cipherUUID;
    tree.metaData.mutableCustomPublicData = self.customPublicData;
    
    if(reader.headerHash && ![self.headerData.SHA256Hash isEqualToData:reader.headerHash]) {
      KPKCreateError(error, KPKErrorKdbxHeaderHashVerificationFailed);
      return nil;
    }
  }
  return tree;
}

- (NSData *)headerData {
  return [self.data subdataWithRange:NSMakeRange(0, self.headerLength)];
}

- (BOOL)_parseHeader:(NSData *)data error:(NSError * __autoreleasing *)error {
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
      case KPKHeaderKeyEndOfHeader: {
        [dataReader skipBytes:fieldSize];
        self.headerLength = dataReader.offset;
        
        /* sanity check cipher size */
        KPKCipher *cipher = [[KPKCipher alloc] initWithUUID:self.cipherUUID];
        if( self.encryptionIV.length != cipher.IVLength ) {
          KPKCreateError(error, KPKErrorWrongIVVectorSize);
          return NO;
        }
        return YES;
      }
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
        
      case KPKHeaderKeyEncryptionIV:
        self.encryptionIV = [dataReader readDataWithLength:fieldSize];
        break;
      case KPKHeaderKeyProtectedKey:
        if(isVersion4) {
          NSLog(@"Unexptected Public Header field ProtectedKey in KDBX4 public header!");
        }
        self.randomStreamKey = [dataReader readDataWithLength:fieldSize];
        break;
        
      case KPKHeaderKeyStartBytes:
        self.streamStartBytes = [dataReader readDataWithLength:fieldSize];
        break;
        
      case KPKHeaderKeyTransformRounds:
        if(isVersion4) {
          KPKCreateError(error, KPKErrorKdbxInvalidHeaderFieldType);
          return NO;
        }
        if(fieldSize != 8) {
          KPKCreateError(error, KPKErrorKdbxInvalidHeaderFieldSize);
          return NO;
        }
        self.mutableKeyDerivationParameters[KPKAESRoundsOption] = [KPKNumber numberWithUnsignedInteger64:CFSwapInt64LittleToHost([dataReader read8Bytes])];
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
        if(isVersion4) {
          NSLog(@"Unexptected Public Header filed RandomStreamID in KDBX4 public header!");
        }
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
        if(!self.mutableKeyDerivationParameters || !self.mutableKeyDerivationParameters.kpk_isValidVariantDictionary) {
          KPKCreateError(error,KPKErrorKdbxInvalidKeyDerivationData);
          return NO;
        }
        break;
        
      case KPKHeaderKeyPublicCustomData:
        NSAssert(self.version >= kKPKKdbxFileVersion4, @"File version doesn allow PublictCustomData header field");
        self.customPublicData = [[NSMutableDictionary alloc] initWithVariantDictionaryData:[dataReader readDataWithLength:fieldSize]];
        if(!self.customPublicData) {
          KPKCreateError(error, KPKErrorKdbxCorrutpedPublicCustomData);
          return NO;
        }
        break;
      default:
        KPKCreateError(error,KPKErrorKdbxInvalidHeaderFieldType);
        return NO;
    }
  }
}

- (NSUInteger)_parseInnerHeader:(NSData *)data error:(NSError *__autoreleasing *)error {
  /*
   struct innerHeaderElement {
   uint8_t type;
   uint32_t length; // LE
   uint8_t data[length];
   };
   
   0x00: End of header.
   0x01: Inner random stream ID (this supersedes the inner random stream ID stored in the outer header of a KDBX 3.1 file).
   0x02: Inner random stream key (this supersedes the inner random stream key stored in the outer header of a KDBX 3.1 file).
   0x03: Binary (entry attachment). D = F ‖ M, where F is one byte and M is the binary content (i.e. the actual entry attachment data). F stores flags for the binary; supported flags are:
   0x01: The user has turned on process memory protection for this binary.
   The inner header must end with an item of type 0x00 (and n = 0).
   */
  KPKDataStreamReader *reader = [[KPKDataStreamReader alloc] initWithData:data];
  
  uint8_t type;
  uint32_t length;
  self.binaryData = [[NSMutableArray alloc] init];
  while(reader.hasBytesAvailable) {
    type = [reader readByte];
    length = CFSwapInt32LittleToHost([reader read4Bytes]);
    switch(type) {
      case KPKInnerHeaderKeyEndOfHeader:
        if(length != 0) {
          [reader skipBytes:length];
          NSLog(@"Malformed end of inner header data encountered. Skipping %u bytes!", length);
        }
        return reader.offset;
        
      case KPKInnerHeaderKeyBinary:
        if(length > 1) {
          uint8_t flags = [reader readByte];
          NSData *rawData = [reader readDataWithLength:length - 1];
          KPKData *data;
          if(flags & KPKBinaryProtectMemoryFlag) {
            data = [[KPKData alloc] initWithProtectedData:rawData];
          }
          else {
            data = [[KPKData alloc] initWithUnprotectedData:rawData];
          }
          [self.binaryData addObject:data];
        }
        else {
          /* no binary to read */
          [reader skipBytes:1];
        }
        break;
        
      case KPKInnerHeaderKeyRandomStreamId:
        if(length == 4) {
          self.randomStreamID = CFSwapInt32LittleToHost([reader read4Bytes]);
        }
        break;
        
      case KPKInnerHeaderKeyRandomStreamKey:
        if(length > 0) {
          self.randomStreamKey = [reader readDataWithLength:length];
        }
        break;
        
      default:
        KPKCreateError(error, KPKErrorKdbxCorruptedInnerHeader);
        return 0;
        break;
    }
  }
  return 0;
}
@end
