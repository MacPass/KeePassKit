//
//  NSURL+KPKAdditions.m
//  KeePassKit
//
//  Created by Michael Starke on 03.12.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import "NSURL+KPKAdditions.h"
#import "KPKOTPGenerator.h"
#import "NSData+KPKBase32.h"

NSString *const kKPKURLOtpAuthScheme      = @"otpauth";
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
  return [[NSURL alloc] initWithTimeOTPKey:key algorithm:algorithm issuer:issuer period:perid digits:digits];
}

+ (instancetype)URLWithHmacOTPKey:(NSString *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer counter:(NSUInteger)counter digits:(NSUInteger)digits {
  return [[NSURL alloc] initWithHmacOTPKey:key algorithm:algorithm issuer:issuer counter:counter digits:digits];
}

+ (NSDictionary<NSValue *, NSString *>*)_algorithmMap {
  static NSDictionary <NSNumber *, NSString *> *map;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = @{ @(KPKOTPHashAlgorithmSha1) : @"sha1",
             @(KPKOTPHashAlgorithmSha256) : @"sha256",
             @(KPKOTPHashAlgorithmSha512) : @"sha512" };
  });
  return map;
}

+ (NSDictionary<NSString *, NSNumber *>*)_algrithmIdentfierMap {
  static NSDictionary <NSString *, NSNumber *> *map;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = @{ @"sha1" : @(KPKOTPHashAlgorithmSha1) ,
             @"sha256" : @(KPKOTPHashAlgorithmSha256),
             @"sha512" : @(KPKOTPHashAlgorithmSha512) };
  });
  return map;
}

- (instancetype)initWithHmacOTPKey:(NSString *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer counter:(NSUInteger)counter digits:(NSUInteger)digits {
  self = [self init];
  NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
  /* otpauth://hotp/ */
  urlComponents.scheme = kKPKURLOtpAuthScheme;
  urlComponents.host = kKPKURLTypeHmacOTP;
  NSMutableArray<NSURLQueryItem *>* queryItems;
  
  /* algorithm */
  NSString *algorithmString = [NSURL _algorithmMap][@(algorithm)];
  if(algorithmString) {
    NSURLQueryItem *algorithmQueueItem = [[NSURLQueryItem alloc] initWithName:kKPKURLParameterAlgorithm value:algorithmString];
    [queryItems addObject:algorithmQueueItem];
  }
  
  /* issuer */
  if(issuer.length > 0) {
    NSURLQueryItem *issuerQueueItem = [[NSURLQueryItem alloc] initWithName:kKPKURLParameterIssuer value:issuer];
    [queryItems addObject:issuerQueueItem];
  }
  
  /* counter */
  NSURLQueryItem *counterQueueItem = [[NSURLQueryItem alloc] initWithName:kKPKURLParameterCounter value:[NSString stringWithFormat:@"%ld", counter]];
  [queryItems addObject:counterQueueItem];
  
  /* digits */
  NSURLQueryItem *digitsItem = [[NSURLQueryItem alloc] initWithName:kKPKURLParameterDigits value:[NSString stringWithFormat:@"%ld", digits]];
  [queryItems addObject:digitsItem];
  
  urlComponents.queryItems = queryItems;
  if(urlComponents.URL) {
    self = urlComponents.URL;
  }
  return self;
}

- (instancetype)initWithTimeOTPKey:(NSString *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer period:(NSUInteger)period digits:(NSUInteger)digits {
  self = [self init];
  NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
  /* otpauth://hotp/ */
  urlComponents.scheme = kKPKURLOtpAuthScheme;
  urlComponents.host = kKPKURLTypeTimeOTP;
  NSMutableArray<NSURLQueryItem *>* queryItems;
  
  /* algorithm */
  NSString *algorithmString = [NSURL _algorithmMap][@(algorithm)];
  if(algorithmString) {
    NSURLQueryItem *algorithmQueueItem = [[NSURLQueryItem alloc] initWithName:kKPKURLParameterAlgorithm value:algorithmString];
    [queryItems addObject:algorithmQueueItem];
  }
  
  /* issuer */
  if(issuer.length > 0) {
    NSURLQueryItem *issuerQueueItem = [[NSURLQueryItem alloc] initWithName:kKPKURLParameterIssuer value:issuer];
    [queryItems addObject:issuerQueueItem];
  }
  
  /* period */
  NSURLQueryItem *periodQueueItem = [[NSURLQueryItem alloc] initWithName:kKPKURLParameterPeriod value:[NSString stringWithFormat:@"%ld", period]];
  [queryItems addObject:periodQueueItem];
  
  /* digits */
  NSURLQueryItem *digitsItem = [[NSURLQueryItem alloc] initWithName:kKPKURLParameterDigits value:[NSString stringWithFormat:@"%ld", period]];
  [queryItems addObject:digitsItem];
  
  urlComponents.queryItems = queryItems;
  if(urlComponents.URL) {
    self = urlComponents.URL;
  }
  return self;
}


- (NSData *)key {
  NSString *keyValue = [self _queryItemValueForKey:kKPKURLParameterSecret];
  if(keyValue) {
    return [NSData dataWithBase32EncodedString:keyValue];
  }
  return nil;
}

- (KPKOTPHashAlgorithm)hashAlgorithm {
  NSString *hashValue = [self _queryItemValueForKey:kKPKURLParameterAlgorithm];
  NSNumber *hashNumber = [NSURL _algrithmIdentfierMap][hashValue];
  if(hashNumber) {
    return (KPKOTPHashAlgorithm)hashNumber.integerValue;
  }
  return KPKOTPHashAlgorithmSha1;
}

- (NSUInteger)digits {
  NSString *keyValue = [self _queryItemValueForKey:kKPKURLParameterDigits];
  return keyValue.integerValue;
}

- (NSUInteger)period {
  NSString *periodValue = [self _queryItemValueForKey:kKPKURLParameterPeriod];
  return periodValue.integerValue;
}

- (NSUInteger)counter {
  NSString *keyValue = [self _queryItemValueForKey:kKPKURLParameterCounter];
  return keyValue.integerValue;
}

- (BOOL)isHmacOTPURL {
  if(NSOrderedSame != [self.scheme compare:kKPKURLOtpAuthScheme options:NSCaseInsensitiveSearch]) {
    return NO;
  }
  return (NSOrderedSame == [self.host compare:kKPKURLTypeHmacOTP options:NSCaseInsensitiveSearch]);
}

- (BOOL)isTimeOTPURL {
  if(NSOrderedSame != [self.scheme compare:kKPKURLOtpAuthScheme options:NSCaseInsensitiveSearch]) {
    return NO;
  }
  return (NSOrderedSame == [self.host compare:kKPKURLTypeTimeOTP options:NSCaseInsensitiveSearch]);
}

- (NSString *)_queryItemValueForKey:(NSString *)key {
  NSURLComponents *components = [[NSURLComponents alloc] initWithURL:self resolvingAgainstBaseURL:NO];
  for(NSURLQueryItem *queryItem in components.queryItems) {
    if(NSOrderedSame == [queryItem.name compare:key options:NSCaseInsensitiveSearch]) {
      return queryItem.value;
    }
  }
  return @"";
}

@end
