//
//  KPKTimeOTPGenerator.h
//  KeePassKit
//
//  Created by Michael Starke on 03.12.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import <KeePassKit/KPKOTPGenerator.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSUInteger const KPKTimeOTPDefaultTimeSlice;

@interface KPKTimeOTPGenerator : KPKOTPGenerator

@property NSTimeInterval timeBase; // the base time for Timed OTP, default=0 -> unix reference time
@property NSUInteger timeSlice; // the time slice for Timed OTP, default=30, , only for KPKOTPGeneratorTimeOTP and KPKOTPGeneratorSteamOTP
@property (nonatomic, readonly) NSUInteger defaultTimeSlice;
@property NSTimeInterval time; // the time to calculate the OTP for, default=0, only for KPKOTPGeneratorTimeOTP and KPKOTPGeneratorSteamOTP
@property (nonatomic, readonly) NSTimeInterval remainingTime; // the time in seconds the data and string is valud only for KPKOTPGeneratorTimeOTP and KPKOTPGeneratorSteamOTP
@property (nonatomic, readonly) BOOL isRFC6238; // YES if the settings are the defaults settings recemended in the RFC6238 standard

- (instancetype)init NS_DESIGNATED_INITIALIZER; // This will create a RFC6238 compliant TOTP generator with an empty key as secret.
- (instancetype)initWithURL:(NSString *)otpAuthURL;


@end

NS_ASSUME_NONNULL_END
