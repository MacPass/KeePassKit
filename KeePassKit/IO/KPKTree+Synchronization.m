//
//  KPKTree+KPKSynchronization.m
//  KeePassKit
//
//  Created by Michael Starke on 17/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTree+Synchronization.h"
#import "KPKTree_Private.h"

#import "KPKNode.h"
#import "KPKNode_Private.h"

#import "KPKGroup.h"
#import "KPKGroup_Private.h"

#import "KPKEntry.h"
#import "KPKEntry_Private.h"

@implementation KPKTree (Synchronization)


- (BOOL)syncronizeWithTree:(KPKTree *)tree options:(KPKSynchronizationOptions)options {
  BOOL didChange = NO;
  if(options == KPKSynchronizationCreateNewUuidsOption) {
    /* create new uuid in the sourc tree */
    [tree.root _regenerateUUIDs];
  }
  
  for(KPKGroup *externGroup in tree.allGroups) {
    KPKDeletedNode *deletedNode = self.deletedObjects[externGroup.uuid];
    if(nil != deletedNode) {
      NSComparisonResult result = [deletedNode.deletionDate compare:externGroup.timeInfo.modificationDate];
      if(result == NSOrderedDescending ) {
        continue; // Group was delted in the destination after is was modified in the source
      }
    }
    
    KPKGroup *localGroup = [self.root groupForUUID:externGroup.uuid];
    
    /* group is unkown, create a copy and integrate it */
    if(!localGroup) {
      localGroup = [[KPKGroup alloc] initWithUUID:externGroup.uuid];
      [localGroup _updateFromNode:externGroup options:KPKUpdateOptionUpateMovedTime | KPKUpdateOptionIgnoreModificationTime];
      
      KPKGroup *localParent = [self.root groupForUUID:externGroup.parent.uuid];
      if(!localParent) {
        localParent = self.root;
      }
      BOOL updateTiming = localGroup.updateTiming;
      localGroup.updateTiming = NO;
      [localGroup addToGroup:localParent];
      localGroup.updateTiming = updateTiming;
      didChange = YES;
    }
    else {
      NSAssert(options != KPKSynchronizationCreateNewUuidsOption, @"UUID collision while merging trees!");
      /*
       ignore entries and subgroups to just compare the group attributes,
       KPKNodeEqualityIgnoreHistory not needed since we do not compare entries at all
       */
      KPKNodeEqualityOptions equalityOptions = KPKNodeEqualityIgnoreGroupsOption | KPKNodeEqualityIgnoreEntriesOption;
      if([localGroup _isEqualToGroup:externGroup options:equalityOptions]) {
        continue; // Groups has not changed at all, no updates needed
      }
      KPKUpdateOptions updateOptions = (equalityOptions == KPKSynchronizationOverwriteExistingOption) ? KPKUpdateOptionIgnoreModificationTime : 0;
      if(options == KPKSynchronizationOverwriteExistingOption ||
         options == KPKSynchronizationOverwriteIfNewerOption ||
         options == KPKSynchronizationSynchronizeOption) {
        [localGroup _updateFromNode:externGroup options:updateOptions];
      }
    }
  }
  
  /* merge entries */
  
  for(KPKEntry *externEntry in tree.allEntries) {
    KPKDeletedNode *deletedNode = self.deletedObjects[externEntry.uuid];
    if(nil != deletedNode) {
      NSComparisonResult result = [deletedNode.deletionDate compare:externEntry.timeInfo.modificationDate];
      if(result == NSOrderedDescending ) {
        continue; // Group was delted in the destination after is was modified in the source
      }
    }
    
    KPKEntry *localEntry = [self.root entryForUUID:externEntry.uuid];
    
    if(!localEntry) {
      localEntry = [[KPKEntry alloc] initWithUUID:externEntry.uuid];
      [localEntry _updateFromNode:externEntry options:KPKUpdateOptionUpateMovedTime | KPKUpdateOptionIgnoreModificationTime];
      
      KPKGroup *localParent = [self.root groupForUUID:externEntry.parent.uuid];
      if(!localParent) {
        localParent = self.root;
      }
      BOOL updateTiming = localEntry.updateTiming;
      localEntry.updateTiming = NO;
      [localEntry addToGroup:localParent];
      localEntry.updateTiming = updateTiming;
    }
    else {
      NSAssert(options != KPKSynchronizationCreateNewUuidsOption, @"UUID collision while merging trees!");
      /*
       just compare entry attributes, ignore history!
       KPKNodeEqualityIgnoreHistory not needed since we do not compare entries at all
       */
      KPKNodeEqualityOptions equalityOptions = KPKNodeEqualityIgnoreHistoryOption;
      if([localEntry _isEqualToEntry:externEntry options:equalityOptions]) {
        continue; // Entry has not changed at all, no updates needed
      }
      KPKUpdateOptions updateOptions = (equalityOptions == KPKSynchronizationOverwriteExistingOption) ? KPKUpdateOptionIgnoreModificationTime : 0;
      if(options == KPKSynchronizationOverwriteExistingOption ||
         options == KPKSynchronizationOverwriteIfNewerOption ||
         options == KPKSynchronizationSynchronizeOption) {
        [localEntry _updateFromNode:externEntry options:updateOptions];
      }
    }
  }
  
  /* merge deleted objects */
  
  for(NSUUID *uuid in tree.mutableDeletedObjects) {
    KPKDeletedNode *otherDeletedNode = tree.mutableDeletedObjects[uuid];
    KPKDeletedNode *localDeletedNode = self.mutableDeletedObjects[uuid];
    if(!localDeletedNode) {
      self.mutableDeletedObjects[uuid] = otherDeletedNode;
      continue; // done;
    }

    /* if the other node was deleted later, we use this other node instaed and remove ours */
    NSComparisonResult result = [localDeletedNode.deletionDate compare:otherDeletedNode.deletionDate];
    if(result == NSOrderedAscending) {
      self.mutableDeletedObjects[uuid] = otherDeletedNode;
    }
    
  }
  
  /* clear undo stack just to be save */
  //[self.undoManager removeAllActions]
  
  return YES;
}

- (void)_mergeHistory:(KPKEntry *)entry ofEntry:(KPKEntry *)otherEntry {

}

@end
