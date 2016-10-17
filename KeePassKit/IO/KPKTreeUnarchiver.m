//
//  KPKTreeUnarchiver.m
//  KeePassKit
//
//  Created by Michael Starke on 04/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTreeUnarchiver.h"
#import "KPKFileHeader.h"

@implementation KPKTreeUnarchiver

+ (KPKTree *)unarchiveTreeData:(NSData *)data withKey:(KPKCompositeKey *)key error:(NSError *__autoreleasing *)error {
  KPKFileHeader *header = [[KPKFileHeader alloc] initWithData:data error:error];
  if(!header) {
    return nil;
  }
  
  /*
   Create the Key
   Supply the Data found in the header
   */
  NSData *keyData = [password finalDataForVersion:KPKDatabaseFormatKdbx
                                       masterSeed:headerReader.masterSeed
                                    transformSeed:headerReader.transformSeed
                                           rounds:headerReader.rounds];
  
  KPKCipher *cipher = [KPKCipher cipherWithUUID:headerReader.cipherUUID];
  if(!cipher) {
    KPKCreateError(error, KPKErrorUnsupportedCipher, @"ERROR_UNSUPPORTED_CHIPHER", "");
  }
  NSData *decryptedData = [cipher decryptData:headerReader.dataWithoutHeader
                                      withKey:keyData
                         initializationVector:headerReader.encryptionIV
                                        error:error];
  
  if(!decryptedData) {
    return nil;
  }
  
  /*
   Compare the first Streambytes with the ones stores in the header
   */
  NSData *startBytes = [decryptedData subdataWithRange:NSMakeRange(0, 32)];
  if(![headerReader.streamStartBytes isEqualToData:startBytes]) {
    KPKCreateError(error, KPKErrorPasswordAndOrKeyfileWrong, @"ERROR_PASSWORD_OR_KEYFILE_WRONG", "");
    return nil;
  }
  /*
   The Stream is Hashed, read the data and verify it.
   If the Stream was Gzipped, uncrompress it.
   */
  
  /* TODO decide what hash to use based on file version */
  
  NSData *unhashedData = [[decryptedData subdataWithRange:NSMakeRange(32, decryptedData.length - 32)] unhashedData];
  if(headerReader.compressionAlgorithm == KPKCompressionGzip) {
    unhashedData = [unhashedData gzipInflate];
  }
  
  if(!unhashedData) {
    KPKCreateError(error, KPKErrorIntegrityCheckFailed, @"ERROR_INTEGRITY_CHECK_FAILED", "");
    return nil;
  }
  KPKXmlTreeReader *reader = [[KPKXmlTreeReader alloc] initWithData:unhashedData headerReader:headerReader];
  return [reader tree:error];
}

@end
