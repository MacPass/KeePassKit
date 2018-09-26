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

#import "KPKFormat.h"

@class KPKKeyDerivation;
@class KPKCipher;

/**
 *  The Composite Key to be used for encryption and decryption of databases
 *  It does not store key  nor password strings rather creates a composite key
 *  every time the password or keyfile is set.
 */
@interface KPKCompositeKey : NSObject
/**
 *  YES if the composite key has a password or keyfile set - that is, it's considered usable
 */
@property (nonatomic, readonly) BOOL hasPasswordOrKeyFile;

@property (nonatomic, readonly, getter=isValid) BOOL valid;
/**
 *  YES if the composite key has a password with a lenght longer than 0.
 *  Since a composite key can be created with am empty string as password or without one,
 *  this property considers both ways as no password given, although technically and emptry string is a password
 */
@property (nonatomic, readonly) BOOL hasPassword;
@property (nonatomic, readonly) BOOL hasKeyFile;
/*
 The password class to be able to decrypt and encrypt databses
 Neither the password nor the keyfile are stored and just read
 and hashed into the composite key.
 
 The Final key is then created before a write or read gets performend
 */
- (instancetype)initWithPassword:(NSString *)password keyFileData:(NSData *)keyFileData;
/**
 *  Updates the password and keyfile for the composite key
 *  @param password the new password, can be nil
 *  @param key      the new key file URL, can be nil
 */
- (void)setPassword:(NSString *)password andKeyFileData:(NSData *)keyFileData;

/*
 @return YES if the password and/or key are correct for this composite key
 */
- (BOOL)testPassword:(NSString *)password keyFileData:(NSData *)keyFileData forVersion:(KPKDatabaseFormat)version;

- (NSData *)computeKeyDataForFormat:(KPKDatabaseFormat)format masterseed:(NSData *)seed cipher:(KPKCipher *)cipher keyDerivation:(KPKKeyDerivation *)keyDerivation hmacKey:(NSData **)hmacKey error:(NSError *__autoreleasing *)error;

@end
