//
//  NSDate+Packed.h
//  MacPass
//
//  Created by Michael Starke on 25.06.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Packed)

+ (NSDate *)dateFromPackedBytes:(uint8_t *)buffer;
+ (NSData *)packedBytesFromDate:(NSDate *)date;
+ (void)getPackedBytes:(uint8_t *)buffer fromDate:(NSDate *)date;

@end
