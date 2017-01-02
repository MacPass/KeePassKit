//
//  KPKTree+KPKSynchronization.m
//  KeePassKit
//
//  Created by Michael Starke on 17/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTree+KPKSynchronization.h"

#import "KPKNode.h"
#import "KPKNode_Private.h"

#import "KPKGroup.h"
#import "KPKGroup_Private.h"

@implementation KPKTree (KPKSynchronization)


- (BOOL)syncronizeWithTree:(KPKTree *)tree options:(KPKSynchronizationOptions)options {
  if(options == KPKSynchronizationCreateNewUuidsOption) {
    [self.root _regenerateUUIDs];
  }
  for(KPKGroup *group in tree.allGroups) {
    KPKDeletedNode *deletedNode = self.deletedObjects[group.uuid];
    if(nil != deletedNode) {
      NSComparisonResult result = [deletedNode.deletionDate compare:group.timeInfo.modificationDate];
      if(result == NSOrderedDescending) {
        // object was deleted in destination but modified in source afterwards "tree conflict"
      }
      continue; // Group is known but deleted
    }
    
    
    KPKGroup *localGroup = [self.root groupForUUID:group.uuid];
    /* ignore entreis and subgroups to just compare the group attributes */
    KPKNodeEqualityOptions options = KPKNodeEqualityIgnoreGroupsOption | KPKNodeEqualityIgnoreEntriesOption;
    if([localGroup _isEqualToGroup:group options:options]) {
      continue;
    }
    KPKUpdateOptions updateOptions = (options == KPKSynchronizationOverwriteExistingOption) ? KPKUpdateOptionIgnoreModificationTime : 0;
    if(options == KPKSynchronizationOverwriteExistingOption ||
       options == KPKSynchronizationOverwriteIfNewerOption ||
       options == KPKSynchronizationSynchronizeOption) {
      [localGroup _updateFromNode:group options:updateOptions];
    }
  }
  
  for(KPKEntry *entry in tree.allEntries) {
    
  }
  return NO;
}

@end
