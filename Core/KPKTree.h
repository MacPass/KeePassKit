//
//  KPKTree.h
//  KeePassKit
//
//  Created by Michael Starke on 11.07.13.
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
#import "KPKVersion.h"
#import "KPKNode.h"

@class KPKGroup;
@class KPKEntry;
@class KPKCompositeKey;
@class KPKIcon;
@class KPKMetaData;

@protocol KPKTreeDelegate <NSObject>

@optional
/**
 *  Allows the delegate to return a default autotype sequence
 *
 *  @return the default autotype sequence to be used
 */
- (NSString *)defaultAutotypeSequenceForTree:(KPKTree *)tree;
/**
 *  Is called whenever the tree wants to issue a modification
 *
 *  @param tree Tree asking if it can be modified
 *
 *  @return YES if the tree can be modified, otherwise NO
 */
- (BOOL)shouldEditTree:(KPKTree *)tree;

@end

@interface KPKTree : NSObject

@property(nonatomic, weak) id<KPKTreeDelegate> delegate;
@property(nonatomic, strong, readonly) NSMutableDictionary *deletedObjects;
@property(nonatomic, strong) KPKMetaData *metaData;
@property(nonatomic, weak) NSUndoManager *undoManager;

@property(nonatomic, readonly, assign) BOOL isEditable;

@property (nonatomic, strong) KPKGroup *root;
/**
 Acces to the root group via the groups property
 to offer a bindable interface for a tree
 */
@property (nonatomic, readonly) NSArray *groups;
/**
 *	NSArray of KPKGroup objects. Contains all child groups in a tree.
 *  @note The root group is missing from this array
 */
@property (nonatomic, readonly) NSArray *allGroups;
/**
 *	NSArray of KPKEntries. Contains all entries of the tree
 */
@property (nonatomic, readonly) NSArray *allEntries;
/**
 *  NSArray of KPKEntries that are History elements
 */
@property (nonatomic, readonly) NSArray *allHistoryEntries;
/**
 *	The minimum Version of the tree. If any node uses higher
 *  featuers, the whole tree needs to have the highest version
 */
@property (nonatomic, assign) KPKVersion minimumVersion;
/**
 *  Tags on this tree. This is a aggregation of all Tags of entries
 */
@property (nonatomic, strong, readonly) NSArray *tags;

+ (KPKTree *)allocTemplateTree;

- (KPKGroup *)createGroup:(KPKGroup *)parent;
- (KPKEntry *)createEntry:(KPKGroup *)parent;

/**
 *  Returns the defautl autotype squence for this tree. If a delegate is set, it is asked for the sequence.
 *
 *  @return defautl sequence, or nil if none is set
 */
- (NSString *)defaultAutotypeSequence;

- (void)registerTags:(NSString *)tags forEntry:(KPKEntry *)entry;
- (void)deregisterTags:(NSString *)tags forEntry:(KPKEntry *)entry;
@end
