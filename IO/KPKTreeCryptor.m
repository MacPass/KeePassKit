//
//  KPKDataCryptor.m
//  KeePassKit
//
//  Created by Michael Starke on 21.07.13.
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

#import "KPKTreeCryptor.h"

#import "KPKLegacyTreeCryptor.h"
#import "KPKXmlTreeCryptor.h"

#import "KPKTree.h"
#import "KPKPassword.h"
#import "KPKFormat.h"

@implementation KPKTreeCryptor

+ (id)treeCryptorWithData:(NSData *)data password:(KPKPassword *)passord {
  KPKVersion version = [[KPKFormat sharedFormat] databaseVersionForData:data];
  
  if(version == KPKVersion1) {
    return [[KPKLegacyTreeCryptor alloc] init];
  }
  if(version == KPKVersion2) {
    return [[KPKXmlTreeCryptor alloc] init];
  }
  return nil;
}

- (id)initWithData:(NSData *)data passwort:(KPKPassword *)password {
  self = [super init];
  if(self) {
    _password = password;
    _data = data;
  }
  return self;
}

- (NSData *)encryptTree:(NSError *__autoreleasing *)error {
  return nil;
}

- (KPKTree *)decryptTree:(NSError *__autoreleasing *)error {
  return nil;
}

@end
