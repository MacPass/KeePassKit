//
//  KPKOTP.h
//  KeePassKit
//
//  Created by Michael Starke on 09.12.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (KPKOTPDataConversion)

@property (readonly) NSUInteger unsignedInteger;

- (NSUInteger)unsignedIntegerFromIndex:(NSInteger)index;
- (NSUInteger)unsignedIntegerFromRange:(NSRange)range;

@end

FOUNDATION_EXPORT NSString const *KPKOTPGeneratorTypeKey; // KPKOTPGeneratorType
FOUNDATION_EXPORT NSString const *KPKOTPGeneratorAlgorithmKey; // KPKOTPHashAlgorithm
FOUNDATION_EXPORT NSString const *KPKOTPGeneratorTimeBaseKey; // NSUInterger
FOUNDATION_EXPORT NSString const *KPKOTPGeneratorTimeSliceKey; // NSUInteger
FOUNDATION_EXPORT NSString const *KPKOTPGeneratorTimeKey; // NSTimeInterval
FOUNDATION_EXPORT NSString const *KPKOTPGeneratorKeyDataKey; // NSData;

typedef NS_ENUM(NSUInteger, KPKOTPHashAlgorithm ) {
  KPKOTPHashAlgorithmSha1,
  KPKOTPHashAlgorithmSha256,
  KPKOTPHashAlgorithmSha512,
  KPKOTPHashAlgorithmDefault = KPKOTPHashAlgorithmSha1
};

typedef NS_ENUM(NSUInteger, KPKOTPGeneratorType) {
  KPKOTPGeneratorHmacOTP,
  KPKOTPGeneratorTOTP,
  KPKOTPGeneratorSteamOTP
};

@interface KPKOTPGenerator : NSObject

@property (copy) NSString *string;
@property (copy) NSData *data;

- (instancetype)initWithOptions:(NSDictionary *)options NS_DESIGNATED_INITIALIZER;

/// Generates a Hmac OTP data for the given parameters
/// @param key the key data to use. No conversion is done, suppy the raw key data
/// @param counter the counter to calculate the Hmac for
/// @param algorithm the algorithm to use. Hmac is only documented fot Sha1 so use this if in doubt
+ (NSData *)HMACOTPWithKey:(NSData *)key counter:(uint64_t)counter algorithm:(KPKOTPHashAlgorithm)algorithm;

/// Generates a TimeOTP data for the given parameters using Hmac OTP and suppliying a time based counter value
/// @param key the key data to use
/// @param time the time interval to use
/// @param slice the slice of the time interval
/// @param base the base time to use
/// @param algorithm the algorithm to use
+ (NSData *)TOTPWithKey:(NSData *)key time:(NSTimeInterval)time slice:(NSUInteger)slice base:(NSUInteger)base algorithm:(KPKOTPHashAlgorithm)algorithm;

@end

NS_ASSUME_NONNULL_END
