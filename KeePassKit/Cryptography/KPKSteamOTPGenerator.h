//
//  KPKSteamOTPGenerator.h
//  KeePassKit
//
//  Created by Michael Starke on 04.12.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import <KeePassKit/KPKTimeOTPGenerator.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSUInteger const KPKSteamOTPGeneratorDigits;
FOUNDATION_EXTERN NSString *const KPKSteamOTPGeneratorSettingsValue;

@interface KPKSteamOTPGenerator : KPKTimeOTPGenerator

@end

NS_ASSUME_NONNULL_END
