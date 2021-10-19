//
//  KPKOTP.m
//  KeePassKit
//
//  Created by Michael Starke on 09.12.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "KPKOTPGenerator.h"
#import "KPKOTPGenerator_Private.h"
#import "KPKEntry.h"
#import "KPKAttribute.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSData (KPKOTPDataConversion)

- (NSUInteger)kpk_unsignedInteger {
  /*
   HMAC data is interpreted as big endian
   */
  NSUInteger number = 0;
  [self getBytes:&number length:MIN(self.length, sizeof(NSUInteger))];
  
  /*
   convert big endian to host
   if conversion took place, we need to shift by the size
   */
#if __LP64__ || NS_BUILD_32_LIKE_64
  NSUInteger beNumber = (NSUInteger)CFSwapInt64BigToHost(number);
#else
  NSUInteger beNumber = (NSUInteger)CFSwapInt32BigToHost(number);
#endif
  
  if(beNumber != number) {
    beNumber >>= (8 * (sizeof(NSUInteger) - self.length));
  }
  return beNumber;
}

@end

NSUInteger const KPKOTPMinumNumberOfDigits = 6;
NSUInteger const KPKOTPMaxiumNumberOfDigits = 8;
static NSUInteger const KPKOTPDefaultNumberOfDigits = 6;


@implementation KPKOTPGenerator

@dynamic defaultHashAlgoritm;
@dynamic defaultNumberOfDigits;

+ (KPKOTPHashAlgorithm)algorithmForString:(NSString *)string {
    static NSDictionary <NSString *, NSNumber *> *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      map = @{ @"sha1" : @(KPKOTPHashAlgorithmSha1) ,
               @"sha256" : @(KPKOTPHashAlgorithmSha256),
               @"sha512" : @(KPKOTPHashAlgorithmSha512) };
    });
  NSNumber *value = map[string.lowercaseString];
  return value ? (KPKOTPHashAlgorithm)value.integerValue : KPKOTPHashAlgorithmInvalid;
}

+ (NSString *)stringForAlgorithm:(KPKOTPHashAlgorithm)algorithm {
  switch(algorithm) {
    case KPKOTPHashAlgorithmSha1:
      return @"sha1";
    case KPKOTPHashAlgorithmSha256:
      return @"sha256";
    case KPKOTPHashAlgorithmSha512:
      return @"sha512";
    default:
      return @"";
  }
}

- (id)copyWithZone:(NSZone *)zone {
  KPKOTPGenerator *copy = [[self.class alloc] _init];
  copy.key = self.key;
  copy.hashAlgorithm = self.hashAlgorithm;
  copy.numberOfDigits = self.numberOfDigits;
  return copy;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"%@: key:%@ algorithm:%@ numberOfDigits:%lu",
          self.class,
          self.key,
          [KPKOTPGenerator stringForAlgorithm:self.hashAlgorithm],
          (unsigned long)self.numberOfDigits];
}

- (instancetype)_init {
  self = [super init];
  if(self) {
    _hashAlgorithm = self.defaultHashAlgoritm;
    _key = [NSData.data copy]; // use an empty key;
    _numberOfDigits = self.defaultNumberOfDigits;
  }
  return self;
}

- (NSUInteger)_counter {
   [self doesNotRecognizeSelector:_cmd];
   return 0;
}

- (NSString *)_alphabet {
  return @"0123456789";
}

- (NSString *)_issuerForEntry:(KPKEntry *)entry {
  NSMutableString *issuer = [[NSMutableString alloc] init];
  if(entry.title) {
    [issuer appendString:entry.title];
  }
  if(entry.username) {
    if(issuer.length >= 0) {
      [issuer appendFormat:@":%@", entry.username];
    }
    else {
      [issuer appendString:entry.username];
    }
  }
  if(entry.url) {
    NSURL *url = [NSURL URLWithString:entry.url];
    if(url.host) {
      [issuer appendFormat:@"@%@", url.host];
    }
  }
  return [issuer copy];
}

- (instancetype)initWithAttributes:(NSArray<KPKAttribute *> *)attributes {
  [self doesNotRecognizeSelector:_cmd];
  self = nil;
  return self;
}

- (void)saveToEntry:(KPKEntry *)entry {
  [self doesNotRecognizeSelector:_cmd];
}

- (NSData *)data {
  if(![self _validateOptions]) {
    return NSData.data;
  }
  return [self _HMACOTPWithKey:self.key counter:[self _counter] algorithm:self.hashAlgorithm];
}

- (NSString *)string {
  NSData *data = self.data;
  if(data.length == 0) {
    return @""; // invalid data
  }
  
  NSUInteger decimal = data.kpk_unsignedInteger;
  NSString *alphabet = [self _alphabet];
  NSUInteger alphabetLength = alphabet.length;
  NSMutableString *result = [[NSMutableString alloc] init];
  while(result.length < self.numberOfDigits) {
    NSUInteger code = decimal % alphabetLength;
    if(code < alphabetLength) {
      [result insertString:[alphabet substringWithRange:NSMakeRange(code, 1)] atIndex:0];
    }
    else {
      return @""; // falure
    }
    decimal /= alphabetLength;
  }
  return [result copy];
}

- (KPKOTPHashAlgorithm)defaultHashAlgoritm {
  return KPKOTPHashAlgorithmSha1;
}

- (NSUInteger)defaultNumberOfDigits {
  return KPKOTPDefaultNumberOfDigits;
}

- (BOOL)_validateOptions {
  return (self.numberOfDigits >= 6 &&
          self.numberOfDigits <= 10
          );
  // an empty key seems to be allowed
}

- (NSData *)_HMACOTPWithKey:(NSData *)key counter:(uint64_t)counter algorithm:(KPKOTPHashAlgorithm)algorithm {
  // ensure we use big endian
  uint64_t beCounter = CFSwapInt64HostToBig(counter);
  
  uint8_t digestLenght = CC_SHA1_DIGEST_LENGTH;
  CCHmacAlgorithm hashAlgorithm = kCCHmacAlgSHA1;
  switch(algorithm) {
    case KPKOTPHashAlgorithmSha1:
      break; // nothing to do
    case KPKOTPHashAlgorithmSha256:
      hashAlgorithm = kCCHmacAlgSHA256;
      digestLenght = CC_SHA256_DIGEST_LENGTH;
      break;
    case KPKOTPHashAlgorithmSha512:
      hashAlgorithm = kCCHmacAlgSHA512;
      digestLenght = CC_SHA512_DIGEST_LENGTH;
      break;
    default:
      // should not happen
      return nil;
      break;
  }
  
  uint8_t mac[digestLenght];
  CCHmac(hashAlgorithm, key.bytes, key.length, &beCounter, sizeof(uint64_t), mac);
  
  /* offset is lowest 4 bit on last byte */
  uint8_t offset = (mac[digestLenght - 1] & 0x0f);
  
  uint8_t otp[4];
  otp[0] = mac[offset] & 0x7f;
  otp[1] = mac[offset + 1];
  otp[2] = mac[offset + 2];
  otp[3] = mac[offset + 3];
  
  return [NSData dataWithBytes:&otp length:sizeof(uint32_t)];
}

@end
