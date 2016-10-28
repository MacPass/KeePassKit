//
//  KPKCipher_Private.h
//  KeePassKit
//
//  Created by Michael Starke on 02/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKCipher.h"

@interface KPKCipher ()

@property (nonatomic, copy) NSData *key;
@property (nonatomic, copy) NSData *initializationVector;

+ (void)_registerCipher:(Class)cipherClass;

@end
