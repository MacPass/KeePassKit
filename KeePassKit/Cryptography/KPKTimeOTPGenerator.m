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
      return self;
    }
  }
  return self;
}

- (NSUInteger)_counter {
  return floor((self.time - self.timeBase) / self.timeSlice);
}


- (NSTimeInterval)remainingTime {
  return ((NSInteger)(self.time - self.timeBase) % self.timeSlice);
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
    }
  }
  
  /* TOTP Settings */

  KPKAttribute *settingsAttribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSettings];
  KPKAttribute *seedAttribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSeed];

  KPKAttribute *secretUTFAttribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSecret];
  KPKAttribute *secretHexAttribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSecretHex];
  KPKAttribute *secretBase32Attribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSecretBase32];
  KPKAttribute *secretBase64Attribute = [entry attributeWithKey:kKPKAttributeKeyTimeOTPSecretBase64];

  return YES;
}

@end
