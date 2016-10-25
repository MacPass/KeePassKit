//
//  KPKXmlTreeWriter.h
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

#import <Foundation/Foundation.h>

#import "KPKXmlFormat.h"

NS_ASSUME_NONNULL_BEGIN

@class KPKTree;
@class DDXMLDocument;
@class KPKXmlHeaderWriter;

@interface KPKXmlTreeWriter : NSObject

@property (strong, readonly) KPKTree *tree;

- (instancetype)initWithTree:(KPKTree *)tree randomStreamType:(KPKRandomStreamType)randomType randomStreamKey:(NSData *_Nullable)key headerHash:(NSData *_Nullable)hash;
- (instancetype)initWithTree:(KPKTree *)tree;

@property (nonatomic, readonly, copy) DDXMLDocument *xmlDocument;

@end

NS_ASSUME_NONNULL_END
