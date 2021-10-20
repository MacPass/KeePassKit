//
//  KPKHmacOTPGenerator.m
//  KeePassKit
//
//  Created by Michael Starke on 03.12.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import "KPKHmacOTPGenerator.h"
#import "KPKOTPGenerator_Private.h"
#import "KPKAttribute.h"
#import "KPKEntry.h"

#import "NSString+KPKHexdata.h"
#import "NSURL+KPKAdditions.h"
#import "NSData+KPKBase32.h"
#import "NSDictionary+KPKAttributes.h"

@implementation KPKHmacOTPGenerator

- (instancetype)init {
  self = [super _init];
  if(self) {
    _counter = 0;
  }
  return self;
}

- (instancetype)initWithAttributes:(NSArray <KPKAttribute *>*)attributes {
  self = [self init];
  if(self) {
    if(![self _parseAttributes:attributes]) {
      self = nil;
    }
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  KPKHmacOTPGenerator *copy = [super copyWithZone:zone];
  copy.counter = self.counter;
  return copy;
}

- (NSString *)description {
  NSString *baseString = [super description];
  return [baseString stringByAppendingFormat:@" counter:%ld", self.counter];
}

- (void)saveCounterToEntry:(KPKEntry *)entry {
  KPKAttribute *urlAttribute = [entry attributeWithKey:kKPKAttributeKeyOTPOAuthURL];
  if(urlAttribute) {
    NSURL *url = [NSURL URLWithString:urlAttribute.value];
    if(url.isHmacOTPURL) {
      NSURL *newURL = [NSURL URLWithHmacOTPKey:url.key algorithm:url.hashAlgorithm issuer:url.issuer counter:self.counter digits:self.numberOfDigits];
      urlAttribute.value = newURL.absoluteString;
    }
  }
  NSString *counterString = [NSString stringWithFormat:@"%ld", self.counter];
  KPKAttribute *counterAttribute = [entry attributeWithKey:kKPKAttributeKeyHmacOTPCounter];
  if(!counterAttribute) {
    counterAttribute = [[KPKAttribute alloc] initWithKey:kKPKAttributeKeyHmacOTPCounter value:counterString];
    [entry addCustomAttribute:counterAttribute];
  }
  else {
    counterAttribute.value = counterString;
  }
}

- (NSUInteger)_counter {
  return self.counter;
}

- (BOOL)_parseAttributes:(NSArray <KPKAttribute*>*)attributes {
  NSDictionary *attributeDict = [NSDictionary dictionaryWithAttributes:attributes];
  KPKAttribute *urlAttribute = attributeDict[kKPKAttributeKeyOTPOAuthURL];
  
  if(urlAttribute) {
    NSURL *authURL = [NSURL URLWithString:urlAttribute.evaluatedValue];
    if(authURL && authURL.isTimeOTPURL) {
      if(authURL.digits > 0) {
        self.numberOfDigits = authURL.digits;
      }
      if(KPKOTPHashAlgorithmInvalid != authURL.hashAlgorithm) {
        self.hashAlgorithm = authURL.hashAlgorithm;
      }
      if(authURL.counter > 0 ) {
        self.counter = authURL.counter;
      }
      if(authURL.key.length != 0) {
        self.key = authURL.key;
      }
      else {
        return NO; // key is mandatory!
      }
      return YES; // parsed otpauth url, no need for more!
    }
  }
  
  /* HTOP Settings */
  KPKAttribute *asciiKeyAttribute = attributeDict[kKPKAttributeKeyHmacOTPSecret];
  KPKAttribute *hexKeyAttribute = attributeDict[kKPKAttributeKeyHmacOTPSecretHex];
  KPKAttribute *base32KeyAttribute = attributeDict[kKPKAttributeKeyHmacOTPSecretBase32];
  KPKAttribute *base64KeyAttribute = attributeDict[kKPKAttributeKeyHmacOTPSecretBase64];
  
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
    return NO; // missing key!!!
  }
  
  KPKAttribute *counterAttribute = attributeDict[kKPKAttributeKeyHmacOTPCounter];
  self.counter = counterAttribute.evaluatedValue.integerValue; // defaults to 0 when no counter was found

  return YES;
}

- (void)saveToEntry:(KPKEntry *)entry {
  /*
   strategy ist to add a otp attribute regardless of the current state
   update or add KeePass native settings regardless of current state
   
   This leads to entries having at least the otp and the native settings
   */
  NSString *urlString = [NSURL URLWithHmacOTPKey:self.key algorithm:self.hashAlgorithm issuer:[self _issuerForEntry:entry] counter:self.counter digits:self.numberOfDigits].absoluteString;
  KPKAttribute *urlAttribute = [entry attributeWithKey:kKPKAttributeKeyOTPOAuthURL];
  /* update or create the URL attribute */
  if(!urlAttribute) {
    urlAttribute = [[KPKAttribute alloc] initWithKey:kKPKAttributeKeyOTPOAuthURL value:urlString];
    [entry addCustomAttribute:urlAttribute];
  }
  else {
    urlAttribute.value = urlString;
  }
  
  /* HTOP Settings */
  KPKAttribute *asciiKeyAttribute = [entry attributeWithKey:kKPKAttributeKeyHmacOTPSecret];
  KPKAttribute *hexKeyAttribute = [entry attributeWithKey:kKPKAttributeKeyHmacOTPSecretHex];
  KPKAttribute *base32KeyAttribute = [entry attributeWithKey:kKPKAttributeKeyHmacOTPSecretBase32];
  KPKAttribute *base64KeyAttribute = [entry attributeWithKey:kKPKAttributeKeyHmacOTPSecretBase64];
  
  /* brute write, nil just works */
  asciiKeyAttribute.value = [[NSString alloc] initWithData:self.key encoding:NSUTF8StringEncoding];
  hexKeyAttribute.value = [NSString kpk_hexstringFromData:self.key];
  base32KeyAttribute.value = [self.key base32EncodedStringWithOptions:0];
  base64KeyAttribute.value = [self.key base64EncodedStringWithOptions:0];
  
  if(!(asciiKeyAttribute || hexKeyAttribute || base32KeyAttribute || base64KeyAttribute)) {
    base32KeyAttribute = [[KPKAttribute alloc] initWithKey:kKPKAttributeKeyHmacOTPSecretBase32 value:[self.key base32EncodedStringWithOptions:0]];
    [entry addCustomAttribute:base32KeyAttribute];
  }
  
  NSString *counterString = [NSString stringWithFormat:@"%ld", self.counter];
  KPKAttribute *counterAttribute = [entry attributeWithKey:kKPKAttributeKeyHmacOTPCounter];
  if(!counterAttribute) {
    counterAttribute = [[KPKAttribute alloc] initWithKey:kKPKAttributeKeyHmacOTPCounter value:counterString];
    [entry addCustomAttribute:counterAttribute];
  }
  else {
    counterAttribute.value = counterString;
  }
}

@end
