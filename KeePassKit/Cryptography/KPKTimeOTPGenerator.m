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

#import "NSDictionary+KPKAttributes.h"

NSUInteger const KPKTimeOTPDefaultTimeSlice = 30;

NSString * stringForAlgoritm(KPKOTPHashAlgorithm algoritm) {
  switch(algoritm) {
    case KPKOTPHashAlgorithmSha1:
      return kKPKAttributeValueTimeOTPHmacSha1;
    case KPKOTPHashAlgorithmSha256:
      return kKPKAttributeValueTimeOTPHmacSha256;
    case KPKOTPHashAlgorithmSha512:
      return kKPKAttributeValueTimeOTPHmacSha512;
    default:
      return nil;
  }
}

KPKOTPHashAlgorithm algoritmForString(NSString *string) {
  if(NSOrderedSame == [kKPKAttributeValueTimeOTPHmacSha1 compare:string options:NSCaseInsensitiveSearch]) {
    return KPKOTPHashAlgorithmSha1;
  }
  if(NSOrderedSame == [kKPKAttributeValueTimeOTPHmacSha256 compare:string options:NSCaseInsensitiveSearch]) {
    return KPKOTPHashAlgorithmSha256;
  }
  if(NSOrderedSame == [kKPKAttributeValueTimeOTPHmacSha512 compare:string options:NSCaseInsensitiveSearch]) {
    return KPKOTPHashAlgorithmSha512;
  }
  return KPKOTPHashAlgorithmInvalid;
}

@implementation KPKTimeOTPGenerator

@dynamic defaultTimeSlice;

- (instancetype)init {
  self = [super _init];
  if(self) {
    _timeBase = 0;
    _timeSlice = KPKTimeOTPDefaultTimeSlice;
    _time = 0;
  }
  return self;
}

- (instancetype)initWithURL:(NSString *)otpAuthURL {
  self = [self init];
  if(self) {
    NSURL *url = [NSURL URLWithString:otpAuthURL];
    if(![self _parseURL:url]) {
      self = nil;
    }
  }
  return self;
}

- (instancetype)initWithAttributes:(NSArray<KPKAttribute *> *)attributes {
  self = [self init];
  if(self) {
    if(![self _parseAttributes:attributes]) {
      self = nil;
    }
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  KPKTimeOTPGenerator *copy = [super copyWithZone:zone];
  copy.timeBase = self.timeBase;
  copy.timeSlice = self.timeSlice;
  copy.time = self.time;
  return copy;
}

- (NSString *)description {
  NSString *baseString = [super description];
  return [baseString stringByAppendingFormat:@" timeBase:%f timeSlice:%ld time:%f", self.timeBase, self.timeSlice, self.time];
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
    seedAttribute.value = [self.key base32EncodedStringWithOptions:0];
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
  KPKAttribute *algorithmAttr = [entry attributeWithKey:kKPKAttributeKeyTimeOTPAlgorithm];
  
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
    secretBase32Attribute = [[KPKAttribute alloc] initWithKey:kKPKAttributeKeyTimeOTPSecretBase32 value:[self.key base32EncodedStringWithOptions:0]];
    [entry addCustomAttribute:secretBase32Attribute];
  }
  
  /* lenght */
  BOOL defaultLenght = self.defaultNumberOfDigits == self.numberOfDigits;
  if(defaultLenght) {
    [entry removeCustomAttribute:lengthAttr];
  }
  else {
    if(!lengthAttr) {
      lengthAttr = [[KPKAttribute alloc] initWithKey:kKPKAttributeKeyTimeOTPLength value:[NSString stringWithFormat:@"%ld",self.numberOfDigits]];
      [entry addCustomAttribute:lengthAttr];
    }
    else {
      lengthAttr.value = [NSString stringWithFormat:@"%ld",self.numberOfDigits];
    }
  }
  /* period */
  
  BOOL defaultPeriod = self.timeSlice == self.defaultTimeSlice;
  if(defaultPeriod) {
    [entry removeCustomAttribute:periodAttr];
  }
  else {
    if(!periodAttr) {
      periodAttr = [[KPKAttribute alloc] initWithKey:kKPKAttributeKeyTimeOTPPeriod value:[NSString stringWithFormat:@"%ld",self.timeSlice]];
      [entry addCustomAttribute:periodAttr];
    }
    else {
      periodAttr.value = [NSString stringWithFormat:@"%ld",self.timeSlice];
    }
  }
  
  /* algorithm */
  BOOL defaultAlgorithm = self.defaultHashAlgoritm == self.hashAlgorithm;
  if(defaultAlgorithm) {
    [entry removeCustomAttribute:algorithmAttr];
  }
  else {
    NSString *algorithmString = stringForAlgoritm(self.hashAlgorithm);
    if(!algorithmAttr) {
      algorithmAttr = [[KPKAttribute alloc] initWithKey:kKPKAttributeKeyTimeOTPAlgorithm value:algorithmString];
      [entry addCustomAttribute:algorithmAttr];
    }
    else {
      algorithmAttr.value = algorithmString;
    }
  }
}

