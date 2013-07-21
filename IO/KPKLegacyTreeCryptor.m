//
//  KPKLegacyDataCryptor.m
//  MacPass
//
//  Created by Michael Starke on 21.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKLegacyTreeCryptor.h"
#import "KPKLegacyHeaderReader.h"
#import "KPKBinaryTreeReader.h"
#import "KPKPassword.h"
#import "KPKVersion.h"

#import "NSData+CommonCrypto.h"

#import <CommonCrypto/CommonCryptor.h>

@interface KPKLegacyTreeCryptor () {
  KPKLegacyHeaderReader *_cipherInfo;
}
@end

@implementation KPKLegacyTreeCryptor

- (id)initWithData:(NSData *)data passwort:(KPKPassword *)password {
  self = [super initWithData:data passwort:password];
  if(self) {
  }
  return self;
}

- (KPKTree *)decryptTree:(NSError *__autoreleasing *)error {
  _cipherInfo = [[KPKLegacyHeaderReader alloc] initWithData:_data error:error];
  
  // Create the final key and initialize the AES input stream
  NSData *keyData = [_password finalDataForVersion:KPKVersion1
                                        masterSeed:_cipherInfo.masterSeed
                                     transformSeed:_cipherInfo.transformSeed
                                            rounds:_cipherInfo.rounds];
  
  
  NSData *aesDecrypted = [[_cipherInfo dataWithoutHeader] decryptedDataUsingAlgorithm:kCCAlgorithmAES128
                                                                                        key:keyData
                                                                       initializationVector:_cipherInfo.encryptionIV
                                                                                    options:kCCOptionPKCS7Padding
                                                                                      error:NULL];
  
  KPKBinaryTreeReader *reader = [[KPKBinaryTreeReader alloc] initWithData:aesDecrypted chipherInformation:_cipherInfo];
  return [reader tree];
}

@end
