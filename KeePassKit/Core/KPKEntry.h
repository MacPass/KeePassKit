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

@import Foundation;
#import "KPKNode.h"
#import "KPKModificationRecording.h"
#import "KPKPlatformIncludes.h"

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
FOUNDATION_EXTERN NSString *const KPKMetaEntryKeePassKitGroupUUIDs; // backport of group UUIDS of KDBX files to KDB UUIDs
FOUNDATION_EXTERN NSString *const KPKMetaEntryKeePassKitDeletedObjects; // backport of deleted object of KDBX to KDB files
FOUNDATION_EXTERN NSString *const KPKMetaEntryKeePassKitDatabaseName;
FOUNDATION_EXTERN NSString *const KPKMetaEntryKeePassKitDatabaseDescription;
FOUNDATION_EXTERN NSString *const KPKMetaEntryKeePassKitTrash;
FOUNDATION_EXTERN NSString *const KPKMetaEntryKeePassKitUserTemplates;

/**
 *  Entries hold ciritcal information to store passwords
 *  They contain a list of default key value pairs (password, username, url, etc.)
 *  Additianlly any number of custom attributes can be stored inside an entry as well as binaries and custom autotype information
 */

#if KPK_MAC
@interface KPKEntry : KPKNode <NSCopying, NSSecureCoding, NSPasteboardReading, NSPasteboardWriting>
#else
@interface KPKEntry : KPKNode <NSCopying, NSSecureCoding>
#endif

@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *url;

@property (nonatomic, copy, readonly) NSArray<KPKBinary *> *binaries;
@property (nonatomic, copy) NSArray<NSString *> *tags;
@property (nonatomic, copy) NSUIColor *foregroundColor;
@property (nonatomic, copy) NSUIColor *backgroundColor;
@property (nonatomic, copy) NSString *overrideURL;

@property (nonatomic, copy, readonly) NSArray<KPKAttribute *> *attributes;
@property (nonatomic, copy, readonly) NSArray<KPKAttribute *> *customAttributes;
@property (nonatomic, copy, readonly) NSArray<KPKAttribute *> *defaultAttributes;
@property (nonatomic, readonly) BOOL hasCustomAttributes;

@property (nonatomic, copy, readonly) KPKAutotype *autotype;
@property (nonatomic, copy, readonly) NSArray<KPKEntry *> *history;
@property (nonatomic, readonly) BOOL isHistory;
/**
 *	Additional information is stores in MetaEntrie in KDB files.
 *  This function determines wheter the entry is a meta entry or not.
 *	@return	YES if this entry is a Meta Entry, NO if not
 */
@property (nonatomic, readonly) BOOL isMeta;

- (KPKComparsionResult)compareToEntry:(KPKEntry *)entry;

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
 Generic accessor for any attribute with the key. This will return default as well as custom attributes

 @param key Key for the attribute to retrieve
 @return Attribute with the given key, nil if none was found
 */
- (KPKAttribute *)attributeWithKey:(NSString *)key;
/**
 @param key String that identifies the attributes
 @returns the attribute with the given key
 */
- (KPKAttribute *)customAttributeWithKey:(NSString *)key;
/**
 *  Returns the value for the attribute with the given key
 *
 *  @param key Key for the attribute
 *
 *  @return value of the attriubte matching the key, nil if no matching attributes was found
 */
- (NSString *)valueForAttributeWithKey:(NSString *)key;

- (NSString *)evaluatedValueForAttributeWithKey:(NSString *)key;
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
 *  Binaries need to have unique names inside an entry. The data of a binary is not considered!
 *  If a binary with the same name is present, the newly added binary will get it's name updated!
 *
 *	@param	binary	Binary to add
 */
- (void)addBinary:(KPKBinary *)binary;

/**
 *	Removes the provied Binary from the entry attachments
 *	@param	binary	Binary to be removed
 */
- (void)removeBinary:(KPKBinary *)binary;

/**
 Returns the first binary with the given name.

 @param name name of the binary to find
 @return the first matching binary, otherwise nil
 */
- (KPKBinary *)binaryWithName:(NSString *)name;


#pragma mark History
/**
 * pushes the current state of the entry to the history. This should be done befor any user-initiated modifications are introduced
 * Settings for entry size or count will be considered!
 * If only the count is too high, the oldest history entry will be removed after the new one was added.
 * If the size it so high, KeePassKit removed the oldes entry until the size limit is meet again.
 * This might result in no history entry at all, depending on the settings!
 */
- (void)pushHistory;
/**
 * Removes an entry for the history list.
 */
- (void)removeHistoryEntry:(KPKEntry *)entry;
/**
 *	Clears the history and removes all entries
 */
- (void)clearHistory;
/**
 *  Reverts the Entry to an entry in it's history.
 *
 *  @param entry The history entry to revert to. If the entry is not part of the history of the receiving entry, an assertion is raised.
 */
- (void)revertToEntry:(KPKEntry *)entry;
/**
 * @returns YES if the entry has a history entry equal to entry. Dates are ignored!
 *
 */
- (BOOL)hasHistoryOfEntry:(KPKEntry *)entry;

#pragma mark Maintainance
/**
 *  Calcualtes the size of this entry. Included are all attributes for this entry
 *
 *  @return Size of this entry in bytes
 */
@property (nonatomic, readonly) NSUInteger estimatedByteSize;

@end

