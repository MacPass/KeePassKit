//
//  KPKTreeUnarchiver_Private.h
//  KeePassKit
//
//  Created by Michael Starke on 25/10/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTreeUnarchiver.h"

@class KPKCompositeKey;

@interface KPKTreeUnarchiver ()

@property (copy) NSData *data;
@property (strong) KPKCompositeKey *key;

@property (copy) NSMutableDictionary *mutableKeyDerivationOptions;
@property (copy) NSUUID *keyDerivationUUID;
@property (assign) NSUInteger version;

- (instancetype)_initWithData:(NSData *)data version:(NSUInteger)version key:(KPKCompositeKey *)key error:(NSError **)error;

@end
