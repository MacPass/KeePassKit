//
//  KPKNode_Private.h
//  MacPass
//
//  Created by Michael Starke on 12/08/15.
//  Copyright (c) 2015 HicknHack Software GmbH. All rights reserved.
//

#ifndef MacPass_KPKNode_Private_h
#define MacPass_KPKNode_Private_h

#import "KPKNode.h"
#import "KPKExtendedModificationRecording.h"

typedef NS_OPTIONS(NSUInteger, KPKUpdateOptions) {
  KPKUpdateOptionIgnoreModificationTime = 1<<1, // Only use properties from node if node has newer updates
  KPKUpdateOptionIncludeMovedTime       = 1<<2, // LocationChanged will only be overwritten if this flag is set
  KPKUpdateOptionIncludeHistory         = 1<<3,  // History will be copied from source
};

typedef NS_OPTIONS(NSUInteger, KPKNodeCompareOptions) {
  KPKNodeCompareOptionIgnoreAccessDate       = 1<<0, // Do not compare access dates
  KPKNodeCompareOptionIgnoreModificationDate = 1<<1, // Don't compare modification dates
  KPKNodeCompareOptionIgnoreHistory          = 1<<2, // Do not compare entry histories
  KPKNodeCompareOptionIgnoreUUID             = 1<<3, // Do not compare UUIDs.
  KPKNodeCompareOptionIgnoreEntries          = 1<<4, // KPKGroup only - do not compare sub-entries
  KPKNodeCompareOptionIgnoreGroups           = 1<<5  // KPKGroup only - do not compare sub-groups (and entries in those sub-groups!)
};

typedef NS_OPTIONS(NSUInteger, KPKNodeTraversalOptions) {
  KPKNodeTraversalOptionSkipEntries   = 1<<0,
  KPKNodeTraversalOptionSkipGroups    = 1<<1
};

@interface KPKNode () <KPKExtendedModificationRecording> {
  @protected
  NSUUID *_uuid; // changes to uuid should be handled with utmost care!
}

@property(nonatomic, readwrite, weak) KPKTree *tree;
@property(nonatomic, copy) KPKTimeInfo *timeInfo;
@property(nonatomic, weak) KPKGroup *parent;
@property(nonatomic, copy) NSUUID *previousParent;
@property(nonatomic, readonly) KPKFileVersion minimumVersion;
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *mutableCustomData;

#pragma mark Initalizer
/* Subclasses have to override these initalizers */
- (instancetype)_init;
- (instancetype)_initWithUUID:(NSUUID *)uuid;

#pragma mark NSSecureCoding
- (instancetype)_initWithCoder:(NSCoder *)aDecoder;
- (void)_encodeWithCoder:(NSCoder *)aCoder;

- (void)_regenerateUUIDs;

#pragma mark Traversal

- (void)_traverseNodesWithBlock:(void (^)(KPKNode *node, BOOL *stop))block;
- (void)_traverseNodesWithOptions:(KPKNodeTraversalOptions)options block:(void (^)(KPKNode *node, BOOL *stop))block;

#pragma mark Copy Helper
/**
 *  Creates a deep copy of the Node.
 *  If a subclass implements this, it's mandatory to also override _init and _initWithUUID:
 *
 *  @param uuid UUID for the copy
 *
 *  @return Copy of the receiving node.
 */
- (instancetype)_copyWithUUID:(NSUUID *)uuid;

#pragma mark Merging

/**
 Updates the reveiving node with properties form the node.
 The way the update works depends heavily on the provided options

 @param node node to update from
 @param options options to use for updation
 @return YES if the node did change, otherwise NO
 */
- (BOOL)_updateFromNode:(KPKNode *)node options:(KPKUpdateOptions)options;

#pragma mark comparsion
- (KPKComparsionResult)_compareToNode:(KPKNode *)aNode options:(KPKNodeCompareOptions)options;

@end

#endif