- (NSUInteger)_counter {
  return floor((self.time - self.timeBase) / self.timeSlice);
}

- (BOOL)isRFC6238 {
  // prevent derived classes from returing YES
  if(self.class != KPKTimeOTPGenerator.class) {
    return NO;
  }
  return (self.defaultTimeSlice == self.timeSlice
          && self.numberOfDigits == self.defaultNumberOfDigits
          && self.hashAlgorithm == self.defaultHashAlgoritm);
}

- (NSUInteger)defaultTimeSlice {
  return KPKTimeOTPDefaultTimeSlice;
}

- (NSTimeInterval)remainingTime {
  return self.timeSlice - ((NSUInteger)(self.time - self.timeBase) % self.timeSlice);
}

- (BOOL)_parseAttributes:(NSArray <KPKAttribute*>*)attributes {
  
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
      self.timeSlice = parts[0].integerValue;
      self.numberOfDigits = parts[1].integerValue;
      // TODO: add support for time-correction parameter;
      return YES;
    }
  }
  else {
    // nothing to do
  }
  
  KPKAttribute *asciiKeyAttribute = attributesDict[kKPKAttributeKeyTimeOTPSecret];
  KPKAttribute *hexKeyAttribute = attributesDict[kKPKAttributeKeyTimeOTPSecretHex];
  KPKAttribute *base32KeyAttribute = attributesDict[kKPKAttributeKeyTimeOTPSecretBase32];
  KPKAttribute *base64KeyAttribute = attributesDict[kKPKAttributeKeyTimeOTPSecretBase64];
  
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
  
  KPKAttribute *lengthAttribute = attributesDict[kKPKAttributeKeyTimeOTPLength];
  if(lengthAttribute) {
    NSInteger length = lengthAttribute.evaluatedValue.integerValue;
    if(length > 0) {
      self.numberOfDigits = length;
    }
  }
  KPKAttribute *periodAttribute = attributesDict[kKPKAttributeKeyTimeOTPPeriod];
  if(periodAttribute) {
    NSInteger period = periodAttribute.evaluatedValue.integerValue;
    if(period > 0) {
      self.timeSlice = period;
    }
  }
  KPKAttribute *algorithmAttribute = attributesDict[kKPKAttributeKeyTimeOTPAlgorithm];
  if(algorithmAttribute) {
    KPKOTPHashAlgorithm algorithm = algoritmForString(algorithmAttribute.evaluatedValue);
    if(algorithm != KPKOTPHashAlgorithmInvalid) {
      self.hashAlgorithm = algorithm;
    }
  }
  
  return YES;
}

- (BOOL)_parseURL:(NSURL *)authURL {
  if(!(authURL && authURL.isTimeOTPURL)) {
    return NO;
  }
  
  if(authURL.key.length != 0) {
    self.key = authURL.key;
  }
  
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
