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

#import "NSData+CommonCrypto.h"

#import <CommonCrypto/CommonCryptor.h>

@interface KPKLegacyTreeCryptor () {
  KPKLegacyHeaderReader *_headerReader;
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
  _headerReader = [[KPKLegacyHeaderReader alloc] initWithData:_data error:error];
  
  // Create the final key and initialize the AES input stream
  NSData *keyData = [_password finalDataForVersion:KPKVersion1
                                        masterSeed:_headerReader.masterSeed
                                     transformSeed:_headerReader.transformSeed
                                            rounds:_headerReader.rounds];
  
  
  NSData *aesDecrypted = [[_headerReader dataWithoutHeader] decryptedDataUsingAlgorithm:kCCAlgorithmAES128
                                                                                        key:keyData
                                                                       initializationVector:_headerReader.encryptionIV
                                                                                    options:kCCOptionPKCS7Padding
                                                                                      error:NULL];
  
  KPKLegacyTreeReader *reader = [[KPKLegacyTreeReader alloc] initWithData:aesDecrypted headerReader:_headerReader];
  return [reader tree:error];
}

@end
