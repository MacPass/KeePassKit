//
//  KPKBinaryCipherInformation.h
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

@interface KPKLegacyHeaderReader : NSObject <KPKHeaderReading, KPKHeaderWriting>

@property (nonatomic, readonly, strong) NSUUID *cipherUUID;

@property (nonatomic, readonly, strong) NSData *masterSeed;
@property (nonatomic, readonly, strong) NSData *transformSeed;
@property (nonatomic, readonly, strong) NSData *encryptionIV;

@property (nonatomic, readonly, assign) uint64_t rounds;

@property (nonatomic, readonly, strong) NSData *contentsHash;
@property (nonatomic, readonly, strong) NSData *headerHash;

@property (nonatomic, readonly) NSUInteger numberOfEntries;
@property (nonatomic, readonly) NSUInteger numberOfGroups;

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
