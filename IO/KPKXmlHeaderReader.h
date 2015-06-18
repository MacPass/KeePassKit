//
//  KPKChipherInformation.h
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

#import <Foundation/Foundation.h>
#import "KPKHeaderReading.h"
#import "KPKHeaderWriting.h"

@interface KPKXmlHeaderReader : NSObject <KPKHeaderReading>

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
 Verifies the integrity of the header
 @param hash The checksum hash the header shoudl verify again
 @returns YES if the check succeeded, NO otherwise
 */
- (BOOL)verifyHeader:(NSData *)hash;

@end
