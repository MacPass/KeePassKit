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
#import <KeePassKit/KPKTypes.h>
#import <KeePassKit/KPKFormat.h>
#import <KeePassKit/KPKModificationRecording.h>

@class KPKEntry;
@class KPKGroup;
@class KPKIcon;
@class KPKTimeInfo;
@class KPKTree;
@class KPKBinary;

typedef NS_OPTIONS(NSUInteger, KPKCopyOptions) {
  kKPKCopyOptionNone               = 0,    // No option
  kKPKCopyOptionCopyHistory        = 1<<0, // KPKEntry only - make a copy of the soures' history.
  kKPKCopyOptionReferenceUsername  = 1<<1, // KPKEntry only - copy refernces the username of the source
  kKPKCopyOptionReferencePassword  = 1<<2, // KPKEntry only - copy references the password of the source
};

/// Abstract base class for all Nodes (Entries and Groups)
/// Do not instanciate an instance of KPKnode
@interface KPKNode : NSObject <KPKModificationRecording>

/// Indexes are independet for KPKGroups and KPKEntries. Henve a group and and entry inside the same parent group can share the same index!
/// @return The Index of the Node inside it's parent.
@property(nonatomic, readonly) NSUInteger index;

@property(nonatomic) NSInteger iconId;
@property(nonatomic, copy) NSUUID *iconUUID;
@property(nonatomic, readonly, strong) KPKIcon *icon;
@property(nonatomic, readonly, copy) NSUUID *uuid;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *notes;
@property(nonatomic, copy) NSArray<NSString *> *tags; // FIXME: Move to NSSet?
@property(nonatomic, readonly, copy) NSDictionary<NSString *, NSString *> *customData;

@property(nonatomic, readonly, copy) KPKTimeInfo *timeInfo;

@property(nonatomic, readonly, weak) KPKGroup *parent;
@property(nonatomic, readonly, copy) NSUUID *previousParent;
@property(nonatomic, readonly, weak) KPKTree *tree;

@property(nonatomic, readonly) NSUndoManager *undoManager;

@property(nonatomic, readonly) BOOL hasDefaultIcon;
@property(nonatomic, readonly) BOOL isEditable;
@property(nonatomic, readonly) BOOL isTrash;
@property(nonatomic, readonly) BOOL isUserTemplate;
@property(nonatomic, readonly) BOOL isUserTemplateGroup;

/// Determines, whether the receiving node is inside the trash.
/// The trash group itself is not considered as trashed.
/// Hence when sending this message with the trash group, NO is returned
/// @return YES, if the item is inside the trash, NO otherwise (and if item is trash group)
@property (nonatomic, readonly) BOOL isTrashed;

/// @return	default icon index for a group
+ (NSUInteger)defaultIcon;

/// Returns a copy of the node assigned with a new UUID. Use copy on KPKEntry or KPKGroup to get a carbon copy
/// @param titleOrNil title for the new node, if nil a default title is generated
/// @param options    options for the specific copy
/// @return copied node
- (instancetype)copyWithTitle:(NSString *)titleOrNil options:(KPKCopyOptions)options;

/// Creates a new node with the given UUID or generates a new if nil was supplied
/// @param uuid uuid for the node. Use nil if you want a newly generated one
/// @return newly created node
- (instancetype)initWithUUID:(NSUUID *)uuid;

- (KPKComparsionResult)compareToNode:(KPKNode *)aNode;

/// Returns the root group of the node by walking up the tree
/// @return	root group of the node
@property (nonatomic, readonly) KPKGroup *rootGroup;

/// Determines if the receiving group is an ancestor of the supplied group
/// @param node Node to test ancestorship for
/// @return	YES if receiver is ancestor of group, NO otherwise
- (BOOL)isAnchestorOf:(KPKNode *)node;

/// Determines if the receiving group is an decendant of the supplied group
/// The default implementation simply calls [node isAnchestorOf:self]
/// @param node Node to test decendance for
/// @return  YES if receiver is decendant of group, NO otherwise
- (BOOL)isDecendantOf:(KPKNode *)node;

/// Trashes the node. Respects the settings for trash handling
/// a) trash is enabled: If no trash is present, a trash group is created and the node is moved to the trash group
/// b) trash is disabled: removes the node.
- (void)trashOrRemove;

/// Remove the node from the group
- (void)remove;

/// Move the node to the group
/// Moves can only be executed inside a tree. Moving nodes accross trees is only possible via -remove and -addToGroup:
/// @param group the group to add the node to
- (void)moveToGroup:(KPKGroup *)group;

/// Move the node to the group at the given index
/// Moves can only be executed inside a tree. Moving nodes accross trees is only possible via -remove and -addToGroup:
/// @param group the group to move the node to
/// @param index the index at which to add the node. If index is out of bounds, the node will get added either at the beginning or the end
- (void)moveToGroup:(KPKGroup *)group atIndex:(NSUInteger)index;

/// Add the node to the group
/// @param group the group to add the node to
- (void)addToGroup:(KPKGroup *)group;

/// Add the node to the group at the given index
/// @param group the group to add the node to
/// @param index the index at which to add the node. If index is out of bounds, the node will get added either at the beginning or the end
- (void)addToGroup:(KPKGroup *)group atIndex:(NSUInteger)index;

/// Removes the custom data for this key
/// @param key the key to remove the data for
- (void)removeCustomDataForKey:(NSString *)key;

/// Sets the custom data for the given key
/// @param value the string value to set
/// @param key the key to set the value for
- (void)setCustomData:(NSString *)value forKey:(NSString *)key;

/// Clears all custom data
- (void)clearCustomData;

/// return the node as a group, nil if the group is an entry
@property(nonatomic, readonly) KPKGroup *asGroup;
/// returns the node as an entry, nil if the node is a group
@property(nonatomic, readonly) KPKEntry *asEntry;

#pragma mark Hierarchy

/// @return The breadcrumb of this group separated by dots.
@property (nonatomic, readonly, copy) NSString *breadcrumb;

/// Returns the path of groups this group is under. The group names a separated by the given separator
/// @param separator a string that is used as group name separator
/// @return NSString of the groups breadcrumb.
- (NSString *)breadcrumbWithSeparator:(NSString *)separator;

/// The index path in the Tree to this group
/// @return NSIndexPath starting at the root group of the tree
@property (nonatomic, readonly, copy) NSIndexPath *indexPath;

@end
