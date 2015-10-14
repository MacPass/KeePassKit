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
@property(nonatomic, strong) KPKEditingSession *editingSession;

#pragma mark Initalizer
- (instancetype)_init;
- (instancetype)_initWithUUID:(NSUUID *)uuid;


#pragma mark NSSecureCoding
- (instancetype)_initWithCoder:(NSCoder *)aDecoder;
- (void)_encodeWithCoder:(NSCoder *)aCoder;

#pragma mark Editing
/**
 *  Updates the node data to the given one.
 *
 *  @param node Node to update to
 */
- (void)_updateToNode:(KPKNode *)node;

@end

#endif
