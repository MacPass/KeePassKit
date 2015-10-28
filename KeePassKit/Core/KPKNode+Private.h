//
//  KPKNode+Private.h
//  MacPass
//
//  Created by Michael Starke on 12/08/15.
//  Copyright (c) 2015 HicknHack Software GmbH. All rights reserved.
//

#ifndef MacPass_KPKNode_Private_h
#define MacPass_KPKNode_Private_h

#import "KPKNode.h"

@interface KPKNode ()

@property(nonatomic, readwrite, weak) KPKTree *tree;
@property(nonatomic, readwrite) BOOL deleted;
@property(nonatomic, copy) KPKTimeInfo *timeInfo;
@property(nonatomic, strong) KPKNode *editNode;

#pragma mark Initalizer
/* Subclasses have to override these initalizers */
- (instancetype)_init;
- (instancetype)_initWithUUID:(NSUUID *)uuid;


#pragma mark NSSecureCoding
- (instancetype)_initWithCoder:(NSCoder *)aDecoder;
- (void)_encodeWithCoder:(NSCoder *)aCoder;

#pragma makr Copy Helper
/**
 *  Creates a deep copy of the Node.
 *  If a subclass implements this, it's mandatory to also override _init and _initWithUUID:
 *
 *  @param uuid UUID for the copy
 *
 *  @return Copy of the receiving node.
 */
- (instancetype)_copyWithUUUD:(NSUUID *)uuid;
/**
 *  Creates a shallow copy of the Node. This is mostly usefull for editing
 *
 *  @param uuid UUID for the copy
 *
 *  @return Copy of the reveiving node.
 */
- (instancetype)_shallowCopyWithUUID:(NSUUID *)uuid;

#pragma mark Editing
/**
 *  Updates the node data to the one given by the shawlow copy
 *
 *  @param node A node to update to. Shallow copies are sufficient
 */
- (void)_updateToNode:(KPKNode *)node;

@end

#endif
