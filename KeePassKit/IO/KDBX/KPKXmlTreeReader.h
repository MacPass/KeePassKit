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
#import "KPKKdbxFormat.h"

@class KPKTree;
@class KPKXmlTreeReader;
@class KPKBinary;
@class KPKRandomStream;
@class KPKData;

@protocol KPKXmlTreeReaderDelegate <NSObject>

@required
- (KPKData *)reader:(KPKXmlTreeReader *)reader binaryDataForReference:(NSUInteger)reference;
- (KPKRandomStream *)randomStreamForReader:(KPKXmlTreeReader *)reader;
- (NSUInteger)fileVersionForReader:(KPKXmlTreeReader *)reader;
@end

@interface KPKXmlTreeReader : NSObject

@property (readonly, copy) NSData *headerHash;
@property (weak) id<KPKXmlTreeReaderDelegate> delegate;

- (instancetype)initWithData:(NSData *)data delegate:(id<KPKXmlTreeReaderDelegate>)delegate NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithData:(NSData *)data;
- (instancetype)init NS_UNAVAILABLE;

- (KPKTree *)tree:(NSError *__autoreleasing *)error;

@end
