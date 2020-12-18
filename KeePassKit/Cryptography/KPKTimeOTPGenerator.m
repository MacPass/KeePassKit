//
//  KPKTimeOTPGenerator.m
//  KeePassKit
//
//  Created by Michael Starke on 03.12.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTimeOTPGenerator.h"
#import "KPKOTPGenerator_Private.h"
#import "NSURL+KPKAdditions.h"
#import "NSString+KPKHexdata.h"
#import "NSData+KPKBase32.h"
#import "KPKAttribute.h"
#import "KPKEntry.h"

@implementation KPKTimeOTPGenerator

- (instancetype)init {
  self = [super _init];
  if(self) {
    _timeBase = 0;
    _timeSlice = 30;
    _time = 0;
  }
  return self;
}

- (instancetype)initWithEntry:(KPKEntry *)entry {
  self = [self init];
  if(self) {
    if(![self _parseEntryAttributes:entry]) {
      self = nil;
    }
  }
  return self;
}

- (void)saveToEntry:(KPKEntry *)entry {
  /**
   strategy ist to add a otp attribute regardless of the current state
   update KeeOTP settings if any where present
   update or add KeePass native settings regardless of current state
   
   This leads to entries having at least the otp and the native settings and optionally the KeeOTP settings as well
   */
  
  NSString *urlString = [NSURL URLWithTimeOTPKey:self.key algorithm:self.hashAlgorithm issuer:[self _issuerForEntry:entry] period:self.timeSlice digits:self.numberOfDigits].absoluteString;
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
    settingsAttribute.value = [NSString stringWithFormat:@"%ld:%ld", self.timeSlice, self.numberOfDigits];
    seedAttribute.value = self.key.base32EncodedString;
  }
  else {
    [entry removeCustomAttribute:settingsAttribute];
    [entry removeCustomAttribute:seedAttribute];
  }
  
  KPKAttribute *secretAsciiAttribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSecret];
  KPKAttribute *secretHexAttribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSecretHex];
  KPKAttribute *secretBase32Attribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSecretBase32];
  KPKAttribute *secretBase64Attribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSecretBase64];
  KPKAttribute *lengthAttr = [entry attributeWithKey:kKPKAttributeKeyTimeOTPLength];
  KPKAttribute *periodAttr = [entry attributeWithKey:kKPKAttributeKeyTimeOTPPeriod];
  KPKAttribute *algortihmAttr = [entry attributeWithKey:kKPKAttributeKeyTimeOTPAlgorithm];
  
  BOOL secretStored = NO;
  if(secretAsciiAttribute) {
    secretAsciiAttribute.value = [[NSString alloc] initWithData:self.key encoding:NSUTF8StringEncoding];
    secretStored = YES;
  }
  if(secretHexAttribute) {
    if(secretStored) {
      [entry removeCustomAttribute:secretHexAttribute];
    }
    else {
      secretHexAttribute.value = [NSString kpk_hexstringFromData:self.key];
      secretStored = YES;
    }
  }
  if(secretBase32Attribute) {
    if(secretStored) {
      [entry removeCustomAttribute:secretHexAttribute];
    }
    else {
      secretHexAttribute.value = [NSString kpk_hexstringFromData:self.key];
      secretStored = YES;
    }
  }
  if(secretBase64Attribute) {
    if(secretStored) {
      [entry removeCustomAttribute:secretHexAttribute];
    }
    else {
      secretHexAttribute.value = [NSString kpk_hexstringFromData:self.key];
      secretStored = YES;
    }
  }
  if(!secretStored) {
    secretBase32Attribute = [[KPKAttribute alloc] initWithKey:kKPKAttributeKeyHmacOTPSecretBase32 value:self.key.base32EncodedString];
    [entry addCustomAttribute:secretBase32Attribute];
    secretStored = YES;
  }
  
  if(!lengthAttr) {
    lengthAttr = [[KPKAttribute alloc] initWithKey:kKPKAttributeKeyTimeOTPLength value:[NSString stringWithFormat:@"%ld",self.numberOfDigits]];
  }
  if(!periodAttr) {
    periodAttr = [[KPKAttribute alloc] initWithKey:kKPKAttributeKeyTimeOTPPeriod value:[NSString stringWithFormat:@"%ld",self.timeSlice]];
  }
  
  if(!algortihmAttr) {
    // TODO: implement algorithm mapping
  }
  
}

