//
//  KPKHmacOTPGenerator.h
//  KeePassKit
//
//  Created by Michael Starke on 03.12.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import <KeePassKit/KeePassKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KPKHmacOTPGenerator : KPKOTPGenerator

@property NSUInteger counter; // the counter to calculate the OTP for, default=0, only for KPKOTPGeneratorHmacOTP

- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
