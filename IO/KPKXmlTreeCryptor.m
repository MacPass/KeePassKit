//
//  KPKXmlDataCryptor.m
//  KeePassKit
//
//  Created by Michael Starke on 21.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "KPKXmlTreeCryptor.h"
#import "KPKXmlHeaderReader.h"
#import "KPKPassword.h"
#import "KPKVersion.h"
#import "KPKErrors.h"
#import "KPKXmlFormat.h"
#import "KPKTree.h"
#import "KPKMetaData.h"

#import "NSData+CommonCrypto.h"
#import "NSData+HashedData.h"
#import "NSData+Gzip.h"

#import "KPKXmlTreeReader.h"
#import "KPKXmlTreeWriter.h"
#import "KPKXmlHeaderWriter.h"

#import "DDXMLDocument.h"

#import <CommonCrypto/CommonCryptor.h>

@implementation KPKXmlTreeCryptor

+ (KPKTree *)decryptTreeData:(NSData *)data withPassword:(KPKPassword *)password error:(NSError **)error {
  KPKXmlHeaderReader *headerReader = [[KPKXmlHeaderReader alloc] initWithData:data error:error];
  if(!headerReader) {
    return nil;
  }
  
  /*
   Create the Key
   Supply the Data found in the header
   */
  NSData *keyData = [password finalDataForVersion:KPKVersion2
                                       masterSeed:headerReader.masterSeed
                                    transformSeed:headerReader.transformSeed
                                           rounds:headerReader.rounds];
  
  /*
   The datastream is AES encrypted. Decrypt using the supplied
   */
  CCCryptorStatus cryptoError = kCCSuccess;
  NSData *aesDecrypted = [[headerReader dataWithoutHeader] decryptedDataUsingAlgorithm:kCCAlgorithmAES128
                                                                                   key:keyData
                                                                  initializationVector:headerReader.encryptionIV
                                                                               options:kCCOptionPKCS7Padding
                                                                                 error:&cryptoError];
  if(cryptoError != kCCSuccess) {
    KPKCreateError(error, KPKErrorDecryptionFaild, @"ERROR_DECRYPTION_FAILED", "");
    return nil;
  }
  /*
   Compare the first Streambytes with the ones stores in the header
   */
  NSData *startBytes = [aesDecrypted subdataWithRange:NSMakeRange(0, 32)];
  if(![headerReader.streamStartBytes isEqualToData:startBytes]) {
    KPKCreateError(error, KPKErrorIntegrityCheckFaild, @"ERROR_INTEGRITY_CHECK_FAILED", "");
    return nil;
  }
  /*
   The Stream is Hashed, read the data and verify it.
   If the Stream was Gzipped, uncrompress it.
   */
  NSData *unhashedData = [[aesDecrypted subdataWithRange:NSMakeRange(32, [aesDecrypted length] - 32)] unhashedData];
  if(headerReader.compressionAlgorithm == KPKCompressionGzip) {
    unhashedData = [unhashedData gzipInflate];
  }
  
  if(!unhashedData) {
    KPKCreateError(error, KPKErrorIntegrityCheckFaild, @"ERROR_INTEGRITY_CHECK_FAILED", "");
    return nil;
  }
  KPKXmlTreeReader *reader = [[KPKXmlTreeReader alloc] initWithData:unhashedData headerReader:headerReader];
  return [reader tree:error];
}

+ (NSData *)encryptTree:(KPKTree *)tree password:(KPKPassword *)password error:(NSError *__autoreleasing *)error {
  
  NSMutableData *data = [[NSMutableData alloc] init];
  
  KPKXmlHeaderWriter *headerWriter = [[KPKXmlHeaderWriter alloc] initWithTree:tree];
  [headerWriter writeHeaderData:data];
  
  
  KPKXmlTreeWriter *treeWriter = [[KPKXmlTreeWriter alloc] initWithTree:tree headerWriter:headerWriter];
  NSData *xmlData = [[treeWriter xmlDocument] XMLData];
  if(!xmlData) {
    // create Error
    return nil;
  }
  
  NSData *key = [password finalDataForVersion:KPKVersion2
                                   masterSeed:headerWriter.masterSeed
                                transformSeed:headerWriter.transformSeed
                                       rounds:tree.metaData.rounds];
  
  
  NSMutableData *contentData = [[NSMutableData alloc] initWithData:headerWriter.streamStartBytes];
  [contentData appendData:xmlData];
  NSData *hashedData = [contentData hashedData];
  if(tree.metaData.compressionAlgorithm == KPKCompressionGzip) {
    hashedData = [hashedData gzipDeflate];
  }
  
  NSData *encryptedData = [hashedData dataEncryptedUsingAlgorithm:kCCAlgorithmAES128
                                                              key:key
                                             initializationVector:headerWriter.encryptionIv
                                                          options:kCCOptionPKCS7Padding
                                                            error:NULL];
  
  //FIXME Hash output stream
  //OutputStream *stream = [[HashedOutputStream alloc] initWithOutputStream:aesOutputStream blockSize:1024*1024];
  return encryptedData;
}

@end
