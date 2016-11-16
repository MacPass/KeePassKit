//
//  KPKAESKeyDerication.h
//  KeePassKit
//
//  Created by Michael Starke on 05/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKKeyDerivation.h"

@class KPKNumber;

// AES Options
FOUNDATION_EXPORT NSString *const KPKAESSeedOption; // NSData 32 bytes
FOUNDATION_EXPORT NSString *const KPKAESRoundsOption; // KPKNumber uint64_t

@interface KPKAESKeyDerivation : KPKKeyDerivation

@property (nonatomic, assign) uint64_t rounds;

@end
