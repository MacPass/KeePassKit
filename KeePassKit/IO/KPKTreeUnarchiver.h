//
//  KPKTreeUnarchiver.h
//  KeePassKit
//
//  Created by Michael Starke on 04/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKCompositeKey;
@class KPKTree;

@interface KPKTreeUnarchiver : NSObject

@property (nonatomic, readonly, strong) NSUUID *cipherUUID;

@property (nonatomic, readonly, strong) NSData *masterSeed;
@property (nonatomic, readonly, strong) NSData *transformSeed;
@property (nonatomic, readonly, strong) NSData *encryptionIV;
@property (nonatomic, readonly, strong) NSData *protectedStreamKey;
@property (nonatomic, readonly, strong) NSData *streamStartBytes;

@property (nonatomic, readonly, assign) uint32_t compressionAlgorithm; // KPKCompression
@property (nonatomic, readonly, assign) uint32_t randomStreamID; // KPKRandomStreamType
@property (nonatomic, readonly, assign) uint64_t rounds;

@property (nonatomic, readonly, strong) NSData *contentsHash;
@property (nonatomic, readonly, strong) NSData *headerHash;

@property (nonatomic, readonly) NSUInteger numberOfEntries;
@property (nonatomic, readonly) NSUInteger numberOfGroups;

@property (nonatomic, readonly, copy) NSData *dataWithoutHeader;

- (instancetype)initWithData:(NSData *)data error:(NSError **)error;

- (KPKTree *)unarchiveTreeWithKey:(KPKCompositeKey *)key error:(NSError **)error;
@end
