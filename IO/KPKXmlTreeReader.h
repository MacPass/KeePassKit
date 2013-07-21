//
//  KPXmlTreeReader.h
//  KeePassKit
//
//  Created by Michael Starke on 20.07.13.
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
@class KPKTree;
@class KPKXmlHeaderReader;

@interface KPKXmlTreeReader : NSObject

/**
 Inilializes the XML Reader with the raw xml data and the random stream
 used to protect containing string fields
 @param data The raw XML data. Make sure to decrypt the data before passing it in
 @param cipherInformation Chipher information to handle the writing
 */
- (id)initWithData:(NSData *)data cipherInformation:(KPKXmlHeaderReader *)cipher;
/**
 @returns
 */
- (KPKTree *)tree;

@end
