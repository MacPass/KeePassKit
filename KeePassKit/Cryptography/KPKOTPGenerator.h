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

typedef NS_ENUM(NSUInteger, KPKOTPHashAlgorithm ) {
  KPKOTPHashAlgorithmInvalid, // Should be used to indicate invalid state
  KPKOTPHashAlgorithmSha1,
  KPKOTPHashAlgorithmSha256,
  KPKOTPHashAlgorithmSha512,
  KPKOTPHashAlgorithmDefault = KPKOTPHashAlgorithmSha1
};

@class KPKEntry;
@class KPKAttribute;

FOUNDATION_EXTERN NSUInteger const KPKOTPMinumNumberOfDigits;
FOUNDATION_EXTERN NSUInteger const KPKOTPMaxiumNumberOfDigits;

/**
 Abstract base class for all OTP generators. You should only use concrete subclasses
 */
@interface KPKOTPGenerator : NSObject <NSCopying>

+ (KPKOTPHashAlgorithm)algorithmForString:(NSString *)string;
+ (NSString *)stringForAlgorithm:(KPKOTPHashAlgorithm)algorithm;

@property (readonly, copy, nonatomic) NSString *string; // will be formatted according to the supplied options, bindable and KVO confromant
@property (readonly, copy, nonatomic) NSData *data; // will return the raw data of the OTP generator, you normally should only need the string value. Is KVO compliant and bindable

@property (copy) NSData *key; // the seed key for the OTP Generator, default=empty data
@property KPKOTPHashAlgorithm hashAlgorithm; // the hash algorithm to base the OTP data on, default=KPKTOPHashAlgorithmSha1
@property (nonatomic, readonly) KPKOTPHashAlgorithm defaultHashAlgoritm;
@property NSUInteger numberOfDigits; // the number of digits to vent as code, default=6
@property (nonatomic, readonly) NSUInteger defaultNumberOfDigits;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAttributes:(NSArray <KPKAttribute*>*)attributes; // initalizes the OTP Generator with the given entry attributes
- (void)saveToEntry:(KPKEntry *)entry; // save the OTP Generator settings to the supplied entry

@end

NS_ASSUME_NONNULL_END
