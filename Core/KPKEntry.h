//
//  KPKEntry.h
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
#import "KPKNode.h"

@class KPKGroup;
@class KPKAttachment;
@class KPKAttribute;

@interface KPKEntry : KPKNode <NSCopying>

@property (nonatomic, assign) NSString *title;
@property (nonatomic, assign) NSString *password;
@property (nonatomic, assign) NSString *username;
@property (nonatomic, assign) NSString *url;
@property (nonatomic, assign) NSString *notes;

@property (nonatomic, strong) NSArray *attachmets;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSMutableArray *customAttributes;

- (void)remove;
/**
 @param key String that identifies the attributes
 @returns the attribute with the given key
 */
- (KPKAttribute *)customAttributeForKey:(NSString *)key;
/**
 @returns YES, if the supplied key is a key in the attributes of this entry
 */
- (BOOL)hasAttributeWithKey:(NSString *)key;
/**
 @returns a unique key for the proposed key.
 */
- (NSString *)proposedKeyForAttributeKey:(NSString *)key;
/**
 Adds an attribute to the entry
 @param attribute The attribute to be added
 @param index the position at wicht to add the attribute
 */
- (void)addCustomAttribute:(KPKAttribute *)attribute atIndex:(NSUInteger)index;
- (void)addCustomAttribute:(KPKAttribute *)attribute;
/**
 Removes the attribute for the given string
 @param attribute The attribute to be removed
 */
- (void)removeCustomAttribute:(KPKAttribute *)attribute;

/**
 Adds the given attachment
 @param attachment Attachment to add to the entry
 @param index The position at whicht to att the attachment
 */
- (void)addAttachment:(KPKAttachment *)attachment atIndex:(NSUInteger)index;
- (void)addAttachment:(KPKAttachment *)attachment;
/**
 Removes the given attachment
 @param attachment The attachment to be removed
 */
- (void)removeAttachment:(KPKAttachment *)attachment;
/**
 Adds the tag to the entry
 @param tag The tag to be added
 @param index The location for the new tag
 */
- (void)addTag:(NSString *)tag atIndex:(NSUInteger)index;
- (void)addTag:(NSString *)tag;
/**
 Removes the given tag from the entry
 @param tag The tag to be removed
 */
- (void)removeTag:(NSString *)tag;
@end
