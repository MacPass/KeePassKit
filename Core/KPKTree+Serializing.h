//
//  KPKTree+Serializing.h
//  MacPass
//
//  Created by Michael Starke on 16.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTree.h"

@interface KPKTree (Serializing)

- (NSData *)serializeWithPassword:(KPKPassword *)password forVersion:(KPKVersion)version error:(NSError *)error;
- (NSString *)serializeXml;

@end
