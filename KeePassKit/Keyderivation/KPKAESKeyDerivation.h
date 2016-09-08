//
//  KPKAESKeyDerication.h
//  KeePassKit
//
//  Created by Michael Starke on 05/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKKeyDerivation.h"

FOUNDATION_EXPORT NSString *const kKPKAESSeedKey; // NSData 32 bytes
FOUNDATION_EXPORT NSString *const kKPKAESRoundsKey; // KPKNumber unsigned long long

@interface KPKAESKeyDerivation : KPKKeyDerivation

@end
