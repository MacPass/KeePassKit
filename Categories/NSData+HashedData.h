//
//  NSData+HashedData.h
//  MacPass
//
//  Created by Michael Starke on 21.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Extension to handle blocked hashed data.
 */
@interface NSData (HashedData)

/**
 @returns YES, if the hashed data's integritry was verified, NO if the hash is corrupted
 */
- (NSData *)unhashedData;
/**
 @returns The data hashed in a blockstream.
 */
- (NSData *)hashedData;

@end
