//
//  KPKKDBFileHeader.m
//  KeePassKit
//
//  Created by Michael Starke on 14/10/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKKdbFileHeader.h"
#import "KPKFileHeader_Private.h"

#import "KPKNumber.h"

#import "KPKErrors.h"
#import "KPKLegacyHeaderUtility.h"
#import "KPKLegacyFormat.h"

#import "KPKKeyDerivation.h"
#import "KPKAESKeyDerivation.h"

@interface KPKKdbFileHeader () {
  KPKLegacyHeader _header;
  BOOL _headerValid;
}
@end

@implementation KPKKdbFileHeader

- (instancetype)_initWithTree:(KPKTree *)tree fileInfo:(KPKFileInfo)fileInfo {
  self = [super _initWithTree:tree fileInfo:fileInfo];
  return self;
}

- (instancetype)_initWithData:(NSData *)data error:(NSError *__autoreleasing *)error {
  self = [super _initWithData:data error:error];
  if(self) {
    if(![self _parseHeaderData:data error:error]) {
      self = nil;
    }
  }
  return self;
}

- (NSUInteger)numberOfEntries {
  return _header.entries;
}

- (NSUInteger)numberOfGroups {
  return _header.groups;
}


- (NSData *)masterSeed {
  return [[NSData alloc] initWithBytes:_header.masterSeed length:sizeof(_header.masterSeed)];
}

- (NSData *)encryptionIV {
  return [[NSData alloc] initWithBytes:_header.encryptionIv length:sizeof(_header.encryptionIv)];
}

- (NSData *)headerHash {
  return [KPKLegacyHeaderUtility hashForHeader:&_header];;
}

- (BOOL)_parseHeaderData:(NSData *)data error:(NSError *__autoreleasing*)error {
  // Read in the header
  if(data.length < sizeof(KPKLegacyHeader)) {
    KPKCreateError(error, KPKErrorHeaderCorrupted, @"ERROR_HEADER_CORRUPTED", "");
    return NO;
  }
  [data getBytes:&_header range:NSMakeRange(0, sizeof(KPKLegacyHeader))];
  /*
   Signature Check was done by KPKFormat to determine the correct Cryptor
   */
  
  // Check the version
  _header.version = CFSwapInt32LittleToHost(_header.version);
  if ((_header.version & kKPKKdbFileVersionMask) != (kKPKKdbFileVersion & kKPKKdbFileVersionMask)) {
    KPKCreateError(error, KPKErrorUnsupportedDatabaseVersion, @"ERROR_UNSUPPORTED_DATABASER_VERSION", "");
  }
  
  // Check the encryption algorithm
  _header.flags = CFSwapInt32LittleToHost(_header.flags);
  if (!(_header.flags & KPKLegacyEncryptionAES)) {
    KPKCreateError(error, KPKErrorUnsupportedCipher, @"ERROR_UNSUPPORTED_CIPHER", "");
    @throw [NSException exceptionWithName:@"IOException" reason:@"Unsupported algorithm" userInfo:nil];
  }
  
  _header.groups = CFSwapInt32LittleToHost(_header.groups);
  _header.entries = CFSwapInt32LittleToHost(_header.entries);
  KPKNumber *rounds = [KPKNumber numberWithInteger64:CFSwapInt32LittleToHost(_header.keyEncRounds)];
  
  self.keyDerivationUUID = [KPKAESKeyDerivation uuid];
  self.keyDerivationOptions = @{ KPKAESSeedOption: [[NSData alloc] initWithBytes:_header.masterSeed2 length:sizeof(_header.masterSeed2)],
                                 KPKAESRoundsOption : rounds
                                 };
  return YES;
}

@end
