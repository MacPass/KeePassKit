//
//  KPKChipherInformation.h
//  MacPass
//
//  Created by Michael Starke on 21.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KPKChipherInformation : NSObject

@property (nonatomic, readonly, strong) NSUUID *cipherUUID;

@property (nonatomic, readonly, strong) NSData *masterSeed;
@property (nonatomic, readonly, strong) NSData *transformSeed;
@property (nonatomic, readonly, strong) NSData *encryptionIV;
@property (nonatomic, readonly, strong) NSData *protectedStreamKey;
@property (nonatomic, readonly, strong) NSData *streamStartBytes;

@property (nonatomic, readonly, assign) uint32_t compressionAlgorithm;
@property (nonatomic, readonly, assign) uint32_t randomStreamID;
@property (nonatomic, readonly, assign) uint64_t rounds;

- (id)initWithData:(NSData *)data error:(NSError **)error;
- (NSData *)dataWithoutHeader;

@end
