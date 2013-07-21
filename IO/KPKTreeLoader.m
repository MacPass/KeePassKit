//
//  KPKParser.m
//  KeePassKit
//
//  Created by Michael Starke on 12.07.13.
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


#import "KPKTreeLoader.h"
#import "KPKTree.h"
#import "KPKFormat.h"
#import "KPKPassword.h"
#import "KPKXmlTreeReader.h"
#import "KPKBinaryTreeReader.h"
#import "KPKHeaderFields.h"
#import "KPKErrors.h"

#import "NSUUID+KeePassKit.h"
#import "KPKXmlCipherInformation.h"
#import "KPKBinaryCipherInformation.h"

#import "NSData+CommonCrypto.h"
#import "NSData+HashedData.h"
#import "NSData+Gzip.h"

#import "DDXML.h"

#import "RandomStream.h"
#import "Salsa20RandomStream.h"
#import "Arc4RandomStream.h"

@interface KPKTreeLoader () {
@private
  DDXMLDocument *_document;
  NSData *_data;
  KPKVersion _version;
  KPKBinaryCipherInformation *_binaryCipherInfo;
  KPKXmlCipherInformation *_xmlCipherInfo;
  KPKPassword *_password;
}

@end

@implementation KPKTreeLoader

- (id)initWithData:(NSData *)data password:(KPKPassword *)password {
  self = [super init];
  if(self) {
    _data = data;
    _password = password;
  }
  return self;
}

- (KPKTree *)loadTree:(NSError **)error {
  KPKFormat *format = [KPKFormat sharedFormat];
  _version = [format databaseVersionForData:_data];
  
  if(_version == KPKVersion1) {
    NSData *data = [self _decryptVersion1Data:error];
    if(!data) {
      return nil;
    }
    KPKBinaryTreeReader *treeReader = [[KPKBinaryTreeReader alloc] initWithData:_data chipherInformation:_binaryCipherInfo];
    return [treeReader tree];
  }
  if(_version == KPKVersion2) {
    NSData *data = [self _decryptVersion2Data:error];
    if(!data) {
      return nil;
    }
    KPKXmlTreeReader *treeReader = [[KPKXmlTreeReader alloc] initWithData:data cipherInformation:_xmlCipherInfo];
    return [treeReader tree];
  }
  if(error != NULL) {
    *error = KPKCreateError(KPKErrorUnknownFileFormat, @"ERROR_UNKOWN_FILE_FORMAT", "");
  }
  return nil;
}

- (NSData *)_decryptVersion1Data:(NSError *__autoreleasing *)error {
  _binaryCipherInfo = [[KPKBinaryCipherInformation alloc] initWithData:_data error:error];
  
  // Create the final key and initialize the AES input stream
  NSData *keyData = [_password finalDataForVersion:_version
                                             masterSeed:_binaryCipherInfo.masterSeed
                                          transformSeed:_binaryCipherInfo.transformSeed
                                            rounds:_binaryCipherInfo.rounds];

  
  NSData *aesDecrypted = [[_binaryCipherInfo dataWithoutHeader] decryptedDataUsingAlgorithm:kCCAlgorithmAES128
                                                                                   key:keyData
                                                                  initializationVector:_binaryCipherInfo.encryptionIV
                                                                               options:kCCOptionPKCS7Padding
                                                                                 error:NULL];
  
  
  return aesDecrypted;
}

- (NSData *)_decryptVersion2Data:(NSError **)error {
  _xmlCipherInfo = [[KPKXmlCipherInformation alloc] initWithData:_data error:error];
  if(!_xmlCipherInfo) {
    return nil;
  }

  /*
   Create the Key
   Supply the Data found in the header
   */
  NSData *keyData = [_password finalDataForVersion:_version
                                        masterSeed:_xmlCipherInfo.masterSeed
                                     transformSeed:_xmlCipherInfo.transformSeed
                                            rounds:_xmlCipherInfo.rounds];
  
  /*
   The datastream is AES encrypted. Decrypt using the supplied
   */
  NSData *aesDecrypted = [[_xmlCipherInfo dataWithoutHeader] decryptedDataUsingAlgorithm:kCCAlgorithmAES128
                                                                                   key:keyData
                                                                  initializationVector:_xmlCipherInfo.encryptionIV
                                                                               options:kCCOptionPKCS7Padding
                                                                                 error:NULL];
  /*
   Compare the first Streambytes with the ones stores in the header
   */
  NSData *startBytes = [aesDecrypted subdataWithRange:NSMakeRange(0, 32)];
  if(![_xmlCipherInfo.streamStartBytes isEqualToData:startBytes]) {
    if(error != NULL) {
      *error = KPKCreateError(KPKErrorKDBXIntegrityCheckFaild, @"ERROR_INTEGRITY_CHECK_FAILED", "");
    }
    return nil;
  }
  /*
   The Stream is Hashed, read the data and verify it.
   If the Stream was Gzipped, uncrompress it.
   */
  NSData *unhashedData = [[aesDecrypted subdataWithRange:NSMakeRange(32, [aesDecrypted length] - 32)] unhashedData];
  if(_xmlCipherInfo.compressionAlgorithm == KPKCompressionGzip) {
    unhashedData = [unhashedData gzipInflate];
  }
  
  if(!unhashedData) {
    if(error != NULL) {
      *error = KPKCreateError(KPKErrorKDBXIntegrityCheckFaild, @"ERROR_INTEGRITY_CHECK_FAILED", "");
    }
    return nil;
  }
  
  
  //  tree.rounds = rounds;
  //  tree.compressionAlgorithm = compressionAlgorithm;
  
  return unhashedData;
}

@end
