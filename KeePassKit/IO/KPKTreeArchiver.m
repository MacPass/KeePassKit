//
//  KPKTreeArchiver.m
//  KeePassKit
//
//  Created by Michael Starke on 04/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTreeArchiver.h"
#import "KPKTreeArchiver_Private.h"
#import "KPKXmlTreeWriter.h"
#import "KPKXmlHeaderWriter.h"
#import "KPKLegacyTreeWriter.h"
#import "KPKFormat.h"

#import "KPKTree.h"
#import "KPKMetaData.h"

#import "KPKCompositeKey.h"
#import "KPKCipher.h"
#import "KPKKeyDerivation.h"

#import "KPKErrors.h"

#import "NSData+Gzip.h"
#import "NSData+CommonCrypto.h"

#import "DDXMLDocument.h"

#import <CommonCrypto/CommonCrypto.h>

@implementation KPKTreeArchiver

+ (NSData *)archiveTree:(KPKTree *)tree withKey:(KPKCompositeKey *)key forFileInfo:(KPKFileInfo)fileInfo error:(NSError *__autoreleasing *)error {
  KPKTreeArchiver *archiver = [[KPKTreeArchiver alloc] initWithTree:tree];
  return [archiver archiveWithKey:key forFileInfo:fileInfo error:error];
}

+ (NSData *)archiveTree:(KPKTree *)tree withKey:(KPKCompositeKey *)key error:(NSError *__autoreleasing *)error {
  KPKTreeArchiver *archiver = [[KPKTreeArchiver alloc] initWithTree:tree];
  return [archiver archiveWithKey:key error:error];
  
}

- (instancetype)init {
  self = [self initWithTree:nil];
  return self;
}

- (instancetype)initWithTree:(KPKTree *)tree {
  self = [super init];
  if(self) {
    _tree = tree;
  }
  return self;
}

- (NSData *)archiveWithKey:(KPKCompositeKey *)key error:(NSError *__autoreleasing *)error {
  KPKFileInfo fileInfo;
  fileInfo.type = self.tree.minimumType;
  fileInfo.version =  self.tree.minimumVersion;
  return [self archiveWithKey:key forFileInfo:fileInfo error:error];
}

- (NSData *)archiveWithKey:(KPKCompositeKey *)key forFileInfo:(KPKFileInfo)fileInfo error:(NSError *__autoreleasing *)error {
  NSMutableData *data = [[NSMutableData alloc] init];
  
  if(fileInfo.type == KPKDatabaseFormatKdbx) {
    KPKXmlTreeWriter *treeWriter = [[KPKXmlTreeWriter alloc] initWithTree:self.tree];
    NSData *xmlData = [[treeWriter protectedXmlDocument] XMLDataWithOptions:DDXMLNodeCompactEmptyElement];
    
    KPKKeyDerivation *keyDerivation = nil;
    KPKCipher *cipher = [KPKCipher cipherWithUUID:self.tree.metaData.cipherUUID];
    if(!cipher) {
      KPKCreateError(error, KPKErrorUnsupportedCipher, @"Unkown Cipher", "");
      return nil;
    }
    //NSDictionary *cipherOptions =
    
    NSData *keyData = [key transformForType:fileInfo.type withKeyDerivationUUID:self.tree.metaData.keyDerivationUUID options:self.tree.metaData.keyDerivationOptions error:error];
    
//    NSData *keyData = [key finalDataForVersion:fileInfo.type
//                                     masterSeed:treeWriter.headerWriter.masterSeed
//                                  transformSeed:treeWriter.headerWriter.transformSeed
//                                         rounds:treeWriter.tree.metaData.rounds];
    
    
    NSMutableData *contentData = [[NSMutableData alloc] initWithData:treeWriter.headerWriter.streamStartBytes];
    if(self.tree.metaData.compressionAlgorithm == KPKCompressionGzip) {
      xmlData = [xmlData gzipDeflate];
    }
    NSData *hashedData = [xmlData hashedDataWithBlockSize:1024*1024];
    [contentData appendData:hashedData];
    NSData *encryptedData = [contentData dataEncryptedUsingAlgorithm:kCCAlgorithmAES128
                                                                 key:keyData
                                                initializationVector:treeWriter.headerWriter.encryptionIv
                                                             options:kCCOptionPKCS7Padding
                                                               error:NULL];
    [treeWriter.headerWriter writeHeaderData:data];
    [data appendData:encryptedData];
    return data;
  }
  else if(fileInfo.type == KPKDatabaseFormatKdb) {
    
  }
  return nil;
}


@end
