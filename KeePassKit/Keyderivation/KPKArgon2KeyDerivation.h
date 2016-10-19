//
//  KPKAnon2KeyDerivation.h
//  KeePassKit
//
//  Created by Michael Starke on 13/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKKeyDerivation.h"


@interface KPKArgon2KeyDerivation : KPKKeyDerivation


- (instancetype)initWithOptions:(NSDictionary *)options;
+ (void)_test;

@end
