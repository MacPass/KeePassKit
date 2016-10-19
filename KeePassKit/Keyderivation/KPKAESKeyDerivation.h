//
//  KPKAESKeyDerication.h
//  KeePassKit
//
//  Created by Michael Starke on 05/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKKeyDerivation.h"

@class KPKNumber;

@interface KPKAESKeyDerivation : KPKKeyDerivation

@property (nonatomic, readonly) uint64_t rounds;
@property (nonatomic, readonly) NSData *seed;

+ (NSDictionary *)optionsWithSeed:(NSData *)seed rounds:(NSUInteger)rounds;

- (instancetype)initWithOptions:(NSDictionary *)options;

@end
