//
//  KPKLegacyHeaderUtility.h
//  MacPass
//
//  Created by Michael Starke on 18.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPKLegacyFormat.h"

@interface KPKLegacyHeaderUtility : NSObject

/**
 *	Generates hashing data to be used while reading and writing legacy files.
 *	@param	header	Pointer to the header data strucutre
 *	@return	NSData containing the header hash;
 */
+ (NSData *)hashForHeader:(KPKLegacyHeader *)header;

@end
