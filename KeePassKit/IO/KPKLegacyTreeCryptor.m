//
//  KPKLegacyDataCryptor.m
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

#import "KPKLegacyTreeCryptor.h"
#import "KPKLegacyHeaderReader.h"
#import "KPKLegacyHeaderWriter.h"
#import "KPKLegacyTreeReader.h"
#import "KPKLegacyTreeWriter.h"
#import "KPKCompositeKey.h"
#import "KPKVersion.h"
#import "KPKErrors.h"

#import "NSData+CommonCrypto.h"

#import <CommonCrypto/CommonCryptor.h>

@implementation KPKLegacyTreeCryptor

+ (KPKTree *)decryptTreeData:(NSData *)data withPassword:(KPKCompositeKey *)password error:(NSError *__autoreleasing *)error {
  KPKLegacyHeaderReader *headerReader = [[KPKLegacyHeaderReader alloc] initWithData:data error:error];
  if(!headerReader) {
    return nil;
  }
  // Create the final key and initialize the AES input stream
  NSData *keyData = [password finalDataForVersion:KPKLegacyVersion
                                        masterSeed:headerReader.masterSeed
                                     transformSeed:headerReader.transformSeed
                                            rounds:headerReader.rounds];
  

  /*
   The error doesn't get set to success on success
   only get's filled on errors. Therefor initalize it
   to be successfull
   */
  CCCryptorStatus cryptoStatus = kCCSuccess;
  NSData *aesDecrypted = [[headerReader dataWithoutHeader] decryptedDataUsingAlgorithm:kCCAlgorithmAES128
                                                                                        key:keyData
                                                                       initializationVector:headerReader.encryptionIV
                                                                                    options:kCCOptionPKCS7Padding
                                                                                      error:&cryptoStatus];
  if(cryptoStatus != kCCSuccess ) {
    KPKCreateError(error, KPKErrorDecryptionFaild, @"ERROR_DECRYPTION_FAILED", "");
    return nil;
  }
  
  KPKLegacyTreeReader *reader = [[KPKLegacyTreeReader alloc] initWithData:aesDecrypted headerReader:headerReader];
  return [reader tree:error];
}

+ (NSData *)encryptTree:(KPKTree *)tree password:(KPKCompositeKey *)password error:(NSError *__autoreleasing *)error {
  NSMutableData *fileData = [[NSMutableData alloc] init];
  
  // Serialize the tree
  KPKLegacyTreeWriter *treeWriter = [[KPKLegacyTreeWriter alloc] initWithTree:tree];
  NSData *treeData = treeWriter.treeData;

  /* Create the key to encrypt the data stream from the password */
  NSData *keyData = [password finalDataForVersion:KPKLegacyVersion
                                            masterSeed:treeWriter.headerWriter.masterSeed
                                         transformSeed:treeWriter.headerWriter.transformSeed
                                                rounds:treeWriter.headerWriter.transformationRounds];


  CCCryptorStatus cryptoError = kCCSuccess;
  NSData *encryptedTreeData = [treeData dataEncryptedUsingAlgorithm:kCCAlgorithmAES128
                                                                key:keyData
                                               initializationVector:treeWriter.headerWriter.encryptionIv
                                                            options:kCCOptionPKCS7Padding
                                                              error:&cryptoError];
  if(cryptoError != kCCSuccess) {
    KPKCreateError(error, KPKErrorDecryptionFaild, @"ERROR_ENCRYPTION_FAILED", "");
    return nil;
  }
  
  /* Calculate the content hash */
  treeWriter.headerWriter.contentHash = treeData.SHA256Hash;
  [treeWriter.headerWriter writeHeaderData:fileData];
  [fileData appendData:encryptedTreeData];
  return fileData;
}
@end
