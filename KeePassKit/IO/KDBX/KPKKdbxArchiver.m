//
//  KPKKdbxTreeArchiver.m
//  KeePassKit
//
//  Created by Michael Starke on 25/10/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <KissXML/KissXML.h>

#import "KPKKdbxArchiver.h"
#import "KPKArchiver_Private.h"

#import "KPKBinary.h"
#import "KPKBinary_Private.h"
#import "KPKCompositeKey.h"
#import "KPKEntry.h"
#import "KPKEntry_Private.h"
#import "KPKTree.h"

#import "KPKCipher.h"
#import "KPKKeyDerivation.h"
#import "KPKAESKeyDerivation.h"
#import "KPKMetaData.h"
#import "KPKMetaData_Private.h"
#import "KPKXmlTreeWriter.h"
#import "KPKDataStreamWriter.h"


#import "KPKRandomStream.h"
#import "KPKArc4RandomStream.h"
#import "KPKChaCha20RandomStream.h"
#import "KPKSalsa20RandomStream.h"

#import "KPKKdbxFormat.h"
#import "KPKErrors.h"

#import "KPKData.h"
#import "KPKNumber.h"

#import "NSData+KPKRandom.h"
#import "NSData+KPKGzip.h"
#import "NSData+KPKHashedData.h"
#import "NSData+CommonCrypto.h"
#import "NSData+KPKKeyComputation.h"

#import "NSUUID+KPKAdditions.h"

#import "NSDictionary+KPKVariant.h"

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
    [self write4Bytes:CFSwapInt32HostToLittle((uint32_t)length)];
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
@property (assign) KPKFileVersion fileVersion;

@property (strong) KPKRandomStream *randomStream;
@property (strong) NSDateFormatter *dateFormatter;
@property (copy) NSData *headerHash;
@property (readonly,nonatomic,copy) NSArray<KPKData *> *binaryData;

@end

@implementation KPKKdbxArchiver

@synthesize masterSeed = _masterSeed;
@synthesize encryptionIV = _encryptionIV;

