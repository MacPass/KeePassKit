//
//  NSData+Compression.h
//  MacPass
//
//  Created by Michael Starke on 05.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//
//  Methods extracted from source given at
//  http://www.cocoadev.com/index.pl?NSDataCategory
//

#import <Foundation/NSData.h>

@interface NSData (Gzip)

#pragma mark -
#pragma mark Gzip Compression routines
/*
 Returns a data object containing a Gzip decompressed copy of the receivers contents.
 */
- (NSData *) gzipInflate;
/*
 Returns a data object containing a Gzip compressed copy of the receivers contents.
 */
- (NSData *) gzipDeflate;

@end
