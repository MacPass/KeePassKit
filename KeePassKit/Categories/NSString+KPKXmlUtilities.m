//
//  NSString+SafeXML.m
//  MacPass
//
//  Created by Michael Starke on 15/12/14.
//  Copyright (c) 2014 HicknHack Software GmbH. All rights reserved.
//

#import "NSString+KPKXmlUtilities.h"

@implementation NSString (KPKXmlUtilities)

/*
 Removes all characters that are not valid XML characters,
 according to http://www.w3.org/TR/xml/#charsets .
 
 Based heavily on SafeXmlString(string strText) from StrUtil.cs of KeePass
 */
- (NSString *)kpk_xmlCompatibleString {
  const NSUInteger length = self.length;
  if(length == 0) {
    return nil;
  }
  unichar *safeCharaters = malloc(length * sizeof(unichar));
  NSInteger safeIndex = 0;
  for(NSInteger index = 0; index < length; ++index) {
    unichar character = [self characterAtIndex:index];
    
    if(((character >= 0x20) && (character <= 0xD7FF )) ||
       (character == 0x9) || (character == 0xA) || (character == 0xD) ||
       ((character >= 0xE000) && (character <= 0xFFFD))) {
      
      safeCharaters[safeIndex++] = character;
    }
    else if( (character >= 0xD800) && (character <= 0xDBFF) ) { // High surrogate
      if((index + 1) < length) {
        unichar lowCharacter = [self characterAtIndex:index+1];
        if((lowCharacter >= 0xDC00) && (lowCharacter <= 0xDFFF)) // Low sur.
        {
          safeCharaters[safeIndex++] = character;
          safeCharaters[safeIndex++] = lowCharacter;
          ++index;
        }
        else {
          NSAssert(NO, @"Lower Surrogate invalid!");
        }
      }
      else {
        NSAssert(NO, @"Lower Surrogate missing!");
      }
    }
  }
  NSString *safeString = [[NSString alloc] initWithCharactersNoCopy:safeCharaters length:safeIndex freeWhenDone:YES];
  return safeString;
}

@end
