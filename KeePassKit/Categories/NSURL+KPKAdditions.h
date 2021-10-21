//
//  NSURL+KPKAdditions.h
//  KeePassKit
//
//  Created by Michael Starke on 03.12.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <KeePassKit/KPKOTPGenerator.h>

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
FOUNDATION_EXTERN NSString *const kKPKURLParameterEncoder;

FOUNDATION_EXTERN NSString *const kKPKURLSteamEncoderValue; // for steam otpauth urls. encoder=steam

@property (readonly, nonatomic) BOOL isHmacOTPURL;
@property (readonly, nonatomic) BOOL isTimeOTPURL;
@property (readonly, nonatomic) BOOL isSteamOTPURL;

@property (copy, readonly, nullable) NSData* key;
@property (copy, readonly) NSString *issuer;
@property (copy, readonly) NSString *encoder; // KeePassXC custom otp format to encode Stream
@property (readonly) KPKOTPHashAlgorithm hashAlgorithm;
@property (readonly) NSInteger digits;
@property (readonly) NSInteger counter; // only for HmacOTP urls
@property (readonly) NSInteger period; // only for TimeOTP urls

+ (instancetype)URLWithHmacOTPKey:(NSData *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer counter:(NSUInteger)counter digits:(NSUInteger)digits;
+ (instancetype)URLWithTimeOTPKey:(NSData *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer period:(NSUInteger)period digits:(NSUInteger)digits;
+ (instancetype)URLWIthSteamOTPKey:(NSData *)key issuer:(NSString *)issuer;
- (instancetype)initWithHmacOTPKey:(NSData *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer counter:(NSUInteger)counter digits:(NSUInteger)digits;
- (instancetype)initWithTimeOTPKey:(NSData *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer period:(NSUInteger)period digits:(NSUInteger)digits;
- (instancetype)initWithSteamOTPKey:(NSData *)key issuer:(NSString *)issuer;
@end

NS_ASSUME_NONNULL_END
