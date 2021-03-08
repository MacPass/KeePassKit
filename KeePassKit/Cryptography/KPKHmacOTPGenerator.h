//
//  KPKHmacOTPGenerator.h
//  KeePassKit
//
//  Created by Michael Starke on 03.12.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import <KeePassKit/KPKOTPGenerator.h>

NS_ASSUME_NONNULL_BEGIN

@class KPKEntry;

@interface KPKHmacOTPGenerator : KPKOTPGenerator

@property NSUInteger counter; // the counter to calculate the OTP for, default=0, only for KPKOTPGeneratorHmacOTP

- (instancetype)init NS_DESIGNATED_INITIALIZER; // Creates a HmacOTP generator with an empty key and a counter set to 0
- (void)saveCounterToEntry:(KPKEntry *)entry; // Save only the current counter to the entry;

@end

NS_ASSUME_NONNULL_END
