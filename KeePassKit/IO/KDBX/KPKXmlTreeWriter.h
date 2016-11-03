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

#import "KPKKdbxFormat.h"

NS_ASSUME_NONNULL_BEGIN

@class KPKTree;
@class DDXMLDocument;
@class KPKXmlTreeWriter;
@class KPKBinary;

@protocol KPKXmlTreeWriterDelegate <NSObject>

@required
- (KPKRandomStreamType)randomStreamTypeForWriter:(KPKXmlTreeWriter *)writer ;
- (NSData *)randomStreamKeyForWriter:(KPKXmlTreeWriter *)writer;
- (NSData *)headerHashForWriter:(KPKXmlTreeWriter *)writer;
/**
 Called by the writer to retrieve information who to write entry attachments (KPKBinary)
 If nil is returned by the delegate, the writer will not write any information about binaries into the file (e.g. KDBX4)
 If no binaries are present, return an empty array @[] instead of nil! (e.g. KDBX3.1)
 
 @param writer the calling writer
 @return NSArray containgin the binaries.
 */
- (NSArray *)binariesForWriter:(KPKXmlTreeWriter *)writer;

/**
 Called by the writer to retrieve a unique refernce for a given binary.
 
 @param writer Calling writer
 @param binary The binary to get a reference key for
 @return the unique reference for the binary.
 */
- (NSUInteger)writer:(KPKXmlTreeWriter *)writer referenceForBinary:(KPKBinary *)binary;
@end

@interface KPKXmlTreeWriter : NSObject

@property (strong, readonly) KPKTree *tree;
@property (weak) id<KPKXmlTreeWriterDelegate> delegate;

- (instancetype)initWithTree:(KPKTree *)tree delegate:(id<KPKXmlTreeWriterDelegate> _Nullable)delegate;
- (instancetype)initWithTree:(KPKTree *)tree;

@property (nonatomic, readonly, copy) DDXMLDocument *xmlDocument;

@end

NS_ASSUME_NONNULL_END
