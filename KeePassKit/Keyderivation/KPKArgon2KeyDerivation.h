//
//  KPKAnon2KeyDerivation.h
//  KeePassKit
//
//  Created by Michael Starke on 13/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKKeyDerivation.h"

// Argon2 Options
FOUNDATION_EXPORT NSString *const KPKArgon2SaltOption; // NSData
FOUNDATION_EXPORT NSString *const KPKArgon2ParallelismOption; // KPKNumber uint32_t
FOUNDATION_EXPORT NSString *const KPKArgon2MemoryOption; // KPKNumber utin64_t
FOUNDATION_EXPORT NSString *const KPKArgon2IterationsOption; // KPKNumber utin64_t
FOUNDATION_EXPORT NSString *const KPKArgon2VersionOption; // KPKNumber uint32_t
FOUNDATION_EXPORT NSString *const KPKArgon2KeyOption; // NSData
FOUNDATION_EXPORT NSString *const KPKArgon2AssociativeDataOption; // NSData

@interface KPKArgon2KeyDerivation : KPKKeyDerivation

@end
