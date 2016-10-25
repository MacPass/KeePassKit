//
//  KPKKdbTreeUnarchiver.m
//  KeePassKit
//
//  Created by Michael Starke on 25/10/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKKdbUnarchiver.h"
#import "KPKUnarchiver_Private.h"

#import "KPKErrors.h"
#import "KPKFormat.h"
#import "KPKKdbFormat.h"
#import "KPKKdbTreeReader.h"

#import "KPKTree.h"
#import "KPKMetaData.h"

#import "KPKAESKeyDerivation.h"

@interface KPKKdbUnarchiver () {
  KPKLegacyHeader _header;
}

@end

@implementation KPKKdbUnarchiver

- (instancetype)_initWithData:(NSData *)data version:(NSUInteger)version key:(KPKCompositeKey *)key error:(NSError *__autoreleasing *)error {
  self = [super _initWithData:data version:version key:key error:error];
  if(self) {
    // Read in the header
    if(data.length < sizeof(KPKLegacyHeader)) {
      KPKCreateError(error, KPKErrorKdbHeaderTruncated);
      self = nil;
      return self;
    }
    [data getBytes:&_header range:NSMakeRange(0, sizeof(KPKLegacyHeader))];
    /*
     Signature Check was done by KPKFormat to determine the correct Cryptor
     */
    
    _header.version = CFSwapInt32LittleToHost(_header.version);
    if ((_header.version & kKPKKdbFileVersionMask) != (kKPKKdbFileVersion & kKPKKdbFileVersionMask)) {
      KPKCreateError(error, KPKErrorUnsupportedDatabaseVersion);
    }
    
    // Check the encryption algorithm
    _header.flags = CFSwapInt32LittleToHost(_header.flags);
    if (!(_header.flags & KPKLegacyEncryptionAES)) {
      KPKCreateError(error, KPKErrorUnsupportedCipher);
      self = nil;
      return self;
    }
    
    _header.groups = CFSwapInt32LittleToHost(_header.groups);
    _header.entries = CFSwapInt32LittleToHost(_header.entries);
    
    self.keyDerivationUUID = [KPKAESKeyDerivation uuid]; // KDB only supports AES key derivation
    self.mutableKeyDerivationOptions = [[KPKAESKeyDerivation optionsWithSeed:[[NSData alloc] initWithBytes:_header.transformationSeed length:sizeof(_header.transformationSeed)]
                                                                      rounds:CFSwapInt32LittleToHost(_header.keyEncRounds)] mutableCopy];
  }
  return self;
}
- (KPKTree *)tree:(NSError * _Nullable __autoreleasing *)error {
  /* todo encrypt */
  NSData *decryptedData;
  KPKKdbTreeReader *treeReader = [[KPKKdbTreeReader alloc] initWithData:decryptedData numberOfEntries:_header.entries numberOfGroups:_header.groups];
  KPKTree *tree = [treeReader tree:error];
  tree.metaData.keyDerivationUUID = self.keyDerivationUUID;
  tree.metaData.keyDerivationOptions = self.mutableKeyDerivationOptions;
  return tree;
}
@end
