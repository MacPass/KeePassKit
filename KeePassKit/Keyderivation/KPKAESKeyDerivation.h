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

@property (readonly, copy) KPKNumber *rounds;
@property (readonly, copy) NSData *seed;

@end
