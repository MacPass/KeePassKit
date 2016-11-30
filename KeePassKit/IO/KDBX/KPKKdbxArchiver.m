//
//  KPKKdbxTreeArchiver.m
//  KeePassKit
//
//  Created by Michael Starke on 25/10/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKKdbxArchiver.h"
#import "KPKArchiver_Private.h"

#import "KPKCompositeKey.h"

#import "KPKXmlTreeWriter.h"
#import "KPKCipher.h"
#import "KPKKeyDerivation.h"
#import "KPKMetaData.h"
#import "KPKMetaData_Private.h"

#import "KPKDataStreamWriter.h"

#import "KPKRandomStream.h"
#import "KPKArc4RandomStream.h"
#import "KPKChaCha20RandomStream.h"
#import "KPKSalsa20RandomStream.h"

#import "KPKKdbxFormat.h"
#import "KPKErrors.h"

#import "NSData+Random.h"
#import "NSData+KPKGzip.h"
#import "NSData+HashedData.h"
#import "NSData+CommonCrypto.h"
#import "NSData+KPKKeyComputation.h"

#import "DDXMLDocument.h"

@interface KPKDataStreamWriter (KPKHeaderWriting)

- (void)_writeInnerHeaderField:(KPKInnerHeaderKey)key bytes:(const void *)bytes length:(NSUInteger)length;
- (void)_writeInnerHeaderField:(KPKInnerHeaderKey)key data:(NSData *)data;
- (void)_writeHeaderField:(KPKHeaderKey)key bytes:(const void *)bytes length:(NSUInteger)length useWideField:(BOOL)wideField;
- (void)_writeHeaderField:(KPKHeaderKey)key data:(NSData *)data useWideField:(BOOL)wideField;

@end

@implementation KPKDataStreamWriter (KPKHeaderWriting)

- (void)_writeHeaderField:(KPKHeaderKey)key bytes:(const void *)bytes length:(NSUInteger)length useWideField:(BOOL)wideField {
  [self writeByte:key];
  if(wideField) {
    [self write4Bytes:CFSwapInt16HostToLittle(length)];
  }
  else {
    [self write2Bytes:CFSwapInt16HostToLittle(length)];
  }
  if (length > 0) {
    [self writeBytes:bytes length:length];
  }
}
- (void)_writeHeaderField:(KPKHeaderKey)key data:(NSData *)data useWideField:(BOOL)wideField {
  [self _writeHeaderField:key bytes:data.bytes length:data.length useWideField:wideField];
}

- (void)_writeInnerHeaderField:(KPKInnerHeaderKey)key bytes:(const void *)bytes length:(NSUInteger)length {
  [self _writeHeaderField:(uint32_t)key bytes:bytes length:length useWideField:YES];
}

- (void)_writeInnerHeaderField:(KPKInnerHeaderKey)key data:(NSData *)data {
  [self _writeInnerHeaderField:key bytes:data.bytes length:data.length];
}

@end


@interface KPKKdbxArchiver () <KPKXmlTreeWriterDelegate>

@property (strong) KPKDataStreamWriter *dataWriter;
@property (copy) NSData *randomStreamKey;
@property (copy) NSData *streamStartBytes;
@property (assign) KPKRandomStreamType randomStreamID;
@property (assign) BOOL outputVersion4;

@property (strong) KPKRandomStream *randomStream;
@property (strong) NSDateFormatter *dateFormatter;
@property (copy) NSData *headerHash;
@property (readonly,nonatomic,copy) NSArray *binaries;

@end

@implementation KPKKdbxArchiver

@synthesize masterSeed = _masterSeed;
@synthesize encryptionIV = _encryptionIV;

- (instancetype)_initWithTree:(KPKTree *)tree key:(KPKCompositeKey *)key {
  self = [super _initWithTree:tree key:key];
  if(self) {
    KPKFileVersion version4 = { KPKDatabaseFormatKdbx, kKPKKdbxFileVersion4 };
    NSComparisonResult result = KPKFileVersionCompare(self.tree.minimumVersion, version4);
    if(result == NSOrderedSame || result == NSOrderedDescending) {
      _outputVersion4 = YES;
    }
    else {
      _outputVersion4 = NO;
    }
    
    NSArray *allEntries = [self.tree.allEntries arrayByAddingObjectsFromArray:self.tree.allHistoryEntries];
    NSMutableArray *tempBinaries = [[NSMutableArray alloc] init];
    for(KPKEntry *entry in allEntries) {
      for(KPKBinary *binary in entry.binaries) {
        if(![tempBinaries containsObject:binary]) {
          [tempBinaries addObject:binary];
        }
      }
    }
    _binaries = [tempBinaries copy];
  }
  return self;
}

