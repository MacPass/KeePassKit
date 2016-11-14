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
+ (NSDictionary *)defaultParameters;

/**
 @return the UUID identifiying the key derivation.
 */
+ (NSUUID *)uuid;
+ (void)parametersForDelay:(NSUInteger)seconds completionHandler:(void(^)(NSDictionary *options))completionHandler;


+ (KPKKeyDerivation * _Nullable)keyDerivationWithParameters:(NSDictionary *)parameters;
+ (NSData * _Nullable)deriveData:(NSData *)data withParameters:(NSDictionary *)parameters;
/**
 @return an NSArray containing default initalizied instances of all known key derivations
 */
+ (NSArray<KPKKeyDerivation *> *)availableKeyDerivations;

- (KPKKeyDerivation *)initWithParameters:(NSDictionary *)parameters;

- (NSData * _Nullable)deriveData:(NSData *)data;

- (void)randomize;
/**
 @param parameters an NSDictionary(Variant) with all the values that should be adjustes to the KDF limits.
 @return YES if any value was adjustes. NO if no change did take place.
 */
- (BOOL)adjustParameters:(NSMutableDictionary *)parameters;

@property (readonly, copy, nonatomic) NSUUID *uuid;
@property (readonly, copy) NSDictionary *parameters;
@property (readonly, copy, nonatomic) NSString *name;

@end

NS_ASSUME_NONNULL_END
