//
//  KPKSynchronizationOptions.h
//  KeePassKit
//
//  Created by Michael Starke on 28.04.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#ifndef KPKSynchronizationOptions_h
#define KPKSynchronizationOptions_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, KPKSynchronizationMode) {
  KPKSynchronizationModeOverwriteExisting, // Overwrite every node with the external node, this will not remove any entries or groups found in the source
  KPKSynchronizationModeKeepExisting, // Only take new items, but keep the old ones just like they are
  KPKSynchronizationModeOverwriteIfNewer, // Overwrite local nodes with external ones if the external ones have been modified more recently
  KPKSynchronizationModeSynchronize // Default behaviour for synchronizing trees. Uses sophisicated merging to prevent any data loss even if conflicting edits have been made.
};

typedef NS_OPTIONS(NSUInteger, KPKSynchronizationOptions) {
  KPKSynchronizationOptionCreateNewUuids          = 1 << 0, // generate new UUIDs in source tree before merging it into target
  KPKSynchronizationOptionMatchGroupsByTitleOnly  = 1 << 1 // match groups by title not by UUID. This is usefull when trying to merge KDB trees since only entry retain ther UUID after save and load
};

#endif /* KPKSynchronizationOptions_h */
