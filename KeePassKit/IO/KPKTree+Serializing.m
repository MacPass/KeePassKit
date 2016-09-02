//
//  KPKTree+Serializing.m
//  KeePassKit
//
//  Created by Michael Starke on 16.07.13.
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

#import "KPKTree+Serializing.h"

#import "KPKXmlTreeCryptor.h"
#import "KPKLegacyTreeCryptor.h"
#import "KPKFormat.h"
#import "KPKMetaData.h"
#import "KPKXmlTreeWriter.h"
#import "KPKXmlTreeReader.h"
#import "DDXMLDocument.h"
#import "KPKCompositeKey.h"
#import "KPKErrors.h"

@implementation KPKTree (Serializing)

- (instancetype)initWithContentsOfUrl:(NSURL *)url password:(KPKCompositeKey *)password error:(NSError *__autoreleasing *)error {
  NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:error];
  if(!data) {
    return nil;
  }
  self = [self initWithData:data password:password error:error];
  return self;
}

- (instancetype)initWithData:(NSData *)data password:(KPKCompositeKey *)password error:(NSError *__autoreleasing *)error {
  self = [self _decryptorForData:data password:password error:error];
  return self;
}

- (instancetype)initWithXmlContentsOfURL:(NSURL *)url error:(NSError *__autoreleasing *)error {
  NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:error];
  if(!data) {
    return nil;
  }
  KPKXmlTreeReader *reader = [[KPKXmlTreeReader alloc] initWithData:data headerReader:nil];
  self = [reader tree:error];
  return self;
}

- (NSData *)encryptWithPassword:(KPKCompositeKey *)password forVersion:(KPKDatabaseType)version error:(NSError **)error {
  switch(version) {
    case KPKDatabaseTypeBinary:
      return [KPKLegacyTreeCryptor encryptTree:self password:password error:error];
    case KPKDatabaseTypeXml:
      return [KPKXmlTreeCryptor encryptTree:self password:password error:error];
    default:
      KPKCreateError(error, KPKErrorUnknownFileFormat, @"ERROR_UNKNOWN_FILE_FORMAT", "");
      return nil;
  }
  return nil;
}

- (NSData *)xmlData {
  KPKXmlTreeWriter *treeWriter = [[KPKXmlTreeWriter alloc] initWithTree:self];
  return [[treeWriter xmlDocument] XMLDataWithOptions:DDXMLNodeCompactEmptyElement|DDXMLNodePrettyPrint];
}

- (KPKTree *)_decryptorForData:(NSData *)data password:(KPKCompositeKey *)password error:(NSError **)error {
  KPKFileInfo info = [[KPKFormat sharedFormat] fileInfoForData:data];
  
  if(info.type == KPKDatabaseTypeBinary) {
    return [KPKLegacyTreeCryptor decryptTreeData:data withPassword:password error:error];
  }
  if(info.type == KPKDatabaseTypeXml) {
    return [KPKXmlTreeCryptor decryptTreeData:data withPassword:password error:error];
  }
  KPKCreateError(error, KPKErrorUnknownFileFormat, @"ERROR_UNKNOWN_FILE_FORMAT", "");
  return nil;
}
@end
