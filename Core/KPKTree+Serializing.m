//
//  KPKTree+Serializing.m
//  MacPass
//
//  Created by Michael Starke on 16.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTree+Serializing.h"

#import "KPKXmlTreeWriter.h"
#import "DDXMLDocument.h"
#import "KPKPassword.h"

@implementation KPKTree (Serializing)

- (NSData *)serializeWithPassword:(KPKPassword *)password forVersion:(KPKVersion)version error:(NSError *)error {
  NSData *passwordData = [password finalDataForVersion:version masterSeed:nil transformSeed:nil rounds:self.rounds];
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
