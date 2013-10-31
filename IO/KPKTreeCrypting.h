//
//  KPKTreeCryting.h
//  KeePassKit
//
//  Created by Michael Starke on 04.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKTree;
@class KPKCompositeKey;

/**
 *	Protocoll to adhere to to enable encryption and decryption of trees
 */
@protocol KPKTreeCrypting <NSObject>

@required
+ (KPKTree *)decryptTreeData:(NSData *)data withPassword:(KPKCompositeKey *)password error:(NSError **)error;
+ (NSData *)encryptTree:(KPKTree *)tree password:(KPKCompositeKey *)password error:(NSError **)error;

@end
