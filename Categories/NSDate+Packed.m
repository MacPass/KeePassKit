//
//  NSDate+Packed.m
//  MacPass
//
//  Created by Michael Starke on 25.06.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "NSDate+Packed.h"

@implementation NSDate (Packed)

+ (NSDate *)dateFromPackedBytes:(uint8_t *)buffer {
  uint32_t dw1, dw2, dw3, dw4, dw5;
  dw1 = (uint32_t)buffer[0]; dw2 = (uint32_t)buffer[1]; dw3 = (uint32_t)buffer[2];
  dw4 = (uint32_t)buffer[3]; dw5 = (uint32_t)buffer[4];
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
  [dateComponents setYear:y];
  [dateComponents setMonth:mon];
  [dateComponents setDay:d];
  [dateComponents setHour:h];
  [dateComponents setMinute:min];
  [dateComponents setSecond:s];
  
  NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSDate *date = [calendar dateFromComponents:dateComponents];
  
  return date;
}

+ (void)getPackedBytes:(uint8_t *)buffer fromDate:(NSDate *)date {
  NSData *data = [self packedBytesFromDate:date];
  [data getBytes:buffer length:[data length]];
}

+ (NSData *)packedBytesFromDate:(NSDate *)date {
  
  uint32_t year;
  uint32_t month;
  uint32_t days;
  uint32_t hours;
  uint32_t minutes;
  uint32_t seconds;
  
  if(date) {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSUInteger calendarComponents = (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit);
    NSDateComponents *dateComponents = [calendar components:calendarComponents fromDate:date];
    
    year = (uint32_t)[dateComponents year];
    month = (uint32_t)[dateComponents month];
    days = (uint32_t)[dateComponents day];
    hours = (uint32_t)[dateComponents hour];
    minutes = (uint32_t)[dateComponents minute];
    seconds = (uint32_t)[dateComponents second];
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

@end
