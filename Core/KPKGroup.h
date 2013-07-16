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
@property(nonatomic, assing) BOOL expires;
@property(nonatomic, readonly) NSArray *groups;
@property(nonatomic, readonly) NSArray *entries;
@property(nonatomic, readonly) NSArray *childEntries;
@property(nonatomic, readonly) NSArray *childGroups;

/*
@property(nonatomic, copy) NSString *notes;
@property(nonatomic, assign) BOOL isExpanded;
@property(nonatomic, copy) NSString *defaultAutoTypeSequence;
@property(nonatomic, copy) NSString *enableAutoType;
@property(nonatomic, copy) NSString *enableSearching;
@property(nonatomic, strong) NSUUID *lastTopVisibleEntry;
@property(nonatomic, assign) BOOL expires;
@property(nonatomic, assign) NSInteger usageCount;
@property(nonatomic, strong) NSDate *locationChanged;
*/

@property(nonatomic, assign) BOOL canAddEntries;

/**
 All actions register with the undomanager and
 thus are undoable.
 Action names aren't set by the model
 */
- (void)remove;
- (void)addGroup:(KPKGroup *)group atIndex:(NSUInteger)index;
- (void)removeGroup:(KPKGroup *)group;
- (void)moveToGroup:(KPKGroup *)group atIndex:(NSUInteger)index;

- (void)addEntry:(KPKEntry *)entry atIndex:(NSUInteger)index;
- (void)removeEntry:(KPKEntry *)entry;
- (void)moveEntry:(KPKEntry *)entry toGroup:(KPKGroup *)toGroup atIndex:(NSUInteger)index;

- (BOOL)containsGroup:(KPKGroup *)group;

/**
 Looks for a entry with the supplied UUID.
 If the UUID is not unique, the first hit will be returned.
 
 @param uuid The UUID to locate entry for;
 @returns Entry that was found, nil if non was found
 */
- (KPKEntry *)entryForUUID:(NSUUID *)uuid;
/**
 Looks for a group with the supplied UUID.
 If the UUID is not unique, the first hit will be returned.
 
 @param uuid The UUID of the group to locate
 @returns Group that matches the uuid, nil if none was found.
 */
- (KPKGroup *)groupForUUID:(NSUUID *)uuid;

@end

