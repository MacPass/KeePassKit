//
//  KPKLegacyHeaderWriter.h
//  KeePassKit
//
//  Created by Michael Starke on 08.08.13.
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
#import "KPKHeaderWriting.h"

@interface KPKLegacyHeaderWriter : NSObject <KPKHeaderWriting>

@property (nonatomic, strong, readonly) NSData *masterSeed;
@property (nonatomic, strong, readonly) NSData *encryptionIv;
@property (nonatomic, strong, readonly) NSData *transformSeed;
@property (nonatomic, readonly) uint32_t transformationRounds;
@property (nonatomic, assign) NSUInteger groupCount;
@property (nonatomic, assign) NSUInteger entryCount;

#pragma mark KPKHeaderWriting
- (instancetype)initWithTree:(KPKTree *)tree;
- (void)writeHeaderData:(NSMutableData *)data;

- (void)setContentHash:(NSData *)hash;
@property (nonatomic, readonly, copy) NSData *headerHash;

@end