#pragma mark -
#pragma mark KPKXmlTreeWriterDelegate

- (KPKRandomStreamType)randomStreamTypeForWriter:(KPKXmlTreeWriter *)writer {
  return self.randomStreamID;
}

- (NSData *)randomStreamKeyForWriter:(KPKXmlTreeWriter *)writer {
  return [self.randomStreamKey copy];
}

- (NSData *)headerHashForWriter:(KPKXmlTreeWriter *)writer {
  if(self.outputVersion4) {
    return nil;
  }
  return [self.headerHash copy];
}

- (NSUInteger)writer:(KPKXmlTreeWriter *)writer referenceForBinary:(KPKBinary *)binary {
  return [self.binaries indexOfObject:binary];
}

- (NSArray *)binariesForWriter:(KPKXmlTreeWriter *)writer {
  return self.binaries;
}

- (KPKRandomStream *)randomStreamForWriter:(KPKXmlTreeWriter *)writer {
  return self.randomStream;
}

- (NSUInteger)fileVersionForWriter:(KPKXmlTreeWriter *)writer {
  if(self.outputVersion4) {
    return kKPKKdbxFileVersion4;
  }
  return kKPKKdbxFileVersion3;
}

#pragma mark -

- (NSData *)archiveTree:(NSError *__autoreleasing *)error {
  KPKCipher *cipher = [KPKCipher cipherWithUUID:self.tree.metaData.cipherUUID];
  if(!cipher) {
    KPKCreateError(error, KPKErrorUnsupportedCipher);
    return nil;
  }
  
  KPKKeyDerivation *keyDerivation = [[KPKKeyDerivation alloc] initWithParameters:self.tree.metaData.keyDerivationParameters];
  if(!keyDerivation) {
    KPKCreateError(error, KPKErrorUnsupportedKeyDerivation);
    return nil;
  }
  [keyDerivation randomize];
  
  self.masterSeed = [NSData dataWithRandomBytes:32];
  self.encryptionIV = [NSData dataWithRandomBytes:cipher.IVLength];
  self.randomStreamKey = [NSData dataWithRandomBytes:32];
  
  if(self.outputVersion4) {
    self.randomStreamID = KPKRandomStreamChaCha20;
  }
  else {
    self.streamStartBytes = [NSData dataWithRandomBytes:32];
    self.randomStreamID = KPKRandomStreamSalsa20;
  }
  
  NSMutableData *data = [[NSMutableData alloc] init];
  self.dataWriter = [[KPKDataStreamWriter alloc] initWithData:data];
  
  /* file signature */
  [self.dataWriter write4Bytes:CFSwapInt32HostToLittle(kKPKKdbxSignature1)];
  [self.dataWriter write4Bytes:CFSwapInt32HostToLittle(kKPKKdbxSignature2)];
  
  /* file version */
  if(self.outputVersion4) {
    [self.dataWriter write4Bytes:CFSwapInt32HostToLittle(kKPKKdbxFileVersion4)];
  }
  else {
    [self.dataWriter write4Bytes:CFSwapInt32HostToLittle(kKPKKdbxFileVersion3)];
  }
  /* header fields */
  
  [self.dataWriter _writeHeaderField:KPKHeaderKeyCipherId data:self.tree.metaData.cipherUUID.uuidData useWideField:self.outputVersion4];
  uint32_t compressionAlgorithm = CFSwapInt32HostToLittle(self.tree.metaData.compressionAlgorithm);
  [self.dataWriter _writeHeaderField:KPKHeaderKeyCompression bytes:&compressionAlgorithm length:sizeof(compressionAlgorithm) useWideField:self.outputVersion4];
  [self.dataWriter _writeHeaderField:KPKHeaderKeyMasterSeed data:self.masterSeed useWideField:self.outputVersion4];
  [self.dataWriter _writeHeaderField:KPKHeaderKeyEncryptionIV data:self.encryptionIV useWideField:self.outputVersion4];
  
  if(!self.outputVersion4) {
    [self.dataWriter _writeHeaderField:KPKHeaderKeyTransformSeed data:keyDerivation.parameters[KPKAESSeedOption] useWideField:self.outputVersion4];
    uint64_t rounds = CFSwapInt64HostToLittle([keyDerivation.parameters[KPKAESRoundsOption] unsignedInteger64Value]);
    [self.dataWriter _writeHeaderField:KPKHeaderKeyTransformRounds bytes:&rounds length:sizeof(rounds) useWideField:self.outputVersion4];
    [self.dataWriter _writeHeaderField:KPKHeaderKeyProtectedKey data:self.randomStreamKey useWideField:self.outputVersion4];
    [self.dataWriter _writeHeaderField:KPKHeaderKeyStartBytes data:self.streamStartBytes useWideField:self.outputVersion4];
    uint32_t randomStreamId = CFSwapInt32HostToLittle(_randomStreamID);
    [self.dataWriter _writeHeaderField:KPKHeaderKeyRandomStreamId bytes:&randomStreamId length:sizeof(randomStreamId) useWideField:self.outputVersion4];
  }
  else {
    [self.dataWriter _writeHeaderField:KPKHeaderKeyKdfParameters data:keyDerivation.parameters.variantDictionaryData useWideField:self.outputVersion4];
  }
  if(self.tree.metaData.customPublicData.count > 0) {
    NSAssert(self.outputVersion4, @"Custom data requires KDBX version 4");
    [self.dataWriter _writeHeaderField:KPKHeaderKeyPublicCustomData data:self.tree.metaData.mutableCustomPublicData.variantDictionaryData useWideField:self.outputVersion4];
  }
  /* endOfHeader */
  uint8_t endBuffer[] = { NSCarriageReturnCharacter, NSNewlineCharacter, NSCarriageReturnCharacter, NSNewlineCharacter };
  [self.dataWriter _writeHeaderField:KPKHeaderKeyEndOfHeader bytes:endBuffer length:4 useWideField:self.outputVersion4];
  
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
  /* calcualte header hash to supply to writer */
  self.headerHash = self.dataWriter.writtenData.SHA256Hash;
  
  /* write xml data */
  KPKXmlTreeWriter *treeWriter = [[KPKXmlTreeWriter alloc] initWithTree:self.tree delegate:self];
  NSData *xmlData = [treeWriter.xmlDocument XMLDataWithOptions:DDXMLNodeCompactEmptyElement];
  
 
  /* create key */
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
  
  if(!self.outputVersion4) {
    NSMutableData *contentData = [[NSMutableData alloc] initWithData:self.streamStartBytes];
    

    /* compress data */
    if(self.tree.metaData.compressionAlgorithm == KPKCompressionGzip) {
      xmlData = xmlData.kpk_gzipDeflated;
    }
    /* append hashed data */
    [contentData appendData:xmlData.hashedSha256Data];
    
    /* encrypt data */
    NSData *encryptedData = [cipher encryptData:contentData withKey:keyData initializationVector:self.encryptionIV error:error];
    if(!encryptedData) {
      return nil;
    }
    [self.dataWriter writeData:encryptedData];
  }
  else {
    NSData *headerHmac = [self.dataWriter.writtenData headerHmacWithKey:hmacKey];
    
    /* add header hash */
    [self.dataWriter writeData:self.headerHash];
    /* add header hmac */
    [self.dataWriter writeData:headerHmac];
    
    
    /* inner header and xml data are encrypted */
    NSMutableData *innerData = [[NSMutableData alloc] init];
    KPKDataStreamWriter *innerDataWriter = [[KPKDataStreamWriter alloc] initWithData:innerData];

    /* inner header */
    uint32_t LErandomStreamId = CFSwapInt32HostToLittle(self.randomStreamID);
    [innerDataWriter _writeInnerHeaderField:KPKInnerHeaderKeyRandomStreamId bytes:&LErandomStreamId length:sizeof(LErandomStreamId)];
    [innerDataWriter _writeInnerHeaderField:KPKInnerHeaderKeyRandomStreamKey data:self.randomStreamKey];
    for(KPKBinary *binary in self.binaries) {
      uint8_t buffer[binary.data.length + 1];
      if(binary.protectInMemory) {
        buffer[0] &= KPKBinaryProtectMemoryFlag;
      }
      [innerDataWriter _writeInnerHeaderField:KPKInnerHeaderKeyBinary bytes:buffer length:sizeof(buffer)];
    }
    [innerDataWriter _writeInnerHeaderField:KPKInnerHeaderKeyEndOfHeader data:nil];
    
    [innerData appendData:xmlData];

    NSData *encryptedData;
    /* encrypt data */
    if(self.tree.metaData.compressionAlgorithm == KPKCompressionGzip) {
      /* compress data if enabled */
      encryptedData = [cipher encryptData:innerData.kpk_gzipDeflated withKey:keyData initializationVector:self.encryptionIV error:error];
    }
    else {
      encryptedData = [cipher encryptData:innerData withKey:keyData initializationVector:self.encryptionIV error:error];;
    }

    if(!encryptedData) {
      return nil;
    }
    NSData *hashedData = [encryptedData hashedHmacSha256DataWithKey:hmacKey error:error];
    if(!hashedData) {
      return nil;
    }
    [self.dataWriter writeData:hashedData];
  }
  return data;
}

@end
