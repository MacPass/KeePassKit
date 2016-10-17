//
//  KPKFileHeader.h
//  KeePassKit
//
//  Created by Michael Starke on 14/10/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKTree;


/**
 File header object to load/save header data
 use initWithData:error: to load the header from the data or
 initWithTree: and then retrieve the data via headerData;
 */
@interface KPKFileHeader : NSObject

@property (nonatomic, readonly, strong) NSUUID *cipherUUID;

@property (nonatomic, readonly, copy) NSUUID *keyDerivationUUID;
@property (nonatomic, readonly, copy) NSDictionary *keyDerivationOptions; // contains rounds for aes

@property (nonatomic, readonly, strong) NSData *masterSeed;
@property (nonatomic, readonly, strong) NSData *encryptionIV;
@property (nonatomic, readonly, strong) NSData *protectedStreamKey;
@property (nonatomic, readonly, strong) NSData *streamStartBytes;

@property (nonatomic, readonly, assign) uint32_t compressionAlgorithm; // KPKCompression
@property (nonatomic, readonly, assign) uint32_t randomStreamID;

@property (nonatomic, readonly, strong) NSData *contentsHash;

// Obsolte since KDBX4
//@property (nonatomic, readonly, strong) NSData *transformSeed;
//@property (nonatomic, readonly, assign) uint64_t rounds;
//@property (nonatomic, readonly, strong) NSData *headerHash;

@property (nonatomic, readonly) NSUInteger numberOfEntries;
@property (nonatomic, readonly) NSUInteger numberOfGroups;

- (instancetype)initWithData:(NSData *)data error:(NSError **)error NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithTree:(KPKTree *)tree NS_DESIGNATED_INITIALIZER;

- (NSData *)headerData;

@end
