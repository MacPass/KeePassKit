//
//  NSURL+KPKAdditions.m
//  KeePassKit
//
//  Created by Michael Starke on 03.12.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import "NSURL+KPKAdditions.h"

#import "KPKOTPGenerator.h"
#import "KPKSteamOTPGenerator.h"

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
NSString *const kKPKURLParameterEncoder   = @"encoder";

NSString *const kKPKURLSteamEncoderValue  = @"steam";

@implementation NSURL (KPKAdditions)

+ (instancetype)URLWithTimeOTPKey:(NSData *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer period:(NSUInteger)perid digits:(NSUInteger)digits {
  return [[NSURL alloc] initWithTimeOTPKey:key algorithm:algorithm issuer:issuer period:perid digits:digits];
}

+ (instancetype)URLWithHmacOTPKey:(NSData *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer counter:(NSUInteger)counter digits:(NSUInteger)digits {
  return [[NSURL alloc] initWithHmacOTPKey:key algorithm:algorithm issuer:issuer counter:counter digits:digits];
}

+ (instancetype)URLWIthSteamOTPKey:(NSData *)key issuer:(NSString *)issuer {
  return [[NSURL alloc] initWithSteamOTPKey:key issuer:issuer];
}


- (instancetype)initWithHmacOTPKey:(NSData *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer counter:(NSUInteger)counter digits:(NSUInteger)digits {
  NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
  /* otpauth://hotp/ */
  urlComponents.scheme = kKPKURLOtpAuthScheme;
  urlComponents.host = kKPKURLTypeHmacOTP;
  NSMutableArray<NSURLQueryItem *>* queryItems = [[NSMutableArray alloc] init];
  
  /* algorithm */
  NSString *algorithmString = [KPKOTPGenerator stringForAlgorithm:algorithm];
  if(algorithmString.length > 0) {
    NSURLQueryItem *algorithmQueueItem = [[NSURLQueryItem alloc] initWithName:kKPKURLParameterAlgorithm value:algorithmString];
    [queryItems addObject:algorithmQueueItem];
  }
  
  /* issuer */
  if(issuer.length > 0) {
    NSURLQueryItem *issuerQueueItem = [[NSURLQueryItem alloc] initWithName:kKPKURLParameterIssuer value:issuer];
    [queryItems addObject:issuerQueueItem];
    urlComponents.path = [NSString stringWithFormat:@"/%@",issuer];
  }
  
  /* counter */
  NSURLQueryItem *counterQueueItem = [[NSURLQueryItem alloc] initWithName:kKPKURLParameterCounter value:[NSString stringWithFormat:@"%ld", counter]];
  [queryItems addObject:counterQueueItem];
  
  /* digits */
  NSURLQueryItem *digitsItem = [[NSURLQueryItem alloc] initWithName:kKPKURLParameterDigits value:[NSString stringWithFormat:@"%ld", digits]];
  [queryItems addObject:digitsItem];
  
  /* secret */
  NSString *base32secret = [key base32EncodedStringWithOptions:KPKBase32EncodingOptionNoPadding];
  NSURLQueryItem *secretItem = [[NSURLQueryItem alloc] initWithName:kKPKURLParameterSecret value:base32secret];
  [queryItems addObject:secretItem];
  
  urlComponents.queryItems = queryItems;
  if(urlComponents.string) {
    self = [self initWithString:urlComponents.string];
  }
  else {
    self = nil;
  }
  return self;
}

- (instancetype)initWithTimeOTPKey:(NSData *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer period:(NSUInteger)period digits:(NSUInteger)digits {
  NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
  /* otpauth://hotp/ */
  urlComponents.scheme = kKPKURLOtpAuthScheme;
  urlComponents.host = kKPKURLTypeTimeOTP;
  NSMutableArray<NSURLQueryItem *>* queryItems = [[NSMutableArray alloc] init];
  
  /* algorithm */
  NSString *algorithmString = [KPKOTPGenerator stringForAlgorithm:algorithm];
  if(algorithmString) {
    NSURLQueryItem *algorithmQueueItem = [[NSURLQueryItem alloc] initWithName:kKPKURLParameterAlgorithm value:algorithmString];
    [queryItems addObject:algorithmQueueItem];
  }
  
  /* issuer */
  if(issuer.length > 0) {
    NSURLQueryItem *issuerQueueItem = [[NSURLQueryItem alloc] initWithName:kKPKURLParameterIssuer value:issuer];
    [queryItems addObject:issuerQueueItem];
    urlComponents.path = [NSString stringWithFormat:@"/%@",issuer];
  }
  
  /* period */
  NSURLQueryItem *periodQueueItem = [[NSURLQueryItem alloc] initWithName:kKPKURLParameterPeriod value:[NSString stringWithFormat:@"%ld", period]];
  [queryItems addObject:periodQueueItem];
  
  /* digits */
  NSURLQueryItem *digitsItem = [[NSURLQueryItem alloc] initWithName:kKPKURLParameterDigits value:[NSString stringWithFormat:@"%ld", digits]];
  [queryItems addObject:digitsItem];
  
  /* secret */
  NSString *base32secret = [key base32EncodedStringWithOptions:KPKBase32EncodingOptionNoPadding];
  NSURLQueryItem *secretItem = [[NSURLQueryItem alloc] initWithName:kKPKURLParameterSecret value:base32secret];
  [queryItems addObject:secretItem];
  
  urlComponents.queryItems = queryItems;
  if(urlComponents.string) {
    self = [self initWithString:urlComponents.string];
  }
  else {
    self = nil;
  }
  return self;
}

- (instancetype)initWithSteamOTPKey:(NSData *)key issuer:(NSString *)issuer {
  // FIXME: remove magic Steam numbers!
  NSURL *timeURL = [[NSURL alloc] initWithTimeOTPKey:key algorithm:KPKOTPHashAlgorithmSha1 issuer:issuer period:KPKTimeOTPDefaultTimeSlice digits:KPKSteamOTPGeneratorDigits];
  NSURLComponents *components = [[NSURLComponents alloc] initWithURL:timeURL resolvingAgainstBaseURL:NO];
  
  NSURLQueryItem *encoderItem = [[NSURLQueryItem alloc] initWithName:kKPKURLParameterEncoder value:kKPKURLSteamEncoderValue];
  
  components.queryItems = [components.queryItems arrayByAddingObject:encoderItem];
  if(components.string) {
    self = [self initWithString:components.string];
  }
  else {
    self = nil;
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

- (NSString *)issuer {
  NSString *issuerAsPath = self.path;
  NSString *issuerQuery = [self _queryItemValueForKey:kKPKURLParameterIssuer];
    
  if(issuerQuery.length == 0 && issuerAsPath.length == 0) {
    return @"";
  }
  switch([issuerQuery compare:issuerAsPath]) {
    case NSOrderedSame:
      return issuerQuery;
    case NSOrderedAscending:
      return issuerAsPath;
    case NSOrderedDescending:
    default:
      return issuerQuery;
  }
}

- (NSString *)encoder {
  return [self _queryItemValueForKey:kKPKURLParameterEncoder];
}

- (KPKOTPHashAlgorithm)hashAlgorithm {
  NSString *hashValue = [self _queryItemValueForKey:kKPKURLParameterAlgorithm];
  return [KPKOTPGenerator algorithmForString:hashValue];
}

- (NSInteger)digits {
  NSString *keyValue = [self _queryItemValueForKey:kKPKURLParameterDigits];
  return keyValue ? keyValue.integerValue : -1;
}

- (NSInteger)period {
  NSString *periodValue = [self _queryItemValueForKey:kKPKURLParameterPeriod];
  return periodValue ? periodValue.integerValue : -1;
}

- (NSInteger)counter {
  NSString *counterValue = [self _queryItemValueForKey:kKPKURLParameterCounter];
  return counterValue ? counterValue.integerValue : -1;
}

- (BOOL)isHmacOTPURL {
  /* handle invalid nil cases */
  if(nil == self.scheme || nil == self.host) {
    return NO;
  }
  if(NSOrderedSame != [self.scheme compare:kKPKURLOtpAuthScheme options:NSCaseInsensitiveSearch]) {
    return NO;
  }
  return (NSOrderedSame == [self.host compare:kKPKURLTypeHmacOTP options:NSCaseInsensitiveSearch]);
}

- (BOOL)isTimeOTPURL {
  /* handle invalid nil cases */
  if(nil == self.scheme || nil == self.host) {
    return NO;
  }
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
