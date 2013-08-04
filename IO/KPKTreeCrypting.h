//
//  KPKTreeCryting.h
//  KeePassKit
//
//  Created by Michael Starke on 04.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKTree;
@class KPKPassword;

/**
 *	Protocoll to adhere to to enable encryption and decryption of trees
 */
@protocol KPKTreeCrypting <NSObject>

@required
+ (KPKTree *)decryptTreeData:(NSData *)data withPassword:(KPKPassword *)password error:(NSError **)error;
+ (NSData *)encryptTree:(KPKTree *)tree password:(KPKPassword *)password error:(NSError **)error;

@end
