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

@property (readonly) NSUInteger kpk_unsignedInteger;

@end
/// Hash algorithm used for the OTP generator
typedef NS_ENUM(NSUInteger, KPKOTPHashAlgorithm ) {
  KPKOTPHashAlgorithmInvalid, // Should be used to indicate invalid state
  KPKOTPHashAlgorithmSha1,
  KPKOTPHashAlgorithmSha256,
  KPKOTPHashAlgorithmSha512,
  KPKOTPHashAlgorithmDefault = KPKOTPHashAlgorithmSha1
};

/// Use these options to specify how to save settings to an entry
/// Normally KPKOTPSaveOptionsDefault should be used.
/// Since there are multipe storage formats used by various plugins and clients the default options tries to be highly compatible
/// This might lead to duplication of settings. If you only want to ensure a dedicated format, use the appropriate option
typedef NS_OPTIONS(NSUInteger, KPKOTPSaveOptions) {
  KPKOTPSaveOptionKeePassNative = 1 << 0, /// saves the options using the native Keepass custom attributes
  KPKOTPSaveOptionURL           = 1 << 1, /// saves the options using the otpauth URI scheme custom attribute favoured by KeePassXC and others
  KPKOTPSaveOptionPlugins       = 1 << 2, /// saves the options using the Tray OTP custom attributes
  KPKOTPSaveOptionsAutomatic    = 1 << 3, /// saves the options using the best fit for the attributes currently present
  KPKOTPSaveOptionDefault = (KPKOTPSaveOptionKeePassNative | KPKOTPSaveOptionURL)
};

@class KPKEntry;
@class KPKAttribute;

FOUNDATION_EXTERN NSUInteger const KPKOTPMinumNumberOfDigits;
FOUNDATION_EXTERN NSUInteger const KPKOTPMaxiumNumberOfDigits;

/// Abstract base class for all OTP generators. You should only use concrete subclasses
@interface KPKOTPGenerator : NSObject <NSCopying>

+ (KPKOTPHashAlgorithm)algorithmForString:(NSString *)string;
+ (NSString *)stringForAlgorithm:(KPKOTPHashAlgorithm)algorithm;

@property (readonly, copy, nonatomic) NSString *string; /// will be formatted according to the supplied options
@property (readonly, copy, nonatomic) NSData *data; /// will return the raw data of the OTP generator, you normally should only need the string value

@property (copy) NSData *key; // the seed key for the OTP Generator, default=empty data
@property KPKOTPHashAlgorithm hashAlgorithm; // the hash algorithm to base the OTP data on, default=KPKTOPHashAlgorithmSha1
@property (nonatomic, readonly) KPKOTPHashAlgorithm defaultHashAlgoritm;
@property NSUInteger numberOfDigits; // the number of digits to vent as code, default=6
@property (nonatomic, readonly) NSUInteger defaultNumberOfDigits;

- (instancetype)init NS_UNAVAILABLE;
/// initalizes the OTP Generator with the given entry attributes
/// @param attributes the attributes to use for configuring the OTP generator
- (instancetype)initWithAttributes:(NSArray <KPKAttribute*>*)attributes;
/// Saves the OTP generator settings to the supplied entry
/// The default implementation calls into -saveToEntry:options: with KPKOTPSaveOptionsDefault
/// @param entry the entry to save to
- (void)saveToEntry:(KPKEntry *)entry;

/// Saves the OTP Genarator settings to the supplied entry
/// @param entry the entry to save to
/// @param options options to specify how to save the options, use KPKOTPSaveOptionsDefaults for being compatible with most KeePass clients
- (void)saveToEntry:(KPKEntry *)entry options:(KPKOTPSaveOptions)options;

@end

NS_ASSUME_NONNULL_END
