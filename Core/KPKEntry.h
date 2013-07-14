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

@interface KPKEntry : KPKNode {
@private
  NSMutableArray *_attachments;
  NSMutableArray *_tags;
  NSMutableDictionary *_attributes;
}

@property (nonatomic, assign) NSString *title;
@property (nonatomic, assign) NSString *password;
@property (nonatomic, assign) NSString *username;
@property (nonatomic, assign) NSString *url;
@property (nonatomic, assign) NSString *notes;


@property (nonatomic, strong) NSArray *attachmets;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSDictionary *attributes;

- (void)remove;

/**
 @param key String that identifies the attributes
 @returns the Value for the given attribute, nil if it's not set
 */
- (NSString *)attributeForKey:(NSString *)key;
/**
 Adds an attribute with value for the key
 @param value Value for the attribute
 @param key Identfying key for the attributes. Needs to be unique
 */
- (void)addAttribute:(NSString *)value forKey:(NSString *)key;
/**
 Sets the new value for the given attribute key
 @param value The new value for the attribute
 @param key Identifyer for the attribute
 */
- (void)setAttribute:(NSString *)value forKey:(NSString *)key;
/**
 Removes the attribute for the given string
 @param Identifiy for the attribute to be removed
 */
- (void)removeAttributeForKey:(NSString *)key;

/**
 Adds the given attachment
 @param attachment Attachment to add to the entry
 */
- (void)addAttachment:(KPKAttachment *)attachment;
/**
 Removes the given attachment
 @param attachment The attachment to be removed
 */
- (void)removeAttachment:(KPKAttachment *)attachment;

@end
