//
//  KPKHeaderReading.h
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

@import Foundation;

@protocol KPKHeaderReading <NSObject>

@required
@property (nonatomic, readonly, strong) NSUUID *cipherUUID;

@property (nonatomic, readonly, copy) NSUUID *keyDerivationUUID;
@property (nonatomic, readonly, copy) NSDictionary *keyDerivationOptions; // contains rounds for aes

@property (nonatomic, readonly, strong) NSData *masterSeed;
@property (nonatomic, readonly, strong) NSData *transformSeed;
@property (nonatomic, readonly, strong) NSData *encryptionIV;
@property (nonatomic, readonly, strong) NSData *protectedStreamKey;
@property (nonatomic, readonly, strong) NSData *streamStartBytes;

@property (nonatomic, readonly, assign) uint32_t compressionAlgorithm; // KPKCompression
@property (nonatomic, readonly, assign) uint32_t randomStreamID;
//@property (nonatomic, readonly, assign) uint64_t rounds;

@property (nonatomic, readonly, strong) NSData *contentsHash;
@property (nonatomic, readonly, strong) NSData *headerHash;

@optional
@property (nonatomic, readonly) NSUInteger numberOfEntries;
@property (nonatomic, readonly) NSUInteger numberOfGroups;

- (instancetype)initWithData:(NSData *)data error:(NSError **)error;
/**
 @returns the data with the header data removed.
 */
@property (nonatomic, readonly, copy) NSData *dataWithoutHeader;

@end
