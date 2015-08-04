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
 *	Baseclass for all Nodes in a Tree.
 */
@interface KPKNode : NSObject <NSSecureCoding, KPKModificationRecording>

@property(nonatomic, weak) KPKTree *tree;

@property(nonatomic, assign) NSInteger iconId;
@property(nonatomic, strong) NSUUID *iconUUID;
@property(nonatomic, strong) NSUUID *uuid;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *notes;

@property(nonatomic, assign) KPKVersion minimumVersion;
@property(nonatomic, strong) KPKTimeInfo *timeInfo;

@property(nonatomic, weak) KPKGroup *parent;

@property(nonatomic, readonly) NSUndoManager *undoManager;

@property(nonatomic, readonly, assign) BOOL hasDefaultIcon;
@property(nonatomic, readonly, assign) BOOL isEditable;
@property(nonatomic, readonly) BOOL isTrash;
/**
 *  Determines, whether the receiving node is inside the trash.
 *  The trash group itself is not considered as trashed.
 *  Hence when sending this message with the trash group, NO is returned
 *  @return YES, if the item is inside the trash, NO otherwise (and if item is trash group)
 */
@property (nonatomic, readonly) BOOL isTrashed;

/**
 *  Returns a copy of the node with the given title or a default tile if nil was supplied
 *  @param titelOrNil Title for the copy or default if nil
 *  @return copy of the node with title
 */
- (instancetype)copyWithTitle:(NSString *)titleOrNil options:(KPKCopyOptions)options;

/**
 *	Returns the default icon number for a Group
 *	@return	default icon index for a group
 */
+ (NSUInteger)defaultIcon;

/**
 *	Returns the root group of the node by walking up the tree
 *	@return	root group of the node
 */
- (KPKGroup *)rootGroup;

/**
 *	Determines if the receiving group is an ancestor of the supplied group
 *	@param	group	group to test ancestorship for
 *	@return	YES if reveiver is ancestor of group, NO otherwise
 */
- (BOOL)isAnchestorOf:(KPKNode *)node;

- (BOOL)isDecendantOf:(KPKNode *)node;

- (void)updateToNode:(KPKNode *)node;

- (void)remove;

- (KPKGroup *)asGroup;
- (KPKEntry *)asEntry;

@end
