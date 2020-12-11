//
//  KPKSteamOTPGenerator.m
//  KeePassKit
//
//  Created by Michael Starke on 04.12.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import "KPKSteamOTPGenerator.h"
#import "KPKOTPGenerator_Private.h"


#import "KPKAttribute.h"
#import "KPKEntry.h"

#import "NSData+KPKBase32.h"

@implementation KPKSteamOTPGenerator

- (NSString *)_alphabet {
  return @"23456789BCDFGHJKMNPQRTVWXY";
}

- (instancetype)initWithEntry:(KPKEntry *)entry {
  self = [self init];
  if(self) {
    
  }
  return self;
}

- (BOOL)_parseEntryAttributes:(KPKEntry *)entry {
  KPKAttribute *settingsAttribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSettings];
  KPKAttribute *seedAttribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSeed];
  
  if(settingsAttribute && seedAttribute) {
    NSString *base32seed = [seedAttribute.evaluatedValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    self.key = [NSData dataWithBase32EncodedString:base32seed];
    NSArray <NSString *> *parts = [settingsAttribute.evaluatedValue componentsSeparatedByString:@";"];
    self.timeSlice = parts.firstObject.integerValue;
    self.numberOfDigits = parts.lastObject.integerValue;
    return YES;
  }
  return NO;
}

@end
