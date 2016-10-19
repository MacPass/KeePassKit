//
//  KPKKeyDerivation.h
//  KeePassKit
//
//  Created by Michael Starke on 05/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Argon2 Options
FOUNDATION_EXPORT NSString *const KPKArgon2SaltOption; // NSData
FOUNDATION_EXPORT NSString *const KPKArgon2ParallelismOption; // KPKNumber uint32_t
FOUNDATION_EXPORT NSString *const KPKArgon2MemoryOption; // KPKNumber utin64_t
FOUNDATION_EXPORT NSString *const KPKArgon2IterationsOption; // KPKNumber utin64_t
FOUNDATION_EXPORT NSString *const KPKArgon2VersionOption; // KPKNumber uint32_t
FOUNDATION_EXPORT NSString *const KPKArgon2KeyOption; // NSData
FOUNDATION_EXPORT NSString *const KPKArgon2AssociativeDataOption; // NSData

// AES Options
FOUNDATION_EXPORT NSString *const KPKAESSeedOption; // NSData 32 bytes
FOUNDATION_EXPORT NSString *const KPKAESRoundsOption; // KPKNumber uint64_t

@interface KPKKeyDerivation : NSObject

/**
 Returns a Variant dictionary with the default parameters

 @return NSDictionary(Variant) with default parameters
 */
+ (NSDictionary *)defaultOptions;

+ (NSUUID *)uuid;
+ (void)parametersForDelay:(NSUInteger)seconds completionHandler:(void(^)(NSDictionary *options))completionHandler;

+ (KPKKeyDerivation * _Nullable)keyDerivationWithUUID:(NSUUID *)uuid;
+ (KPKKeyDerivation * _Nullable)keyDerivationWithUUID:(NSUUID *)uuid options:(NSDictionary *)options;

+ (NSData * _Nullable)deriveData:(NSData *)data withUUID:(NSUUID *)uuid options:(NSDictionary *)options;

- (KPKKeyDerivation *)initWithUUID:(NSUUID *)uuid;
- (KPKKeyDerivation *)initWithUUID:(NSUUID *)uuid options:(NSDictionary *)options NS_DESIGNATED_INITIALIZER;

- (NSData * _Nullable)deriveData:(NSData *)data;

@property (readonly, copy, nonatomic) NSUUID *uuid;
@property (readonly, copy) NSDictionary *options;

@end

NS_ASSUME_NONNULL_END
