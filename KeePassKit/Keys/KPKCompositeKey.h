//
//  KPKPassword.h
//  KeePassKit
//
//  Created by Michael Starke on 12.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

@import Foundation;

#import <KeePassKit/KPKFormat.h>

@class KPKKeyDerivation;
@class KPKCipher;
@class KPKKey;

/**
 *  The Composite Key to be used for encryption and decryption of databases
 *  It does not store key nor password strings rather creates a composite key
 *  every time the password or keyfile is set.
 */
@interface KPKCompositeKey : NSObject <NSSecureCoding>
/**
 *  YES if the composite key has some form of key set.
 */
@property (nonatomic, readonly) BOOL hasKeys;
/** Creates a composite key with the supplied keys
 @param keys an array of keys to be used for the composite key. The key is order-dependant!
 */
- (instancetype)initWithKeys:(NSArray <KPKKey *>*)keys;

- (BOOL)isEqualToKey:(KPKCompositeKey *)key;

/**
 Add a key to the composite key. The key is order dependant.
 If you add the same keys in a differnt order, the final key is different!
 @param key the key to be added. Re-adding the same key has no effect

 */
- (BOOL)addKey:(KPKKey *)key;

- (BOOL)hasKeyOfClass:(Class)keyClass;

/**
 Derives the final key data for the supplied parameters
 @param format The database format to use the key for (kbd or kdbx)
 @param seed the seed for the key derivation
 @param cipher the cipher to use
 @param keyDerivation the key derivation to use
 @param hmacKey output for hmac check
 @param error output of errors while deriving the key
 */
- (NSData *)computeKeyDataForFormat:(KPKDatabaseFormat)format masterseed:(NSData *)seed cipher:(KPKCipher *)cipher keyDerivation:(KPKKeyDerivation *)keyDerivation hmacKey:(NSData **)hmacKey error:(NSError *__autoreleasing *)error;

@end
