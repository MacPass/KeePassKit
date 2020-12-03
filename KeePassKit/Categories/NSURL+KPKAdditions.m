//
//  NSURL+KPKAdditions.m
//  KeePassKit
//
//  Created by Michael Starke on 03.12.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import "NSURL+KPKAdditions.h"

@implementation NSURL (KPKAdditions)

+ (instancetype)URLWithTimeOTPKey:(NSString *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer period:(NSUInteger)perid digits:(NSUInteger)digits {
  return nil;
}

+ (instancetype)URLWithHmacOTPKey:(NSString *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer counter:(NSUInteger)counter digits:(NSUInteger)digits {
  return nil;
}

- (KPKOTPGeneratorType)type {
  NSString *type = self.host;
  if(!type) {
    return KPKOTPGeneratorTypeInvalid;
  }
  if([type isEqualToString:@"totp"]) {
    return KPKOTPGeneratorTOTP;
  }
  if([type isEqualToString:@"hotp"]) {
    return KPKOTPGeneratorHmacOTP;
  }
  return KPKOTPGeneratorTypeInvalid;
}

- (NSData *)key {
  NSString *query = self.query;
  return NSData.data;
}

@end