- (instancetype)_initWithTree:(KPKTree *)tree key:(KPKCompositeKey *)key {
  self = [super _initWithTree:tree key:key];
  if(self) {
    /* we write kdbx3 at minimum */
    _fileVersion = KPKFileVersionMax(KPKMakeFileVersion(KPKDatabaseFormatKdbx, kKPKKdbxFileVersion3), self.tree.minimumVersion);
    
    NSArray *allEntries = [self.tree.allEntries arrayByAddingObjectsFromArray:self.tree.allHistoryEntries];
    NSMutableSet *tempBinaries = [[NSMutableSet alloc] init];
    for(KPKEntry *entry in allEntries) {
      for(KPKBinary *binary in entry.mutableBinaries) {
        [tempBinaries addObject:binary.internalData];
      }
    }
    _binaryData = tempBinaries.allObjects;
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
  if(self.fileVersion.version >= kKPKKdbxFileVersion4) {
    return NSData.data;
  }
  return [self.headerHash copy];
}

- (NSArray<KPKData *> *)binaryDataForWriter:(KPKXmlTreeWriter *)writer {
  return self.binaryData;
}

- (KPKRandomStream *)randomStreamForWriter:(KPKXmlTreeWriter *)writer {
  return self.randomStream;
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
  
  self.masterSeed = [NSData kpk_dataWithRandomBytes:32];
  self.encryptionIV = [NSData kpk_dataWithRandomBytes:cipher.IVLength];
  
  
  if(self.fileVersion.version >= kKPKKdbxFileVersion4) {
    self.randomStreamID = KPKRandomStreamChaCha20;
    self.randomStreamKey = [NSData kpk_dataWithRandomBytes:64];
  }
  else {
    self.randomStreamID = KPKRandomStreamSalsa20;
    self.randomStreamKey = [NSData kpk_dataWithRandomBytes:32];
    self.streamStartBytes = [NSData kpk_dataWithRandomBytes:32];
  }
  
  NSMutableData *data = [[NSMutableData alloc] init];
  self.dataWriter = [[KPKDataStreamWriter alloc] initWithData:data];
  
  /* file signature */
  [self.dataWriter write4Bytes:CFSwapInt32HostToLittle(kKPKKdbxSignature1)];
  [self.dataWriter write4Bytes:CFSwapInt32HostToLittle(kKPKKdbxSignature2)];
  
  /* file version */
  [self.dataWriter write4Bytes:CFSwapInt32HostToLittle((uint32_t)self.fileVersion.version)];

  BOOL isFileVersion4 = self.fileVersion.version >= kKPKKdbxFileVersion4;
  
  [self.dataWriter _writeHeaderField:KPKHeaderKeyCipherId data:self.tree.metaData.cipherUUID.kpk_uuidData useWideField:isFileVersion4];
  uint32_t compressionAlgorithm = CFSwapInt32HostToLittle(self.tree.metaData.compressionAlgorithm);
  [self.dataWriter _writeHeaderField:KPKHeaderKeyCompression bytes:&compressionAlgorithm length:sizeof(compressionAlgorithm) useWideField:isFileVersion4];
  [self.dataWriter _writeHeaderField:KPKHeaderKeyMasterSeed data:self.masterSeed useWideField:isFileVersion4];
  [self.dataWriter _writeHeaderField:KPKHeaderKeyEncryptionIV data:self.encryptionIV useWideField:isFileVersion4];
  
  /* kdbx 4.x */
  if(isFileVersion4) {
    [self.dataWriter _writeHeaderField:KPKHeaderKeyKdfParameters data:keyDerivation.parameters.kpk_variantDictionaryData useWideField:isFileVersion4];
    if(self.tree.metaData.customPublicData.count > 0) {
      [self.dataWriter _writeHeaderField:KPKHeaderKeyPublicCustomData data:self.tree.metaData.mutableCustomPublicData.kpk_variantDictionaryData useWideField:isFileVersion4];
    }
  }
  /* kdbx3 */
  else {
    [self.dataWriter _writeHeaderField:KPKHeaderKeyTransformSeed data:keyDerivation.parameters[KPKAESSeedOption] useWideField:isFileVersion4];
    uint64_t rounds = CFSwapInt64HostToLittle([keyDerivation.parameters[KPKAESRoundsOption] unsignedInteger64Value]);
    [self.dataWriter _writeHeaderField:KPKHeaderKeyTransformRounds bytes:&rounds length:sizeof(rounds) useWideField:isFileVersion4];
    [self.dataWriter _writeHeaderField:KPKHeaderKeyProtectedKey data:self.randomStreamKey useWideField:isFileVersion4];
    [self.dataWriter _writeHeaderField:KPKHeaderKeyStartBytes data:self.streamStartBytes useWideField:isFileVersion4];
    uint32_t randomStreamId = CFSwapInt32HostToLittle(_randomStreamID);
    [self.dataWriter _writeHeaderField:KPKHeaderKeyRandomStreamId bytes:&randomStreamId length:sizeof(randomStreamId) useWideField:isFileVersion4];
  }

  /* endOfHeader */
#if KPK_MAC
  uint8_t endBuffer[] = { NSCarriageReturnCharacter, NSNewlineCharacter, NSCarriageReturnCharacter, NSNewlineCharacter };
#else
  uint8_t endBuffer[] = { '\r', '\n', '\r', '\n' };
#endif
  
  [self.dataWriter _writeHeaderField:KPKHeaderKeyEndOfHeader bytes:endBuffer length:4 useWideField:isFileVersion4];
  
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
  
  if(!isFileVersion4) {
    NSMutableData *contentData = [[NSMutableData alloc] initWithData:self.streamStartBytes];

    /* compress data */
    if(self.tree.metaData.compressionAlgorithm == KPKCompressionGzip) {
      xmlData = xmlData.kpk_gzipDeflated;
    }
    /* append hashed data */
    [contentData appendData:xmlData.kpk_hashedSha256Data];
    
    /* encrypt data */
    NSData *encryptedData = [cipher encryptData:contentData withKey:keyData initializationVector:self.encryptionIV error:error];
    if(!encryptedData) {
      return nil;
    }
    [self.dataWriter writeData:encryptedData];
  }
  else {
    NSData *headerHmac = [self.dataWriter.writtenData kpk_headerHmacWithKey:hmacKey];
    
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
    for(KPKData *data in self.binaryData) {
      NSUInteger length = data.length + 1;
      uint8_t *buffer = malloc(sizeof(uint8_t) * (length));
      memset(buffer, 0, (data.length + 1));
      if(data.protect) {
        buffer[0] |= KPKBinaryProtectMemoryFlag;
      }
      /* copy data after flags */
      [data getBytes:(buffer+1) length:data.length];
      [innerDataWriter _writeInnerHeaderField:KPKInnerHeaderKeyBinary bytes:buffer length:length];
      free(buffer);
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
    NSData *hashedData = [encryptedData kpk_hashedHmacSha256DataWithKey:hmacKey error:error];
    if(!hashedData) {
      return nil;
    }
    [self.dataWriter writeData:hashedData];
  }
  return data;
}

@end
