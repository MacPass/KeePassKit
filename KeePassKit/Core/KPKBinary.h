//
//  KPKBinaryData.h
//  KeePassKit
//
//  Created by Michael Starke on 12.07.13.
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

/* Binary */
@interface KPKBinary : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSData *data;
@property (nonatomic) BOOL protect;

/**
 @param name The name for the attachment, usually this should be the filename with extension
 @param data The image data .
 @return Attachment initalized with the given data and name, nil if errors occured
 */
- (instancetype)initWithName:(NSString *)name data:(NSData *)data NS_DESIGNATED_INITIALIZER;
/**
 @param url Location of the file to use
 @returns Attachment initalized with the name and data from the given file URL. nil if errors occured
 */
- (instancetype)initWithContentsOfURL:(NSURL *)url;

- (BOOL)isEqualtoBinary:(KPKBinary *)binary;

- (BOOL)saveToLocation:(NSURL *)location error:(NSError *__autoreleasing *)error;

@end
