//
//  NSURL+KPKAdditions.h
//  KeePassKit
//
//  Created by Michael Starke on 03.12.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPKOTPGenerator.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (KPKAdditions)

FOUNDATION_EXTERN NSString *const kKPKURLOtpAuthScheme;
FOUNDATION_EXTERN NSString *const kKPKURLTypeHmacOTP;
FOUNDATION_EXTERN NSString *const kKPKURLTypeTimeOTP;
FOUNDATION_EXTERN NSString *const kKPKURLParameterSecret;
FOUNDATION_EXTERN NSString *const kKPKURLParameterAlgorithm;
FOUNDATION_EXTERN NSString *const kKPKURLParameterDigits;
FOUNDATION_EXTERN NSString *const kKPKURLParameterIssuer;
FOUNDATION_EXTERN NSString *const kKPKURLParameterPeriod;
FOUNDATION_EXTERN NSString *const kKPKURLParameterCounter;

@property (readonly, nonatomic) BOOL isHmacOTPURL;
@property (readonly, nonatomic) BOOL isTimeOTPURL;

@property (copy, readonly, nullable) NSData* key;
@property (readonly) KPKOTPHashAlgorithm hashAlgorithm;
@property (readonly) NSUInteger digits;
@property (readonly) NSUInteger counter; // only for HmacOTP urls
@property (readonly) NSUInteger period; // only for TimeOTP urls

+ (instancetype)URLWithHmacOTPKey:(NSString *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer counter:(NSUInteger)counter digits:(NSUInteger)digits;
+ (instancetype)URLWithTimeOTPKey:(NSString *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer period:(NSUInteger)period digits:(NSUInteger)digits;
- (instancetype)initWithHmacOTPKey:(NSString *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer counter:(NSUInteger)counter digits:(NSUInteger)digits;
- (instancetype)initWithTimeOTPKey:(NSString *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer period:(NSUInteger)period digits:(NSUInteger)digits;
@end

NS_ASSUME_NONNULL_END