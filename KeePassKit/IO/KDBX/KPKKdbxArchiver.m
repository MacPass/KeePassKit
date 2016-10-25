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

#import "KPKDataStreamWriter.h"

#import "KPKKdbxFormat.h"
#import "KPKErrors.h"

#import "NSData+Random.h"
#import "NSData+Gzip.h"
#import "NSData+HashedData.h"
#import "NSData+CommonCrypto.h"

#import "DDXMLDocument.h"

@interface KPKKdbxArchiver ()

@property (strong) KPKDataStreamWriter *dataWriter;
@property (copy) NSData *randomStreamKey;
@property (copy) NSData *randomStartBytes;
@property (assign) KPKRandomStreamType randomStreamID;

@property (assign) BOOL isVersion4;

@end

@implementation KPKKdbxArchiver

@synthesize masterSeed = _masterSeed;
@synthesize encryptionIV = _encryptionIV;

- (NSData *)archiveTree:(NSError *__autoreleasing *)error {

  _masterSeed = [NSData dataWithRandomBytes:32];
  _encryptionIV = [[NSData dataWithRandomBytes:16] copy];
  _randomStreamKey = [[NSData dataWithRandomBytes:32] copy];
  _randomStartBytes = [[NSData dataWithRandomBytes:32] copy];
  /* random stream defaults to salsa20 */
  _randomStreamID = self.isVersion4 ? KPKRandomStreamChaCha20 : KPKRandomStreamSalsa20;
  
  KPKKeyDerivation *keyDerivation = [[KPKKeyDerivation alloc] initWithUUID:self.tree.metaData.keyDerivationUUID options:self.tree.metaData.keyDerivationOptions];
  [keyDerivation randomize];
  
  NSMutableData *data = [[NSMutableData alloc] init];
  
  /* Version and Signature */
  self.dataWriter = [[KPKDataStreamWriter alloc] initWithData:data];
  [self.dataWriter write4Bytes:CFSwapInt32HostToLittle(kKPKKdbxSignature1)];
  [self.dataWriter write4Bytes:CFSwapInt32HostToLittle(kKPKKdbxSignature2)];
  [self.dataWriter write4Bytes:CFSwapInt32HostToLittle(kKPKKdbxFileVersion3)];
  
  @autoreleasepool {
    uuid_t uuidBytes;
    [self.tree.metaData.cipherUUID getUUIDBytes:uuidBytes];
    NSData *headerData = [NSData dataWithBytesNoCopy:&uuidBytes length:sizeof(uuid_t) freeWhenDone:NO];
    [self _writerHeaderField:KPKHeaderKeyCipherId data:headerData];
    
    uint32_t compressionAlgorithm = CFSwapInt32HostToLittle(self.tree.metaData.compressionAlgorithm);
    headerData = [NSData dataWithBytesNoCopy:&compressionAlgorithm length:sizeof(uint32_t) freeWhenDone:NO];
    [self _writerHeaderField:KPKHeaderKeyCompression data:headerData];
    [self _writerHeaderField:KPKHeaderKeyMasterSeed data:self.masterSeed];
    if(self.isVersion4) {
      [self _writerHeaderField:KPKHeaderKeyTransformSeed data:keyDerivation.options[KPKAESSeedOption]];
      KPKNumber *roundsOption = self.tree.metaData.keyDerivationOptions[KPKAESRoundsOption];
      uint64_t rounds = CFSwapInt64HostToLittle(roundsOption.unsignedInteger64Value);
      headerData = [NSData dataWithBytesNoCopy:&rounds length:sizeof(uint64_t) freeWhenDone:NO];
      [self _writerHeaderField:KPKHeaderKeyTransformRounds data:headerData];
    }
    else {
      [self _writerHeaderField:KPKHeaderKeyKdfParameters data:keyDerivation.options.variantDictionaryData];
    }
    [self _writerHeaderField:KPKHeaderKeyEncryptionIV data:self.encryptionIV];
    [self _writerHeaderField:KPKHeaderKeyProtectedKey data:self.randomStreamKey];
    [self _writerHeaderField:KPKHeaderKeyStartBytes data:self.randomStartBytes];
    
    uint32_t randomStreamId = CFSwapInt32HostToLittle(_randomStreamID);
    headerData = [NSData dataWithBytesNoCopy:&randomStreamId length:sizeof(uint32_t) freeWhenDone:NO];
    [self _writerHeaderField:KPKHeaderKeyRandomStreamId data:headerData];
    
    uint8_t endBuffer[] = { NSCarriageReturnCharacter, NSNewlineCharacter, NSCarriageReturnCharacter, NSNewlineCharacter };
    headerData = [NSData dataWithBytesNoCopy:endBuffer length:4 freeWhenDone:NO];
    [self _writerHeaderField:KPKHeaderKeyEndOfHeader data:headerData];
  }
  
  NSData *headerHash = self.isVersion4 ? nil : self.dataWriter.writtenData.SHA256Hash;
  KPKXmlTreeWriter *treeWriter = [[KPKXmlTreeWriter alloc] initWithTree:self.tree randomStreamType:self.randomStreamID randomStreamKey:self.randomStreamKey headerHash:headerHash];
  NSData *xmlData = [treeWriter.xmlDocument XMLDataWithOptions:DDXMLNodeCompactEmptyElement];
  
  NSData *keyData = [self.key transformForFormat:KPKDatabaseFormatKdbx seed:self.masterSeed keyDerivation:nil error:error];

  KPKCipher *cipher = [KPKCipher cipherWithUUID:self.tree.metaData.cipherUUID];
  if(!cipher) {
    KPKCreateError(error, KPKErrorUnsupportedCipher);
    return nil;
  }
  
  NSMutableData *contentData = [[NSMutableData alloc] initWithData:self.randomStartBytes];
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
  if(self.isVersion4) {
    [self.dataWriter write4Bytes:CFSwapInt16HostToLittle(data.length)];
  }
  else {
    [self.dataWriter write2Bytes:CFSwapInt16HostToLittle(data.length)];
  }
  if (data.length > 0) {
    [self.dataWriter writeData:data];
  }
}

@end
