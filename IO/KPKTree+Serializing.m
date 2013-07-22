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

#import "KPKMetaData.h"
#import "KPKXmlTreeWriter.h"
#import "DDXMLDocument.h"
#import "KPKPassword.h"

@implementation KPKTree (Serializing)

- (NSData *)serializeWithPassword:(KPKPassword *)password forVersion:(KPKVersion)version error:(NSError *)error {
  NSData *passwordData = [password finalDataForVersion:version masterSeed:nil transformSeed:nil rounds:self.metadata.rounds];
  /*
   Create Stream for strong
   Add Serailized data
   return data
   */
  return nil;
}

- (NSString *)serializeXml {
  KPKXmlTreeWriter *treeWriter = [[KPKXmlTreeWriter alloc] initWithTree:self];
  return [[treeWriter xmlDocument] XMLStringWithOptions:DDXMLNodeCompactEmptyElement|DDXMLNodePrettyPrint];
}

- (NSData *)_serializeVersion1WithPassword:(KPKPassword *)password error:(NSError *)error {
  return nil;
}

- (NSData *)_serializeVersion2WithPassword:(KPKPassword *)password error:(NSError *)error {
  KPKXmlTreeWriter *treeWriter = [[KPKXmlTreeWriter alloc] initWithTree:self];
  NSData *data = [[treeWriter xmlDocument] XMLDataWithOptions:DDXMLNodeCompactEmptyElement];
  // Process Data
  return data;
}

@end
