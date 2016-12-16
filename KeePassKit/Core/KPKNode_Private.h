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

@end

#endif
