//
//  KPKNode.h
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
#import "KPKVersion.h"
#import "KPKModificationRecording.h"

@class KPKEntry;
@class KPKEditingSession;
@class KPKGroup;
@class KPKIcon;
@class KPKTimeInfo;
@class KPKTree;

typedef NS_OPTIONS(NSUInteger, KPKCopyOptions) {
  kKPKCopyOptionNone               = 0,    // No option
  kKPKCopyOptionCopyHistory        = 1<<0, // KPKEntry only - make a copy of the soures' history.
  kKPKCopyOptionReferenceUsername  = 1<<1, // KPKEntry only - copy refernces the username of the source
  kKPKCopyOptionReferencePassword  = 1<<2, // KPKEntry only - copy references the password of the source
};

/**
 *  Abstract base class for all Nodes (Entries and Groups)
 *  Do not instanciate an instance of KPKnode
 */
@interface KPKNode : NSObject <KPKModificationRecording>

@property(nonatomic) NSInteger iconId;
@property(nonatomic, strong) NSUUID *iconUUID;
@property(nonatomic, readonly, strong) NSUUID *uuid;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *notes;

@property(nonatomic, readonly) KPKVersion minimumVersion;
@property(nonatomic, copy, readonly) KPKTimeInfo *timeInfo;

@property(nonatomic, weak) KPKGroup *parent;

@property(nonatomic, readonly) NSUndoManager *undoManager;

@property(nonatomic, readonly) BOOL hasDefaultIcon;
@property(nonatomic, readonly) BOOL isEditable;
@property(nonatomic, readonly) BOOL isTrash;
@property(nonatomic, readonly) BOOL isUserTemplate;
@property(nonatomic, readonly) BOOL isUserTemplateGroup;
@property(nonatomic, readonly) BOOL deleted;
/**
 *  Determines, whether the receiving node is inside the trash.
 *  The trash group itself is not considered as trashed.
 *  Hence when sending this message with the trash group, NO is returned
 *  @return YES, if the item is inside the trash, NO otherwise (and if item is trash group)
 */
@property (nonatomic, readonly) BOOL isTrashed;

/**
 *	Returns the default icon number for a Group
 *	@return	default icon index for a group
 */
+ (NSUInteger)defaultIcon;

/**
 *  Returns a copy of the node assigned with a new UUID. Use copy on KPKEntry or KPKGroup to get a carbon copy
 *
 *  @param titleOrNil title for the new node, if nil a default title is generated
 *  @param options    options for the specific copy
 *
 *  @return copied node
 */
- (instancetype)copyWithTitle:(NSString *)titleOrNil options:(KPKCopyOptions)options;

/**
 *  Creates a new node with the given UUID or generates a new of if nil was supplied
 *
 *  @param uuid uuid for the node. Use nil if you want a newly generated one
 *
 *  @return newly created node
 */
- (instancetype)initWithUUID:(NSUUID *)uuid;

- (BOOL)isEqualToNode:(KPKNode *)aNode;

/**
 *	Returns the root group of the node by walking up the tree
 *	@return	root group of the node
 */
@property (nonatomic, readonly) KPKGroup *rootGroup;
/**
 *	Determines if the receiving group is an ancestor of the supplied group
 *	@param	group	group to test ancestorship for
 *	@return	YES if reveiver is ancestor of group, NO otherwise
 */
- (BOOL)isAnchestorOf:(KPKNode *)node;

- (BOOL)isDecendantOf:(KPKNode *)node;
/**
 *  Trashes the node. Respects the settings for trash handling
 *  a) trash is enabled: If no trash is present, a trash group is created and the node is moved to the trash group
 *  b) trash is disabled: removes the node.
 */
- (void)trashOrRemove;

- (void)remove;

@property(nonatomic, readonly) KPKGroup *asGroup;
@property(nonatomic, readonly) KPKEntry *asEntry;

#pragma mark Editing
/**
 *  Signals the Node there are changes to be made. Previous uncommited changes will get dropped.
 *
 *  @return A shallow copy of the node suitabel for editing.
 */
- (void)beginEditing;
/**
 *  Discards the editing changes.
 *
 *  @return YES if any changes were discared, NO otherwise
 */
- (BOOL)cancelEditing;
/**
 *  Commits the changes from the current open editing, stores the data (KPKEntries add a history entry with old values as well)
 *  If nothing was changes during the edit, nothing will changes
 *
 *  @return YES if any changes were store, NO otherwise
 */
- (BOOL)commitEditing;

@end
