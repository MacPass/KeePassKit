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
#import "KPKNode.h"

@class KPKEntry;

@interface KPKGroup : KPKNode

@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *notes;
@property(nonatomic, assign) BOOL expires;
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
#pragma mark Group manipulation
- (void)remove;
- (void)addGroup:(KPKGroup *)group;
- (void)addGroup:(KPKGroup *)group atIndex:(NSUInteger)index;
- (void)removeGroup:(KPKGroup *)group;
- (void)moveToGroup:(KPKGroup *)group atIndex:(NSUInteger)index;

#pragma mark Entry manipulation
- (void)addEntry:(KPKEntry *)entry;
- (void)addEntry:(KPKEntry *)entry atIndex:(NSUInteger)index;
- (void)removeEntry:(KPKEntry *)entry;
- (void)moveEntry:(KPKEntry *)entry toGroup:(KPKGroup *)toGroup atIndex:(NSUInteger)index;

#pragma mark Search
/**
 *	Determines if a given group is contained inside this group
 *  The search works recursively that is, it finds groups that are inside subgroups as well
 *  as direct child groups
 *
 *	@param	group	the group that should be searched for
 *	@return	YES if the group is contained inside this group, NO otherwise
 */
- (BOOL)containsGroup:(KPKGroup *)group;

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

@end

