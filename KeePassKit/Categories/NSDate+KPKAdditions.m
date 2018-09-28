//
//  NSDate+Packed.m
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

#import "NSDate+KPKAdditions.h"
#import <time.h>

static NSCalendar *_gregorianCalendar(void) {
  static NSCalendar *_kpkCalendar;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _kpkCalendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
  });
  return _kpkCalendar;
}

@implementation NSDate (KPKAdditions)

+ (NSDate *)kpk_dateFromPackedBytes:(const uint8_t *)buffer {
  uint32_t dw1 = (uint32_t)buffer[0];
  uint32_t dw2 = (uint32_t)buffer[1];
  uint32_t dw3 = (uint32_t)buffer[2];
  uint32_t dw4 = (uint32_t)buffer[3];
  uint32_t dw5 = (uint32_t)buffer[4];
  int y = (dw1 << 6) | (dw2 >> 2);
  int mon = ((dw2 & 0x00000003) << 2) | (dw3 >> 6);
  int d = (dw3 >> 1) & 0x0000001F;
  int h = ((dw3 & 0x00000001) << 4) | (dw4 >> 4);
  int min = ((dw4 & 0x0000000F) << 2) | (dw5 >> 6);
  int s = dw5 & 0x0000003F;
  
  if (y == 2999 && mon == 12 && d == 28 && h == 23 && min == 59 && s == 59) {
    return nil;
  }
  
  NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
  dateComponents.year = y;
  dateComponents.month = mon;
  dateComponents.day = d;
  dateComponents.hour = h;
  dateComponents.minute = min;
  dateComponents.second = s;
  
  NSDate *date = [_gregorianCalendar() dateFromComponents:dateComponents];
  
  return date;
}

+ (void)kpk_getPackedBytes:(uint8_t *)buffer fromDate:(NSDate *)date {
  NSData *data = [self kpk_packedBytesFromDate:date];
  [data getBytes:buffer length:data.length];
}

+ (NSData *)kpk_packedBytesFromDate:(NSDate *)date {
  
  uint32_t year;
  uint32_t month;
  uint32_t days;
  uint32_t hours;
  uint32_t minutes;
  uint32_t seconds;
  
  if(date) {
    static NSUInteger calendarComponents = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond);
    NSDateComponents *dateComponents = [_gregorianCalendar() components:calendarComponents fromDate:date];
    
    year = (uint32_t)dateComponents.year;
    month = (uint32_t)dateComponents.month;
    days = (uint32_t)dateComponents.day;
    hours = (uint32_t)dateComponents.hour;
    minutes = (uint32_t)dateComponents.minute;
    seconds = (uint32_t)dateComponents.second;
  }
  else {
    year = 2999;
    month = 12;
    days = 28;
    hours = 23;
    minutes = 59;
    seconds = 59;
  }
  uint8_t byteBuffer[5];
  byteBuffer[0] = (uint8_t)((year >> 6) & 0x0000003F);
  byteBuffer[1] = (uint8_t)(((year & 0x0000003F) << 2) | ((month >> 2) & 0x00000003));
  byteBuffer[2] = (uint8_t)(((month & 0x00000003) << 6) | ((days & 0x0000001F) << 1) | ((hours >> 4) & 0x00000001));
  byteBuffer[3] = (uint8_t)(((hours & 0x0000000F) << 4) | ((minutes >> 2) & 0x0000000F));
  byteBuffer[4] = (uint8_t)(((minutes & 0x00000003) << 6) | (seconds & 0x0000003F));
  
  return [NSData dataWithBytes:byteBuffer length:sizeof(byteBuffer)];
}

- (NSData *)kpk_packedBytes {
  return [NSDate kpk_packedBytesFromDate:self];
}

@end

@implementation NSDate (KPKDateFormat)


+ (NSDate *)kpk_dateFromUTCString:(NSString *)string {
  if(nil == string) {
    return nil;
  }
  /* fallback to a reference date for empty strings */
  if(string.length == 0) {
    static NSDate *referenceDate;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      referenceDate = [NSDate dateWithTimeIntervalSinceReferenceDate:0];
    });
    return referenceDate;
  }
/*
 The call to timegm on iOS is even slower than using a date formatter,
 on macOS using C functions yields much faster times
 */
#ifdef KPK_MAC

  struct tm time;
  __unused char *result = strptime([string cStringUsingEncoding:NSUTF8StringEncoding], "%Y-%m-%dT%H:%M:%SZ", &time);
  NSAssert(result != NULL, @"Internal inconsitency. Unable to parse date format!");
  time.tm_isdst = 0;
  time.tm_gmtoff = 0;
  time.tm_zone = "UTC";
  time_t t = timegm(&time);
  return [NSDate dateWithTimeIntervalSince1970:t];

#else

  NSDateComponents *components = [[NSDateComponents alloc] init];
  NSUInteger year, month, day, hour, minute, second;
  sscanf([string cStringUsingEncoding:NSUTF8StringEncoding], "%ld-%ld-%ldT%ld:%ld:%ldZ", &year, &month, &day, &hour, &minute, &second);
  components.year = year;
  components.month = month;
  components.day = day;
  components.hour = hour;
  components.minute = minute;
  components.second = second;
  components.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
  components.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];

  return components.date;

#endif
}

- (NSString *)kpk_UTCString {
  struct tm *timeinfo;
  char buffer[80];
  
  time_t rawtime = self.timeIntervalSince1970;
  timeinfo = gmtime(&rawtime);
  
  strftime(buffer, 80, "%Y-%m-%dT%H:%M:%SZ", timeinfo);
  
  return [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
}

@end

@implementation NSDate (KPKPrecision)

- (NSDate *)kpk_dateWithReducedPrecsion {
  return [NSDate dateWithTimeIntervalSinceReferenceDate:floor(self.timeIntervalSinceReferenceDate)];
}

@end
