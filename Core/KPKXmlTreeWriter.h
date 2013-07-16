//
//  KPKXmlTreeWriter.h
//  MacPass
//
//  Created by Michael Starke on 16.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKTree;
@class DDXMLDocument;

@interface KPKXmlTreeWriter : NSObject

@property (strong, readonly) KPKTree *tree;

- (id)initWithTree:(KPKTree *)tree;
- (DDXMLDocument *)xmlDocument;

@end
