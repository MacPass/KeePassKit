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

#import <Foundation/Foundation.h>
#import "KPKTypes.h"
#import "KPKNode.h"

@class KPKEntry;

FOUNDATION_EXPORT NSString *const KPKGroupUTI;

@interface KPKGroup : KPKNode <NSSecureCoding, NSCopying, NSPasteboardReading, NSPasteboardWriting>

@property(nonatomic, readonly) NSArray *groups;
@property(nonatomic, readonly) NSArray *entries;
@property(nonatomic, readonly) NSArray *childEntries;
@property(nonatomic, readonly) NSArray *childGroups;

@property(nonatomic, strong) NSUUID *lastTopVisibleEntry;
@property(nonatomic, assign) BOOL isExpanded;
@property(nonatomic, copy) NSString *defaultAutoTypeSequence;
@property(nonatomic, assign) KPKInheritBool isAutoTypeEnabled;
@property(nonatomic, assign) KPKInheritBool isSearchEnabled;

/**
 All actions register with the undomanager and
 thus are undoable.
 Action names aren't set by the model
 */

- (BOOL)isEqualToGroup:(KPKGroup *)aGroup;

#pragma mark Group manipulation
- (void)addGroup:(KPKGroup *)group;
- (void)addGroup:(KPKGroup *)group atIndex:(NSUInteger)index;
- (void)moveToGroup:(KPKGroup *)group;
- (void)moveToGroup:(KPKGroup *)group atIndex:(NSUInteger)index;

#pragma mark Entry manipulation
- (void)addEntry:(KPKEntry *)entry;
- (void)removeEntry:(KPKEntry *)entry;
- (void)moveEntry:(KPKEntry *)entry toGroup:(KPKGroup *)toGroup;

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
- (NSArray *)searchableChildEntries;

/**
 *	Returns YES if the group is seachable, NO otherwise. The value is determined by the isSeacheEnabled settings
 *  If the settings is KPKInherit, the parent is asked. If the root has set KPKInhertig, YES is assumed
 *	@return	YES if enabled, NO otherwise
 */
- (BOOL)isSearchable;

#pragma mark Autotype

- (NSArray *)autotypeableChildEntries;
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

#pragma mark Hierarchy
/**
 *  @return The breadcrumb of this group separated by dots.
 */
- (NSString *)breadcrumb;
/**
 *  Retursn the path of groups this group is under. The group names a separated by the given separator
 *
 *  @param separator a string that is used as group name separator
 *  @return NSString of the groups breadcrumb.
 */
- (NSString *)breadcrumbWithSeparator:(NSString *)separator;

/**
 *  The index path in the Tree to this group
 *
 *  @return NSIndexPath starting at the root group of the tree
 */
- (NSIndexPath *)indexPath;

#pragma mark Delete
/**
 *	Removes alle Subentries and Subgroups
 */
- (void)clear;

@end

