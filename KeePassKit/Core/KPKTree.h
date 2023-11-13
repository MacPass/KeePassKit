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
#import <KeePassKit/KPKFormat.h>
#import <KeePassKit/KPKSynchronizationOptions.h>
#import <KeePassKit/KPKSynchronizationChangesStore.h>
#import <KeePassKit/KPKNode.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const KPKTreeWillAddGroupNotification;
FOUNDATION_EXTERN NSString *const KPKTreeDidAddGroupNotification;
FOUNDATION_EXTERN NSString *const KPKTreeWillRemoveGroupNotification;
FOUNDATION_EXTERN NSString *const KPKTreeDidRemoveGroupNotification;

FOUNDATION_EXTERN NSString *const KPKTreeWillAddEntryNotification;
FOUNDATION_EXTERN NSString *const KPKTreeDidAddEntryNotification;
FOUNDATION_EXTERN NSString *const KPKTreeWillRemoveEntryNotification;
FOUNDATION_EXTERN NSString *const KPKTreeDidRemoveEntryNotification;

FOUNDATION_EXTERN NSString *const KPKParentGroupKey;
FOUNDATION_EXTERN NSString *const KPKGroupKey;
FOUNDATION_EXTERN NSString *const KPKEntryKey;

@class KPKTree;

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
/**
 Delegates can provide an Undo-Manager to enabel Undo-Redo registration inside the tree.
 The provided item is not stored, so you can use this to disable undo/redo globally for a period by just providing nil
 Alternativly you can disable and enable undoregistration on the provided NSUndoManager
 
 @param tree Tree for which an undo manager is requested
 *
 *  @return the undo manager to be used for the tree.
 */
- (NSUndoManager *)undoManagerForTree:(KPKTree *)tree;

/**
 Resolves a placeholder for the tree. Some placeholders require access to document location and other attributes,
 that a KPKTree normally does not know.  
 Some placeholders might even require user-interaction.
 {PICKCHAR}, {PICKCHARS:Fld:Opt}, {PICKFIELD}, {HMACOTP}
 
 
 @param placeholder The placeholder to resolve
 @param tree The Tree asking for the resolving
 @return The resolved String, nil if no resolving is possible
 */
- (NSString *)tree:(KPKTree *)tree resolvePlaceholder:(NSString *)placeholder forEntry:(KPKEntry *)entry;
/* specialized placeholder to speed up lookup */
- (NSString *)tree:(KPKTree *)tree resolvePickCharsPlaceholderForValue:(NSString *)value options:(NSString *_Nullable)options;
- (NSString *)tree:(KPKTree *)tree resolvePickFieldPlaceholderForEntry:(KPKEntry *)entry;
/**
 Allows the Tree to resolve unkown placeholders in the supplied string. Be aware that this string is raw and might still contain
 placeholders that will get resolved after this message was sent.
 This is a place to process values that KeePassKit is unable to replace (e.g. by custom sequences for plugins)
 
 You should not process any placeholders or references on your own if you do not need the final value.
 If you need final values, use -[NSString kpk_finalValueForEntry:] to retrieve them
 
 If you do not change anythin simply return NO and do not touch the string
 */
- (BOOL)tree:(KPKTree *)tree resolveUnknownPlaceholdersInString:(NSMutableString *)string forEntry:(KPKEntry *)entry;

/// Allows the delegate to supply a changesStore to retrieve any changes when a synchonization is done.
/// Run the synchronization in dry mode to retriefe those changes before applying the merge
/// - Parameter tree: the tree to supply the store for
- (KPKSynchronizationChangesStore *)synchronizationChangeStoreForTree:(KPKTree *)tree;

@end

@class KPKGroup;
@class KPKEntry;
@class KPKCompositeKey;
@class KPKDeletedNode;
@class KPKIcon;
@class KPKMetaData;

/* Keys used in UserInfo */
FOUNDATION_EXPORT NSString *const kKPKNodeKey;

@interface KPKTree : NSObject <NSCopying>

@property (nonatomic, weak, nullable) id<KPKTreeDelegate> delegate;
@property (nonatomic, copy, readonly) NSDictionary<NSUUID *,KPKDeletedNode *> *deletedObjects;
@property (nonatomic, strong, readonly, nullable) KPKMetaData *metaData;


@property (nonatomic, readonly, nullable) NSUndoManager *undoManager;
@property (nonatomic, readonly) BOOL isEditable;

@property (nonatomic, weak, nullable) KPKGroup *trash;
@property (nonatomic, weak, nullable) KPKGroup *templates;
@property (nonatomic, strong, nullable) KPKGroup *root;
/**
 Acces to the root group via the groups property
 to offer a bindable interface for a tree
 */
@property (nonatomic, readonly) NSArray<KPKGroup *> *groups;
/**
 Acces to the root children via the children property
 to offer a bindable interface for a tree
 */
@property (nonatomic, copy, readonly) NSArray<KPKNode *> *children;
/**
 *	NSArray of KPKGroup objects. Contains all child groups in a tree.
 *  @note The root group is missing from this array
 */
@property (nonatomic, readonly) NSArray<KPKGroup *> *allGroups;
/**
 *	NSArray of KPKEntries. Contains all entries of the tree
 */
@property (nonatomic, readonly) NSArray<KPKEntry *> *allEntries;
/**
 *  NSArray of KPKEntries that are History elements
 */
@property (nonatomic, readonly) NSArray<KPKEntry *> *allHistoryEntries;
/**
 Array of all currently known tags.
 */
@property (nonatomic, readonly, copy) NSArray<NSString *> *availableTags;

/**
 Returns the minimum database version (tied to the minimum Type) to store the tree without data loss.
 This always returns the maxium supported KDB version for a KDB type, KDBX results depend on data (settings, loaded data, etc.)
 */
@property (nonatomic, readonly) KPKFileVersion minimumVersion;

- (instancetype)initWithTemplateContents;

- (KPKGroup *)createGroup:(KPKGroup *_Nullable)parent;
- (KPKEntry *)createEntry:(KPKGroup *_Nullable)parent;
/**
 *  Enforces the right setup for the current settings. That is if trash is disabled, does nothing
 *  If trash is enabled, returnes the specified trahs group or creates on if none is present.
 *
 *  @return the Trash group or nil if usage of trash is disabled
 */
- (KPKGroup * _Nullable)createTrash;

/**
 *  Returns the defautl autotype squence for this tree. If a delegate is set, it is asked for the sequence.
 *
 *  @return defautl sequence, or nil if none is set
 */
- (NSString * _Nullable)defaultAutotypeSequence;

@end

@interface KPKTree (Synchronization)

/**
 Synchronizes the changes from tree into the current tree. The synchronizationoptions determine how the process takes place
 The supplied tree will get modified in the process and should NOT be reused. If you want to prevent modification, create a copy first.

 Refer to the KPKSynchronizationOptions for details on their effect
 
 @param tree the externa tree to merge in
 @param options options for the merge
 */
- (void)synchronizeWithTree:(KPKTree *)tree mode:(KPKSynchronizationMode)mode options:(KPKSynchronizationOptions)options;

@end

@interface KPKTree (History)

- (void)maintainHistory;

@end

@interface KPKTree (FormatSupport)

- (KPKFileVersion)minimumVersionForAddingEntryToGroup:(KPKGroup *)group;
- (KPKFileVersion)minimumVersionForAddingAttachmentToEntry:(KPKEntry *)entry;
- (KPKFileVersion)minimumVersionForHistory;
- (KPKFileVersion)minimumVersionForAddingAttribute;

@end

NS_ASSUME_NONNULL_END
