//
//  KPKSynchronizationChangesStore.m
//  KeePassKit
//
//  Created by Michael Starke on 02.10.22.
//  Copyright © 2022 HicknHack Software GmbH. All rights reserved.
//

#import "KPKSynchronizationChangesStore.h"
#import "KPKSynchronizationChangesStore_Private.h"
#import "KPKSynchronizationChangesItem.h"

@implementation KPKSynchronizationChangesStore

@dynamic addedNodes;
@dynamic removedNodes;
@dynamic allChanges;

- (instancetype)init {
  self = [super init];
  if(self) {
    self.mutableChanges = [[NSMutableArray alloc] init];
    self.recordingChanges = NO;
  }
  return self;
}

- (void)_beginRecordingChanges {
  [self.mutableChanges removeAllObjects];
  self.recordingChanges = YES;
}

- (void)_endRecordingChanges {
  self.recordingChanges = NO;
}

- (void)_addChange:(KPKSynchronizationChangesItem *)changeItem {
  NSAssert(self.isRecordingChanges, @"Change recording is only possible while in active recording");
  [self.mutableChanges addObject:changeItem];
}

- (NSArray<KPKSynchronizationChangesItem *> *)allChanges {
  NSAssert(!self.isRecordingChanges, @"Cannot access changes while actively recording them");
  return [self.mutableChanges copy];
}

- (NSArray<KPKSynchronizationChangesItem *> *)addedNodes {
  NSAssert(!self.isRecordingChanges, @"Cannot access changes while actively recording them");
  NSPredicate *addedNodesPredicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
    KPKSynchronizationChangesItem *item = (KPKSynchronizationChangesItem *)evaluatedObject;
    return (item.changeType == KPKSynchronizationChangeTypeAddedNode);
    
  }];
  return [self.mutableChanges filteredArrayUsingPredicate:addedNodesPredicate];
}

- (NSArray<KPKSynchronizationChangesItem *> *)removedNodes {
  NSAssert(!self.isRecordingChanges, @"Cannot access changes while actively recording them");
  NSPredicate *addedNodesPredicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
    KPKSynchronizationChangesItem *item = (KPKSynchronizationChangesItem *)evaluatedObject;
    return (item.changeType == KPKSynchronizationChangeTypeRemovedNode);
    
  }];
  return [self.mutableChanges filteredArrayUsingPredicate:addedNodesPredicate];
}

- (NSArray<KPKSynchronizationChangesItem *> *)changesForUUID:(NSUUID *)uuid {
  NSAssert(!self.isRecordingChanges, @"Cannot access changes while actively recording them");
  NSPredicate *addedNodesPredicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
    KPKSynchronizationChangesItem *item = (KPKSynchronizationChangesItem *)evaluatedObject;
    return ([item.uuid isEqual:uuid]);
  }];
  return [self.mutableChanges filteredArrayUsingPredicate:addedNodesPredicate];

}

@end
