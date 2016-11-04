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
#import "NSData+Gzip.h"
#import "NSData+HashedData.h"
#import "NSData+CommonCrypto.h"
#import "NSData+KPKKeyComputation.h"

#import "DDXMLDocument.h"

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
    if(self.tree.minimumType == KPKDatabaseFormatKdbx) {
      _outputVersion4 = NO;
    }
    else {
      _outputVersion4 = self.tree.minimumVersion <= kKPKKdbxFileVersion4;
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
  if(self.outputVersion4) {
    return @[];
  }
  return self.binaries;
}

- (KPKRandomStream *)randomStreamForWriter:(KPKXmlTreeWriter *)writer {
  return self.randomStream;
}

- (NSDateFormatter *)dateFormatterForWriter:(KPKXmlTreeWriter *)writer {
  if(self.outputVersion4) {
    return nil;
  }
  if(!self.dateFormatter) {
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    self.dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
  }
  return self.dateFormatter;
}


- (NSUInteger)outputVersionForWriter:(KPKXmlTreeWriter *)writer {
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
  [self _writerHeaderField:KPKHeaderKeyCipherId data:self.tree.metaData.cipherUUID.uuidData];
  uint32_t compressionAlgorithm = CFSwapInt32HostToLittle(self.tree.metaData.compressionAlgorithm);
  NSData *headerData = [NSData dataWithBytesNoCopy:&compressionAlgorithm length:sizeof(uint32_t) freeWhenDone:NO];
  [self _writerHeaderField:KPKHeaderKeyCompression data:headerData];
  [self _writerHeaderField:KPKHeaderKeyMasterSeed data:self.masterSeed];
  [self _writerHeaderField:KPKHeaderKeyEncryptionIV data:self.encryptionIV];
  
  if(!self.outputVersion4) {
    [self _writerHeaderField:KPKHeaderKeyTransformSeed data:keyDerivation.parameters[KPKAESSeedOption]];
    KPKNumber *roundsOption = keyDerivation.parameters[KPKAESRoundsOption];
    uint64_t rounds = CFSwapInt64HostToLittle(roundsOption.unsignedInteger64Value);
    headerData = [NSData dataWithBytesNoCopy:&rounds length:sizeof(uint64_t) freeWhenDone:NO];
    [self _writerHeaderField:KPKHeaderKeyTransformRounds data:headerData];
    [self _writerHeaderField:KPKHeaderKeyProtectedKey data:self.randomStreamKey];
    [self _writerHeaderField:KPKHeaderKeyStartBytes data:self.streamStartBytes];
    uint32_t randomStreamId = CFSwapInt32HostToLittle(_randomStreamID);
    headerData = [NSData dataWithBytesNoCopy:&randomStreamId length:sizeof(uint32_t) freeWhenDone:NO];
    [self _writerHeaderField:KPKHeaderKeyRandomStreamId data:headerData];
  }
  else {
    [self _writerHeaderField:KPKHeaderKeyKdfParameters data:keyDerivation.parameters.variantDictionaryData];
  }
  if(self.tree.metaData.customPublicData.count > 0) {
    NSAssert(self.outputVersion4, @"Custom data reuqires KDBX version 4");
    [self _writerHeaderField:KPKHeaderKeyPublicCustomData data:self.tree.metaData.mutableCustomPublicData.variantDictionaryData];
  }
  /* endOfHeader */
  uint8_t endBuffer[] = { NSCarriageReturnCharacter, NSNewlineCharacter, NSCarriageReturnCharacter, NSNewlineCharacter };
  headerData = [NSData dataWithBytesNoCopy:endBuffer length:4 freeWhenDone:NO];
  [self _writerHeaderField:KPKHeaderKeyEndOfHeader data:headerData];
  
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
  
  /* compress data */
  NSMutableData *contentData = [[NSMutableData alloc] initWithData:self.streamStartBytes];
  if(self.tree.metaData.compressionAlgorithm == KPKCompressionGzip) {
    xmlData = [xmlData gzipDeflate];
  }
  
  /* append hashed data */
  [contentData appendData:xmlData.hashedSha256Data];
  
  /* encrypt data */
  NSData *encryptedData = [cipher encryptData:contentData withKey:keyData initializationVector:self.encryptionIV error:error];
  [data appendData:encryptedData];
  return data;
}

- (void)_writeHeader:(KPKKeyDerivation *)keyDerivation {

}

- (void)_writerHeaderField:(KPKHeaderKey)key data:(NSData *)data {
  [self.dataWriter writeByte:key];
  self.outputVersion4 ? [self.dataWriter write4Bytes:CFSwapInt16HostToLittle(data.length)] : [self.dataWriter write2Bytes:CFSwapInt16HostToLittle(data.length)];
  if (data.length > 0) {
    [self.dataWriter writeData:data];
  }
}

@end
