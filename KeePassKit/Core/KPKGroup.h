//
//  KPKGroup.h
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
#import <KeePassKit/KPKPlatformIncludes.h>
#import <KeePassKit/KPKTypes.h>
#import <KeePassKit/KPKNode.h>

@class KPKEntry;

FOUNDATION_EXPORT NSString *const KPKGroupUTI;
FOUNDATION_EXPORT NSString *const KPKEntriesArrayBinding;
FOUNDATION_EXPORT NSString *const KPKGroupsArrayBinding;
/**
 *  A group is like a folder in the database.
 *  It can hold subgroups as well as entries.
 *  The tree structure provides a way to inherit certain attributes like search or autotype.
 */
#if KPK_MAC
@interface KPKGroup : KPKNode <NSSecureCoding, NSCopying, NSPasteboardReading, NSPasteboardWriting>
#else
@interface KPKGroup : KPKNode <NSSecureCoding, NSCopying>
#endif

@property(nonatomic, copy, readonly) NSArray<KPKGroup *> *groups; // if you need a performance oriented read only binding interface, use KPKGroupsArrayBinding
@property(nonatomic, copy, readonly) NSArray<KPKEntry *> *entries; // if you need a performance oriented read only bindable interface, use KPKEntriesArrayBinding
@property(nonatomic, copy, readonly) NSArray<KPKEntry *> *childEntries;
@property(nonatomic, copy, readonly) NSArray<KPKGroup *> *childGroups;
@property(nonatomic, copy, readonly) NSArray<KPKNode *> *children;

@property(nonatomic, copy) NSUUID *lastTopVisibleEntry;
@property(nonatomic) BOOL isExpanded;

/**
 All actions register with the undomanager and
 thus are undoable.
 Action names aren't set by the model
 */

- (KPKComparsionResult)compareToGroup:(KPKGroup *)aGroup;

#pragma mark Search
/**
 *	Searches the group for an entry with the supplied NSUUID.
 *  The search does work recursively and searches inside all subgroups
 *
 *	@param	uuid	The UUID of the entry that needs to be found
 *	@return	The entry associated with the UUID or nil if not found
 */
- (KPKEntry *)entryForUUID:(NSUUID *)uuid;
/**
 *	Searches all childgroups to find the group for the supplied UUID
 *
 *	@param	uuid	UUID of the group to look for
 *	@return	group with the matching UUID.
 *  @note   if more than one Group matches, the resutl is the first match.
 */
- (KPKGroup *)groupForUUID:(NSUUID *)uuid;
/**
 *	Returns an array containing all entries inside searchable groups.
 *	@return	NSArray of KPKEntries contained in searchable groups
 */
@property (nonatomic, readonly, copy) NSArray<KPKEntry *> *searchableChildEntries;

@property(nonatomic) KPKInheritBool isSearchEnabled;

#pragma mark Autotype

@property(nonatomic, copy) NSString *defaultAutoTypeSequence;

@property(nonatomic) KPKInheritBool isAutoTypeEnabled;

@property (nonatomic, readonly, copy) NSArray<KPKEntry *> *autotypeableChildEntries;
/**
 *  Returns YES if the entries for this group use Autotype. The value is determined by the isAutotypeEnabled settings
 *  If the setting is KPKInherit, the parent is aksed. If th eroot has KPKInhert, YES is assumed
 *
 *  @return YES if autotype can be used, otherwise NO
 */
@property (nonatomic, readonly) BOOL isAutotypeable;
/**
 *  @return YES if the group has a default autotype sequence. That is none set. NO otherwise
 */
@property(nonatomic, readonly) BOOL hasDefaultAutotypeSequence;

#pragma mark Delete
/**
 *	Removes alle Subentries and Subgroups
 */
- (void)clear;

@end

