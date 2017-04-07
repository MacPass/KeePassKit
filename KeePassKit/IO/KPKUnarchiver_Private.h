//
//  KPKTreeUnarchiver_Private.h
//  KeePassKit
//
//  Created by Michael Starke on 25/10/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKUnarchiver.h"

@class KPKCompositeKey;

@interface KPKUnarchiver ()

@property (copy) NSData *data;
@property (strong) KPKCompositeKey *key;

@property (copy) NSUUID *cipherUUID;
@property (strong) NSMutableDictionary *mutableKeyDerivationParameters;
@property (assign) NSUInteger version;

- (instancetype)_initWithData:(NSData *)data version:(NSUInteger)version key:(KPKCompositeKey *)key error:(NSError *__autoreleasing *)error;

@end
