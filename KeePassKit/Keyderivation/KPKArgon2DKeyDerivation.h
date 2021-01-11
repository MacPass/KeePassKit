//
//  KPKAnon2KeyDerivation.h
//  KeePassKit
//
//  Created by Michael Starke on 13/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <KeePassKit/KPKKeyDerivation.h>

// Argon2 types
typedef NS_OPTIONS(NSUInteger, KPKArgon2Type) {
  KPKArgon2TypeD = 0,
  KPKArgon2TypeI = 1, // currently unsupported due to no use cases
  KPKArgon2TypeID = 2
};

// Argon2 Options
FOUNDATION_EXPORT NSString *const KPKArgon2SaltParameter; // NSData
FOUNDATION_EXPORT NSString *const KPKArgon2ParallelismParameter; // KPKNumber uint32_t
FOUNDATION_EXPORT NSString *const KPKArgon2MemoryParameter; // KPKNumber utin64_t
FOUNDATION_EXPORT NSString *const KPKArgon2IterationsParameter; // KPKNumber utin64_t
FOUNDATION_EXPORT NSString *const KPKArgon2VersionParameter; // KPKNumber uint32_t
FOUNDATION_EXPORT NSString *const KPKArgon2SecretKeyParameter; // NSData
FOUNDATION_EXPORT NSString *const KPKArgon2AssociativeDataParameter; // NSData

@interface KPKArgon2DKeyDerivation : KPKKeyDerivation

@property (class, readonly) KPKArgon2Type type;

@property (nonatomic, assign) uint64_t iterations;
@property (nonatomic, assign) uint64_t memory;
@property (nonatomic, assign) uint32_t threads;

@property (nonatomic, readonly, assign) uint64_t minimumMemory;
@property (nonatomic, readonly, assign) uint64_t maximumMemory;

@end
