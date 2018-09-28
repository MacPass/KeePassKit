//
//  NSDate+Packed.h
//  MacPass
//
//  Created by Michael Starke on 25.06.13.
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

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (KPKPacked)
+ (NSDate * _Nullable)kpk_dateFromPackedBytes:(const uint8_t *)buffer;
+ (NSData *)kpk_packedBytesFromDate:(NSDate * _Nullable)date;
+ (void)kpk_getPackedBytes:(uint8_t *)buffer fromDate:(NSDate * _Nullable)date;

@property (copy, readonly) NSData *kpk_packedBytes;

@end

@interface NSDate (KPKDateFormat)

+ (NSDate * _Nullable)kpk_dateFromUTCString:(NSString *)string;

@property (nonatomic, readonly) NSString *kpk_UTCString;

@end

@interface NSDate (KPKPrecision)

@property (copy, readonly) NSDate *kpk_dateWithReducedPrecsion;

@end

NS_ASSUME_NONNULL_END
