//
//  KPKTreeArchiver_Private.h
//  KeePassKit
//
//  Created by Michael Starke on 04/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKArchiver.h"

@class KPKTree;

@interface KPKArchiver ()

@property (strong) KPKTree *tree;
@property (strong) KPKCompositeKey *key;

@property (nonatomic, copy) NSData *masterSeed;
@property (nonatomic, copy) NSData *encryptionIV;

- (instancetype)_initWithTree:(KPKTree *)tree key:(KPKCompositeKey *)key NS_DESIGNATED_INITIALIZER;

@end
