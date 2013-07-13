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


#import <Foundation/Foundation.h>
#import "KPKDatabaseVersion.h"

@interface KPKPassword : NSObject

/*
 The password class to be able to decrypt and encrypt databses
 Neither the password nor the keyfile are stored and just read
 and hashed into the composite key.
 
 The Final key is then created before a write or read gets performend
 */

- (id)initWithPassword:(NSString *)password key:(NSURL *)url;
/*
 @return the final Data to use to en/decrypt the database
 */
- (NSData *)finalDataForVersion:(KPKDatabaseVersion )version
                     masterSeed:(NSData *)masterSeed
                  transformSeed:(NSData *)transformSeed
                         rounds:(NSUInteger )rounds;

/*
 @return YES if the password and/or key are correct for this composite key
 */
- (bool)testPassword:(NSString *)password key:(NSURL *)key forVersion:(KPKDatabaseVersion)version;

@end
