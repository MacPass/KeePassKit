//
//  KPKSynchronizationChangesStore+Private.h
//  KeePassKit
//
//  Created by Michael Starke on 05.10.22.
//  Copyright © 2022 HicknHack Software GmbH. All rights reserved.
//

#import <KeePassKit/KeePassKit.h>
#import "KPKSynchronizationChangesStore.h"
#import "KPKSynchronizationChangesItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface KPKSynchronizationChangesStore ()

@property (strong) NSMutableArray *mutableChanges;
@property (assign, getter=isRecordingChanges) BOOL recordingChanges;

- (void)_beginRecordingChanges;
- (void)_endRecordingChanges;
- (void)_addChange:(KPKSynchronizationChangesItem *)changeItem;

@end

NS_ASSUME_NONNULL_END
