//
//  KPKCipher_Private.h
//  KeePassKit
//
//  Created by Michael Starke on 02/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKCipher.h"

@interface KPKCipher ()

+ (void)_registerCipher:(Class)cipherClass;
- (KPKCipher *)_initWithOptions:(NSDictionary *)options;

@end
