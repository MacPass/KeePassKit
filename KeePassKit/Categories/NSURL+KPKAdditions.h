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

+ (instancetype)URLWithHmacOTPKey:(NSString *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer counter:(NSUInteger)counter digits:(NSUInteger)digits;
+ (instancetype)URLWithTimeOTPKey:(NSString *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer period:(NSUInteger)perid digits:(NSUInteger)digits;

@end

NS_ASSUME_NONNULL_END
