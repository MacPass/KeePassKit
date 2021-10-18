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

#import "NSURL+KPKAdditions.h"
#import "NSData+KPKBase32.h"
#import "NSDictionary+KPKAttributes.h"

NSUInteger const KPKSteamOTPGeneratorDigits = 5;
NSString *const KPKSteamOTPGeneratorSettingsValue = @"S";

@implementation KPKSteamOTPGenerator

- (NSString *)_alphabet {
  return @"23456789BCDFGHJKMNPQRTVWXY";
}

- (instancetype)initWithEntry:(KPKEntry *)entry {
  self = [self init];
  if(self) {
    self.numberOfDigits = KPKSteamOTPGeneratorDigits;
  }
  return self;
}

- (NSUInteger)defaultNumberOfDigits {
  return KPKSteamOTPGeneratorDigits;
}

- (void)saveToEntry:(KPKEntry *)entry {
  /**
   KeePassXC uses a custom otpauth url so we use this first.
   Additionally we update any KeeTrayOTP settings
   */
  
  NSString *urlString = [NSURL URLWIthSteamOTPKey:self.key issuer:[self _issuerForEntry:entry]].absoluteString;
  KPKAttribute *urlAttribute = [entry attributeWithKey:kKPKAttributeKeyOTPOAuthURL];
  /* update or create the URL attribute */
  if(!urlAttribute) {
    urlAttribute = [[KPKAttribute alloc] initWithKey:kKPKAttributeKeyOTPOAuthURL value:urlString];
    [entry addCustomAttribute:urlAttribute];
  }
  else {
    urlAttribute.value = urlString;
  }
  
  KPKAttribute *settingsAttribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSettings];
  KPKAttribute *seedAttribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSeed];
  if(settingsAttribute) {
    settingsAttribute.value = [NSString stringWithFormat:@"%ld;%@", self.timeSlice, KPKSteamOTPGeneratorSettingsValue];
    seedAttribute.value = [self.key base32EncodedStringWithOptions:0];
  }
  else {
    [entry removeCustomAttribute:settingsAttribute];
    [entry removeCustomAttribute:seedAttribute];
  }
  
  /* clear out all other TOTP settings since they are conflicting */
  NSArray *otherAttributes = @[ kKPKAttributeKeyTimeOTPSecret,
                                kKPKAttributeKeyTimeOTPSecretHex,
                                kKPKAttributeKeyTimeOTPSecretBase32,
                                kKPKAttributeKeyTimeOTPSecretBase64,
                                kKPKAttributeKeyTimeOTPLength,
                                kKPKAttributeKeyTimeOTPPeriod,
                                kKPKAttributeKeyTimeOTPAlgorithm ];
  for(NSString *attributeKey in otherAttributes) {
    [entry removeCustomAttribute:[entry attributeWithKey:attributeKey]];
  }
}

- (BOOL)_parseAttributes:(NSArray<KPKAttribute *>*)attributes {
  
  /* use dict for simpler lookup! */
  NSDictionary *attributesDict = [NSDictionary dictionaryWithAttributes:attributes];
  
  KPKAttribute *urlAttribute = attributesDict[kKPKAttributeKeyOTPOAuthURL];
  
  if(urlAttribute) {
    NSURL *authURL = [NSURL URLWithString:urlAttribute.evaluatedValue];
    /* only parse the URL if it's correct, otherwise try fallback to other attributes */
    if(authURL && authURL.isTimeOTPURL) {
      return [self _parseURL:authURL];
    }
  }
  
  /* TOTP Settings */
  
  KPKAttribute *seedAttribute = attributesDict[kKPKAttributeKeyTimeOTPSeed];
  
  if(seedAttribute) {
    NSString *base32seed = [seedAttribute.evaluatedValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    self.key = [NSData dataWithBase32EncodedString:base32seed];
    
    KPKAttribute *settingsAttribute = attributesDict[kKPKAttributeKeyTimeOTPSettings];
    if(settingsAttribute) {
      
      NSArray <NSString *> *parts = [settingsAttribute.evaluatedValue componentsSeparatedByString:@";"];
      self.timeSlice = parts.firstObject.integerValue;
      NSString *numberOfDigits = parts[1];
      if(NSOrderedSame != [numberOfDigits compare:KPKSteamOTPGeneratorSettingsValue options:NSCaseInsensitiveSearch]) {
        return NO; // invalid special key for Stream
      }
    }
    return YES;
  }
  return NO;
}

- (BOOL)_parseURL:(NSURL *)authURL {
  if(!(authURL && authURL.isTimeOTPURL)) {
    return NO;
  }
  
  if([authURL.encoder.lowercaseString isEqualToString:kKPKURLSteamEncoderValue]) {
    return NO; // invalid encoder!
  }
  
  if(authURL.key.length != 0) {
    self.key = authURL.key;
  }
  
  /* FIXME: we should not need to parse this since Steam requires fixed settings */
  
  if(authURL.digits > 0) {
    self.numberOfDigits = authURL.digits;
  }
  if(KPKOTPHashAlgorithmInvalid != authURL.hashAlgorithm) {
    self.hashAlgorithm = authURL.hashAlgorithm;
  }
  if(authURL.period > 0) {
    self.timeSlice = authURL.period;
  }
  return YES;
}

@end
