//
//  KPKChipherInformation.h
//  MacPass
//
//  Created by Michael Starke on 21.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KPKXmlCipherInformation : NSObject

@property (nonatomic, readonly, strong) NSUUID *cipherUUID;

@property (nonatomic, readonly, strong) NSData *masterSeed;
@property (nonatomic, readonly, strong) NSData *transformSeed;
@property (nonatomic, readonly, strong) NSData *encryptionIV;
@property (nonatomic, readonly, strong) NSData *protectedStreamKey;
@property (nonatomic, readonly, strong) NSData *streamStartBytes;

@property (nonatomic, readonly, assign) uint32_t compressionAlgorithm;
@property (nonatomic, readonly, assign) uint32_t randomStreamID;
@property (nonatomic, readonly, assign) uint64_t rounds;

/**
 Initalizes a new Chipher information with random seeds
 @returns the initalized instance
 */
- (id)init;
/**
 Initalizes a new Chipher information with the information found in the header
 @param data The file input to read (raw file data)
 @param error Occuring errors. Suppy NULL if you're not interested in any errors
 @returns the initalized instance
 */
- (id)initWithData:(NSData *)data error:(NSError **)error;
/**
 @returns the data with the header data removed.
 */
- (NSData *)dataWithoutHeader;
/**
 Writes the data to the header
 */
- (void)writeHeaderData:(NSMutableData *)data;

@end
