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

typedef NS_ENUM(NSUInteger, KPKSynchronizationOptions) {
  KPKSynchronizationOverwriteExistingOption = 1, // Overwrite every node with the external node, this will not remove any entries or groups found in the source
  //KPKSynchronizationKeepExistingOption = 2, // Only take new items, but keep the old ones just like they are
  KPKSynchronizationOverwriteIfNewerOption = 3, // Overwrite local nodes with external ones if the external ones have been modified more recently
  KPKSynchronizationCreateNewUuidsOption = 4, // Additional Option, cannot be used standaloen - set this if you want to generate new UUIDs for the merged in tree
  KPKSynchronizationSynchronizeOption = 5 // Default behaviour for synchronizing trees. Uses sophisicated merging to prevent any data loss even if conflicting edits have been made.
};

#endif /* KPKSynchronizationOptions_h */
