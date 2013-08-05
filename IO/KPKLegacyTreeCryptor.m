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
#import "KPKLegacyTreeReader.h"
#import "KPKPassword.h"
#import "KPKVersion.h"
#import "KPKErrors.h"

#import "NSData+CommonCrypto.h"

#import <CommonCrypto/CommonCryptor.h>

@implementation KPKLegacyTreeCryptor

+ (KPKTree *)decryptTreeData:(NSData *)data withPassword:(KPKPassword *)password error:(NSError *__autoreleasing *)error {
  KPKLegacyHeaderReader *headerReader = [[KPKLegacyHeaderReader alloc] initWithData:data error:error];
  if(!headerReader) {
    return nil;
  }
  // Create the final key and initialize the AES input stream
  NSData *keyData = [password finalDataForVersion:KPKVersion1
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

+ (NSData *)encryptTree:(KPKTree *)tree password:(KPKPassword *)password error:(NSError *__autoreleasing *)error {
  NSAssert(NO, @"Not implemented");
  return nil;
}


@end
