//
//  KPKKeyDerivation.h
//  KeePassKit
//
//  Created by Michael Starke on 05/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const KPKKeyDerivationOptionUUID;

/**
 Common interface to create and work with key derivations.
 */
@interface KPKKeyDerivation : NSObject

/**
 Returns a VariantDictionary with all required options initialized with default values.
 The seed is also included and randomized.

 @return NSDictionary(Variant) with default parameters
 */
+ (NSDictionary *)defaultOptions;

/**
 @return the UUID identifiying the key derivation.
 */
+ (NSUUID *)uuid;
+ (void)parametersForDelay:(NSUInteger)seconds completionHandler:(void(^)(NSDictionary *options))completionHandler;

+ (KPKKeyDerivation * _Nullable)keyDerivationWithOptions:(NSDictionary *)options;
+ (NSData * _Nullable)deriveData:(NSData *)data wihtOptions:(NSDictionary *)options;

/**
 @return an NSArray containing default initalizied instances of all known key derivations
 */
+ (NSArray<KPKKeyDerivation *> *)availableKeyDerivations;

- (KPKKeyDerivation *)initWithOptions:(NSDictionary *)options;

- (NSData * _Nullable)deriveData:(NSData *)data;

- (void)randomize;

@property (readonly, copy, nonatomic) NSUUID *uuid;
@property (readonly, copy) NSDictionary *options;

@end

NS_ASSUME_NONNULL_END
