//
//  KPKTree+Serializing.h
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

#import <KeePassKit/KPKTree.h>

@interface KPKTree (Serializing)

/**
 *	Initalizes the Tree with the data contained in the given url
 *	@param	url	URL to load the tree data from
 *	@param	key Key to decrpyt the tree with
 *  @param  error Error if initalization doesnt work
 *	@return	Newly created tree
 */
- (instancetype)initWithContentsOfUrl:(NSURL *)url key:(KPKCompositeKey *)key error:(NSError *__autoreleasing *)error;
/**
 *	Initalizes a tree with the given data. The data is the raw encrypted file data
 *	@param	data	Data to load the tree from. Supply raw undecrypted file data
 *	@param	key Key to decrypt the tree
 *  @param  error Error if initalization doesnt work
 *	@return	Tree with contents of data
 */
- (instancetype)initWithData:(NSData *)data key:(KPKCompositeKey *)key error:(NSError *__autoreleasing *)error;
/**
 *	Creates the tree with the contents of the xml file
 *	@param	url	URL to the xml file to load
 *  @param  error the error object returned on failure
 *	@return	Tree created from the xml data
 */
- (instancetype)initWithXmlContentsOfURL:(NSURL *)url error:(NSError *__autoreleasing *)error;
/**
 Creates a tree with the given XML data

 @param data XML data to load
 @param error error object returned on failure
 @return Tree created from XML data
 */
- (instancetype)initWithXmlData:(NSData *)data error:(NSError *__autoreleasing *)error;
/**
 *	Encrypts the tree with the given password and the version. This operation is possibly lossy
 *	@param	key	The key to encrypt the tree
 *	@param	format The format to write. Possibly lossy
 *	@param	error	error that might occur
 *	@return	data with the encrypted tree
 */
- (NSData *)encryptWithKey:(KPKCompositeKey *)key format:(KPKDatabaseFormat)format error:(NSError *__autoreleasing *)error;
/**
 *	Serializes the tree into the KeePass xml file
 *	@return	XML file string. Pretty printed
 */
@property (nonatomic, readonly, copy) NSData *xmlData;

@end
