//
//  KPKTreeReading.h
//  KeePassKit
//
//  Created by Michael Starke on 24.07.13.
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
@protocol KPKHeaderReading;

/**
 *	Protocoll for tree reader
 */
@protocol KPKTreeReading <NSObject>

@required
/**
 *	Initalizes the Treereader with the fiven data
 *	@param	data raw data to read the tree. Any decryptiong is handled by the TreeCryptor
 *	@param	headerReader	the used headerreader to parst the header for this data
 *	@return	instance of tree reader
 */
- (instancetype)initWithData:(NSData *)data headerReader:(id<KPKHeaderReading>)headerReader;

/**
 *	Reads the data and creates a tree from it
 *	@param	error	Error object.
 *	@return	initalizes tree object
 */
- (KPKTree *)tree:(NSError *__autoreleasing*)error;

@end
