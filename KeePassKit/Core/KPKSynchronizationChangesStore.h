//
//  KPKSynchronizationChangesStore.h
//  KeePassKit
//
//  Created by Michael Starke on 02.10.22.
//  Copyright © 2022 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class KPKGroup;
@class KPKNode;
@class KPKAttribute;
@class KPKSynchronizationChangesItem;

@interface KPKSynchronizationChangesStore : NSObject

@property (readonly, copy, nonatomic) NSArray<KPKSynchronizationChangesItem *> *allChanges;

@property (readonly, copy, nonatomic) NSArray<KPKSynchronizationChangesItem *> *addedNodes;
@property (readonly, copy, nonatomic) NSArray<KPKSynchronizationChangesItem *> *removedNodes;

- (NSArray<KPKSynchronizationChangesItem *> *)changesForUUID:(NSUUID *)uuid;
// icons
// metadata
// attributes

@end

NS_ASSUME_NONNULL_END