- (NSUInteger)_counter {
  return floor((self.time - self.timeBase) / self.timeSlice);
}


- (NSTimeInterval)remainingTime {
  return self.timeSlice - ((NSUInteger)(self.time - self.timeBase) % self.timeSlice);
}

- (BOOL)_parseEntryAttributes:(KPKEntry *)entry {
  KPKAttribute *urlAttribute = [entry attributeWithKey:kKPKAttributeKeyOTPOAuthURL];
  
  if(urlAttribute) {
    NSURL *authURL = [NSURL URLWithString:urlAttribute.evaluatedValue];
    if(authURL && authURL.isTimeOTPURL) {
      if(authURL.digits > 0) {
        self.numberOfDigits = authURL.digits;
      }
      if(KPKOTPHashAlgorithmInvalid != authURL.hashAlgorithm) {
        self.hashAlgorithm = authURL.hashAlgorithm;
      }
      if(authURL.period > 0) {
        self.timeSlice = authURL.period;
      }
      if(authURL.key.length != 0) {
        self.key = authURL.key;
      }
      else {
        return NO; // key is mandatory!
      }
      return YES;
    }
  }
  
  /* TOTP Settings */
  
  KPKAttribute *seedAttribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSeed];
  
  if(seedAttribute) {
    NSString *base32seed = [seedAttribute.evaluatedValue stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    self.key = [NSData dataWithBase32EncodedString:base32seed];
    
    KPKAttribute *settingsAttribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSettings];
    if(settingsAttribute) {
      
      NSArray <NSString *> *parts = [settingsAttribute.evaluatedValue componentsSeparatedByString:@";"];
      self.timeSlice = parts.firstObject.integerValue;
      self.numberOfDigits = parts.lastObject.integerValue;
    }
    return YES;
  }
  
  KPKAttribute *asciiKeyAttribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSecret];
  KPKAttribute *hexKeyAttribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSecretHex];
  KPKAttribute *base32KeyAttribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSecretBase32];
  KPKAttribute *base64KeyAttribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSecretBase64];
  
  if(asciiKeyAttribute) {
    self.key = [asciiKeyAttribute.evaluatedValue dataUsingEncoding:NSUTF8StringEncoding];
  }
  else if(hexKeyAttribute) {
    self.key = hexKeyAttribute.evaluatedValue.kpk_dataFromHexString;
  }
  else if(base32KeyAttribute) {
    self.key = [NSData dataWithBase32EncodedString:base32KeyAttribute.evaluatedValue];
  }
  else if(base64KeyAttribute) {
    self.key = [[NSData alloc] initWithBase64EncodedString:base64KeyAttribute.evaluatedValue options:NSDataBase64DecodingIgnoreUnknownCharacters];
  }
  else {
    return NO; // no key
  }
  
  KPKAttribute *lengthAttribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPLength];
  if(lengthAttribute) {
    NSInteger length = lengthAttribute.evaluatedValue.integerValue;
    if(length > 0) {
      self.numberOfDigits = length;
    }
  }
  KPKAttribute *periodAttribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPPeriod];
  if(periodAttribute) {
    NSInteger period = periodAttribute.evaluatedValue.integerValue;
    if(period > 0) {
      self.timeSlice = period;
    }
  }
  KPKAttribute *algorithmAttribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPAlgorithm];
  if(algorithmAttribute) {
    KPKOTPHashAlgorithm algorithm = [KPKOTPGenerator algorithmForString:algorithmAttribute.evaluatedValue];
    if(algorithm != KPKOTPHashAlgorithmInvalid) {
      self.hashAlgorithm = algorithm;
    }
  }
  
  return YES;
}

@end
