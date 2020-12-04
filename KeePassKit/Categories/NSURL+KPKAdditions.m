//
//  NSURL+KPKAdditions.m
//  KeePassKit
//
//  Created by Michael Starke on 03.12.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import "NSURL+KPKAdditions.h"

NSString *const kKPKURLTypeHmacOTP        = @"hotp";
NSString *const kKPKURLTypeTimeOTP        = @"totp";
NSString *const kKPKURLParameterSecret    = @"secret";
NSString *const kKPKURLParameterAlgorithm = @"algorithm";
NSString *const kKPKURLParameterDigits    = @"digits";
NSString *const kKPKURLParameterIssuer    = @"issuer";
NSString *const kKPKURLParameterPeriod    = @"period";
NSString *const kKPKURLParameterCounter   = @"counter";

@implementation NSURL (KPKAdditions)

+ (instancetype)URLWithTimeOTPKey:(NSString *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer period:(NSUInteger)perid digits:(NSUInteger)digits {
  return nil;
}

+ (instancetype)URLWithHmacOTPKey:(NSString *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer counter:(NSUInteger)counter digits:(NSUInteger)digits {
  return nil;
}

- (NSData *)key {
  NSString *query = self.query;
  NSURLComponents *components = [[NSURLComponents alloc] initWithURL:self resolvingAgainstBaseURL:NO];
  for(NSURLQueryItem *queryItem in components.queryItems) {
    if([queryItem.name compare:kKPKURLParameterSecret options:NSCaseInsensitiveSearch]) {
      return queryItem.value;
    }
  }
  return nil;
}

- (BOOL)isHmacOTPURL {
  return [self.host compare:kKPKURLTypeHmacOTP options:NSCaseInsensitiveSearch];
}

- (BOOL)isTimeOTPURL {
  return [self.host compare:kKPKURLTypeTimeOTP options:NSCaseInsensitiveSearch];
}

@end
