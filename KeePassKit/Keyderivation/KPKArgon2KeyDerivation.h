//
//  KPKAnon2KeyDerivation.h
//  KeePassKit
//
//  Created by Michael Starke on 13/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKKeyDerivation.h"

// Argon2 Options
FOUNDATION_EXPORT NSString *const KPKArgon2SaltParameter; // NSData
FOUNDATION_EXPORT NSString *const KPKArgon2ParallelismParameter; // KPKNumber uint32_t
FOUNDATION_EXPORT NSString *const KPKArgon2MemoryParameter; // KPKNumber utin64_t
FOUNDATION_EXPORT NSString *const KPKArgon2IterationsParameter; // KPKNumber utin64_t
FOUNDATION_EXPORT NSString *const KPKArgon2VersionParameter; // KPKNumber uint32_t
FOUNDATION_EXPORT NSString *const KPKArgon2SecretKeyParameter; // NSData
FOUNDATION_EXPORT NSString *const KPKArgon2AssociativeDataParameter; // NSData

@interface KPKArgon2KeyDerivation : KPKKeyDerivation

@property (nonatomic, readonly, assign) uint64_t iterations;
@property (nonatomic, readonly, assign) uint64_t memory;
@property (nonatomic, readonly, assign) uint32_t threads;

@end
