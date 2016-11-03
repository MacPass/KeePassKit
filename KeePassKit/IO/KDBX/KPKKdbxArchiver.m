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
@property (copy) NSData *headerHash;
@property (assign) BOOL outputVersion4;

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
    self.randomStreamID = KPKRandomStreamArc4;
  }
  
  NSMutableData *data = [[NSMutableData alloc] init];
  
  /* Version and Signature */
  self.dataWriter = [[KPKDataStreamWriter alloc] initWithData:data];
  [self.dataWriter write4Bytes:CFSwapInt32HostToLittle(kKPKKdbxSignature1)];
  [self.dataWriter write4Bytes:CFSwapInt32HostToLittle(kKPKKdbxSignature2)];
  [self.dataWriter write4Bytes:CFSwapInt32HostToLittle(kKPKKdbxFileVersion3)];
  
  @autoreleasepool {
    [self _writerHeaderField:KPKHeaderKeyCipherId data:self.tree.metaData.cipherUUID.uuidData];
    uint32_t compressionAlgorithm = CFSwapInt32HostToLittle(self.tree.metaData.compressionAlgorithm);
    NSData *headerData = [NSData dataWithBytesNoCopy:&compressionAlgorithm length:sizeof(uint32_t) freeWhenDone:NO];
    [self _writerHeaderField:KPKHeaderKeyCompression data:headerData];
    [self _writerHeaderField:KPKHeaderKeyMasterSeed data:self.masterSeed];
    if(!self.outputVersion4) {
      [self _writerHeaderField:KPKHeaderKeyTransformSeed data:keyDerivation.parameters[KPKAESSeedOption]];
      KPKNumber *roundsOption = keyDerivation.parameters[KPKAESRoundsOption];
      uint64_t rounds = CFSwapInt64HostToLittle(roundsOption.unsignedInteger64Value);
      headerData = [NSData dataWithBytesNoCopy:&rounds length:sizeof(uint64_t) freeWhenDone:NO];
      [self _writerHeaderField:KPKHeaderKeyTransformRounds data:headerData];
    }
    [self _writerHeaderField:KPKHeaderKeyEncryptionIV data:self.encryptionIV];
    [self _writerHeaderField:KPKHeaderKeyProtectedKey data:self.randomStreamKey];
    [self _writerHeaderField:KPKHeaderKeyStartBytes data:self.streamStartBytes];
    
    uint32_t randomStreamId = CFSwapInt32HostToLittle(_randomStreamID);
    headerData = [NSData dataWithBytesNoCopy:&randomStreamId length:sizeof(uint32_t) freeWhenDone:NO];
    [self _writerHeaderField:KPKHeaderKeyRandomStreamId data:headerData];
    
    if(self.outputVersion4) {
      [self _writerHeaderField:KPKHeaderKeyKdfParameters data:keyDerivation.parameters.variantDictionaryData];
    }
    if(self.tree.metaData.customPublicData.count > 0) {
      NSAssert(self.outputVersion4, @"Custom data reuqires KDBX version 4");
      [self _writerHeaderField:KPKHeaderKeyPublicCustomData data:self.tree.metaData.mutableCustomPublicData.variantDictionaryData];
    }
    uint8_t endBuffer[] = { NSCarriageReturnCharacter, NSNewlineCharacter, NSCarriageReturnCharacter, NSNewlineCharacter };
    headerData = [NSData dataWithBytesNoCopy:endBuffer length:4 freeWhenDone:NO];
    [self _writerHeaderField:KPKHeaderKeyEndOfHeader data:headerData];
  }
  
  self.headerHash = self.dataWriter.writtenData.SHA256Hash;
  
  KPKXmlTreeWriter *treeWriter = [[KPKXmlTreeWriter alloc] initWithTree:self.tree delegate:self];
  NSData *xmlData = [treeWriter.xmlDocument XMLDataWithOptions:DDXMLNodeCompactEmptyElement];
  
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
  
  NSMutableData *contentData = [[NSMutableData alloc] initWithData:self.streamStartBytes];
  if(self.tree.metaData.compressionAlgorithm == KPKCompressionGzip) {
    xmlData = [xmlData gzipDeflate];
  }
  
  [contentData appendData:xmlData.hashedSha256Data];
  
  NSData *encryptedData = [cipher encryptData:contentData withKey:keyData initializationVector:self.encryptionIV error:error];
  [data appendData:encryptedData];
  return data;
}

- (void)_writerHeaderField:(KPKHeaderKey)key data:(NSData *)data {
  [self.dataWriter writeByte:key];
  self.outputVersion4 ? [self.dataWriter write4Bytes:CFSwapInt16HostToLittle(data.length)] : [self.dataWriter write2Bytes:CFSwapInt16HostToLittle(data.length)];
  if (data.length > 0) {
    [self.dataWriter writeData:data];
  }
}

@end
