//
//  KPKKeyDerivation_Private.h
//  KeePassKit
//
//  Created by Michael Starke on 05/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKKeyDerivation.h"

@interface KPKKeyDerivation ()

+ (NSUUID *)_uuid;
+ (void)_registerKeyDerivation:(Class)derivationClass;

@end
