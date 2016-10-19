//
//  KPKFileHeader.h
//  KeePassKit
//
//  Created by Michael Starke on 14/10/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KPKFormat.h"

@class KPKTree;
/**
 File header object to load/save header data
 use initWithData:error: to load the header from the data or
 initWithTree: and then retrieve the data via headerData;
 */
@interface KPKFileHeader : NSObject

@property (nonatomic, readonly, strong) NSUUID *cipherUUID;

@property (nonatomic, readonly, copy) NSUUID *keyDerivationUUID; // fixed for KDB and KDBX3.1
@property (nonatomic, readonly, copy) NSDictionary *keyDerivationOptions;

@property (nonatomic, readonly, copy) NSData *masterSeed;
@property (nonatomic, readonly, copy) NSData *encryptionIV;
@property (nonatomic, readonly, copy) NSData *protectedStreamKey;
@property (nonatomic, readonly, copy) NSData *streamStartBytes;

@property (nonatomic, readonly, assign) uint32_t compressionAlgorithm; // KPKCompression
@property (nonatomic, readonly, assign) uint32_t randomStreamID;

// Obsolte since KDBX4
//@property (nonatomic, readonly, strong) NSData *transformSeed;
//@property (nonatomic, readonly, assign) uint64_t rounds;

@property (readonly, copy) NSData *headerData;
@property (readonly) NSUInteger length;

- (instancetype)initWithData:(NSData *)data error:(NSError **)error NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithTree:(KPKTree *)tree fileInfo:(KPKFileInfo)fileInfo NS_DESIGNATED_INITIALIZER;

@end
