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

@import Cocoa;
#import "KPKNode.h"
#import "KPKModificationRecording.h"

@class KPKGroup;
@class KPKBinary;
@class KPKAttribute;
@class KPKAutotype;

/* Entries declared as MetaEntries in KDB files
 * contain information that is stored in meta data in KDBX file
 */
FOUNDATION_EXTERN NSString *const KPKMetaEntryBinaryDescription;
FOUNDATION_EXTERN NSString *const KPKMetaEntryTitle;
FOUNDATION_EXTERN NSString *const KPKMetaEntryUsername;
FOUNDATION_EXTERN NSString *const KPKMetaEntryURL;

/* Commonly known meta entries */

FOUNDATION_EXTERN NSString *const KPKMetaEntryUIState;
FOUNDATION_EXTERN NSString *const KPKMetaEntryDefaultUsername;
FOUNDATION_EXTERN NSString *const KPKMetaEntrySearchHistoryItem;
FOUNDATION_EXTERN NSString *const KPKMetaEntryCustomKVP;
FOUNDATION_EXTERN NSString *const KPKMetaEntryDatabaseColor;
FOUNDATION_EXTERN NSString *const KPKMetaEntryKeePassXCustomIcon;
FOUNDATION_EXTERN NSString *const KPKMetaEntryKeePassXCustomIcon2;
FOUNDATION_EXTERN NSString *const KPKMetaEntryKeePassXGroupTreeState;

@interface KPKEntry : KPKNode <NSCopying, NSSecureCoding, NSPasteboardWriting, NSPasteboardReading>

@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *url;

@property (nonatomic, strong) NSArray<KPKBinary *> *binaries;
@property (nonatomic, copy) NSArray<NSString *> *tags;
@property (nonatomic, copy) NSColor *foregroundColor;
@property (nonatomic, copy) NSColor *backgroundColor;
@property (nonatomic, copy) NSString *overrideURL;

@property (nonatomic, copy, readonly) NSArray<KPKAttribute *> *attributes;
@property (nonatomic, copy, readonly) NSArray<KPKAttribute *> *customAttributes;
@property (nonatomic, copy, readonly) NSArray<KPKAttribute *> *defaultAttributes;

@property (nonatomic, copy, readonly) KPKAutotype *autotype;
@property (nonatomic, copy, readonly) NSArray<KPKEntry *> *history;
@property (nonatomic, readonly) BOOL isHistory;
/**
 *	Additional information is stores in MetaEntrie in KDB files.
 *  This function determines wheter the entry is a meta entry or not.
 *	@return	YES if this entry is a Meta Entry, NO if not
 */
@property (nonatomic, readonly) BOOL isMeta;

/**
 *  Test for Equality
 *  @param entry entry to test for equality
 *  @return YES if receiver is equal to entry based on all attributes. UUID and parents are NOT considered
 */
- (BOOL)isEqualToEntry:(KPKEntry *)entry;

/**
 *  Moves the Entry the the new group at the given index
 *
 *  @param group The new group that should contain the entry
 *  @param index The index at which to sort the entry into the existing entries of the group
 */
- (void)moveToGroup:(KPKGroup *)group;

#pragma mark MetaEntries
/**
 *	Creates KDB meta entry with the given data and name
 *	@param	data	data to store in the entry
 *  @param  name  the name of the metaentry
 *	@return	a meta entry that can be serailized
 */
+ (KPKEntry *)metaEntryWithData:(NSData *)data name:(NSString *)name;

#pragma mark Generic Attribute manipulation

/**
 @param key String that identifies the attributes
 @returns the attribute with the given key
 */
- (KPKAttribute *)customAttributeForKey:(NSString *)key;
/**
 *  Returns the value for the attribute with the given key
 *
 *  @param key Key for the attribute
 *
 *  @return value of the attriubte matching the key, nil if no matching attributes was found
 */
- (NSString *)valueForAttributeWithKey:(NSString *)key;
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
 */
- (void)addCustomAttribute:(KPKAttribute *)attribute;
/**
 Removes the attribute for the given string
 @param attribute The attribute to be removed
 */
- (void)removeCustomAttribute:(KPKAttribute *)attribute;

#pragma mark Binaries

/**
 *	Adds the given Binary to the binaries of this entry
 *	@param	binary	Binary to add
 */
- (void)addBinary:(KPKBinary *)binary;

/**
 *	Removes the provied Binary from the entry attachments
 *	@param	binary	Binary to be removed
 */
- (void)removeBinary:(KPKBinary *)binary;

#pragma mark History

/**
 *	Adds an Item to the Entries history
 *	@param	entry	Entry element to be added as history
 */
- (void)addHistoryEntry:(KPKEntry *)entry;
- (void)removeHistoryEntry:(KPKEntry *)entry;
/**
 *	Clears the history and removes all entries
 */
- (void)clearHistory;

#pragma mark Maintainance
/**
 *  Calcualtes the size of this entry. Included are all attributes for this entry
 *
 *  @return Size of this entry in bytes
 */
@property (nonatomic, readonly) NSUInteger estimatedByteSize;

@end

