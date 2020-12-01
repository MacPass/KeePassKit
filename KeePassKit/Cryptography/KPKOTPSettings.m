//
//  KPKOTPSettings.m
//  KeePassKit
//
//  Created by Michael Starke on 01.12.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import "KPKOTPSettings.h"

@implementation KPKOTPSettings

- (NSString *)alphabet {
  switch (self.type) {
    case KPKOTPGeneratorHmacOTP:
    case KPKOTPGeneratorTOTP:
      return @"0123456789";
      
    case KPKOTPGeneratorSteamOTP:
      return @"23456789BCDFGHJKMNPQRTVWXY";
    default:
      return @"";
      break;
  }
}

- (instancetype)init {
  self = [super init];
  if(self) {
    _hashAlgorithm = KPKOTPHashAlgorithmSha1;
    _key = [NSData.data copy]; // use an empty key;
    _type = KPKOTPGeneratorHmacOTP;
    _timeBase = 0;
    _timeSlice = 30;
    _time = 0;
    _counter = 0;
    _numberOfDigits = 6;
  }
  return self;
}

@end
