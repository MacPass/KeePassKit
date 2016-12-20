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
  KPKUpdateOptionUpateMovedTime         = 1<<2 // LocationChanged will only be overwritten if this flag is set
};

typedef NS_OPTIONS(NSUInteger, KPKNodeEqualityOptions) {
  KPKNodeEqualityIgnoreAccessDateOption       = 1<<0, // Do not compare access dates
  KPKNodeEqualityIgnoreModificationDateOption = 1<<1, // Don't compare modification dates
  KPKNodeEqualityIgnoreHistoryOption          = 1<<2, // Do not compare entry histories
  KPKNodeEqualityIgnoreEntriesOption          = 1<<3, // KPKGroup only do not compare sub-entries
  KPKNodeEqualityIgnoreGroupsOption           = 1<<4 // KPKGroup only, do not compare sub-groups (and entries in those sub-groups!)
};

@interface KPKNode () <KPKExtendedModificationRecording>

@property(nonatomic, readwrite, weak) KPKTree *tree;
@property(nonatomic, copy) KPKTimeInfo *timeInfo;
@property(nonatomic, weak) KPKGroup *parent;
@property(nonatomic, readonly) KPKFileVersion minimumVersion;
@property(nonatomic, strong) NSMutableArray<KPKBinary *> *mutableCustomData;

#pragma mark Initalizer
/* Subclasses have to override these initalizers */
- (instancetype)_init;
- (instancetype)_initWithUUID:(NSUUID *)uuid;

#pragma mark NSSecureCoding
- (instancetype)_initWithCoder:(NSCoder *)aDecoder;
- (void)_encodeWithCoder:(NSCoder *)aCoder;

- (void)_regenerateUUIDs;

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
- (void)_updateFromNode:(KPKNode *)node options:(KPKUpdateOptions)options;

#pragma mark Extended Equality
- (BOOL)_isEqualToNode:(KPKNode *)node options:(KPKNodeEqualityOptions)options;

@end

#endif
