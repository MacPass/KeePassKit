//
//  KPKSynchronizationChangesItem.h
//  KeePassKit
//
//  Created by Michael Starke on 05.10.22.
//  Copyright © 2022 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, KPKSynchronizationChangeType) {
  KPKSynchronizationChangeTypeAddedNode,
  KPKSynchronizationChangeTypeRemovedNode,
  KPKSynchronizationChangeTypeMovedNode,
  KPKSynchronizationChangeTypeChangedNodeAttribute,   // Node attributes have changed
  KPKSynchronizationChangeTypeAddedNodeAttribute,     // Node attributes where added - valid only for entries
  KPKSynchronizationChangeTypeRemovedNodeAttribute,   // Node attributes where removed - valid only for entries
  KPKSynchronizationChangeTypeAddedIcon,
  KPKSynchronizationChangeTypeRemovedIcon,
  KPKSynchronizationChangeTypeChangedIcon,
  KPKSynchronizationChangeTypeChangedMetaData,          // Any changes in inner settings e.g. Templates, Recycle Bin, History, Name, Color
};

@class KPKNode;
@class KPKGroup;
@class KPKAttribute;

@interface KPKSynchronizationChangesItem : NSObject

@property (readonly) KPKSynchronizationChangeType changeType;

@property (readonly, copy) NSUUID *uuid; // the uuid of the affected node

+ (instancetype)itemWithChangedAttributeKey:(NSString *)key localValue:(NSString *)localValue remoteValue:(NSString *)remoteValue;
+ (instancetype)itemWithAddedNode:(KPKNode *)node parent:(KPKGroup *)group;
+ (instancetype)itemWithRemovedNode:(KPKNode *)node;

- (instancetype)init NS_UNAVAILABLE;

@end

@interface KPKSynchronizationAttributeChangesItem : KPKSynchronizationChangesItem

@property (readonly, copy) NSString *key;
@property (readonly, copy) NSString *localValue;
@property (readonly, copy) NSString *remoteValue;

@end

NS_ASSUME_NONNULL_END
