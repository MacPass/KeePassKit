//
//  KPKTree+KPKSynchronization.m
//  KeePassKit
//
//  Created by Michael Starke on 17/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTree.h"
#import "KPKTree_Private.h"

#import "KPKNode.h"
#import "KPKNode_Private.h"

#import "KPKGroup.h"
#import "KPKGroup_Private.h"

#import "KPKEntry.h"
#import "KPKEntry_Private.h"

#import "KPKMetaData.h"
#import "KPKMetaData_Private.h"

#import "KPKDeletedNode.h"

#import "KPKTimeInfo.h"

#define KPK_SCOPED_ROLLBACK_BEGIN(rollbackValue, value) { \
BOOL _rollbackValue = rollbackValue; \
rollbackValue = value; \

#define KPK_SCOPED_ROLLBACK_END(rollbackValue) \
rollbackValue = _rollbackValue; \
} \

@implementation KPKTree (Synchronization)

- (void)syncronizeWithTree:(KPKTree *)tree options:(KPKSynchronizationOptions)options {
  
  if(options == KPKSynchronizationCreateNewUuidsOption) {
    /* create new uuid in the sourc tree */
    [tree.root _regenerateUUIDs];
  }
  
  [self _mergeGroupsFromTree:tree options:options];
  [self _mergeEntriesFromTree:tree options:options];
  [self _mergeDeletedObjects:tree.mutableDeletedObjects];
  [self _reapplyDeletions];
  [self.metaData _mergeWithMetaData:tree.metaData options:options];
  ;
  /* clear undo stack just to be save */
  [self.undoManager removeAllActions];
  
}

- (void)_mergeGroupsFromTree:(KPKTree *)otherTree options:(KPKSynchronizationOptions)options {
  /* Updated Properties */
  for(KPKGroup *externGroup in otherTree.allGroups) {
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
      [localGroup _updateFromNode:externGroup options:KPKUpdateOptionIgnoreModificationTime | KPKUpdateOptionUpateMovedTime];
      
      KPKGroup *localParent = [self.root groupForUUID:externGroup.parent.uuid];
      if(!localParent) {
        localParent = self.root;
      }
      KPK_SCOPED_ROLLBACK_BEGIN(localGroup.updateTiming, NO)
      [localGroup addToGroup:localParent atIndex:externGroup.index];
      KPK_SCOPED_ROLLBACK_END(localGroup.updateTiming)
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
  /* Update Location */
  for(KPKGroup *externGroup in otherTree.allGroups) {
    KPKGroup *localGroup = [self.root groupForUUID:externGroup.uuid];
    if(!localGroup) {
      /* no local group for extern group found */
      continue;
    }
    KPKGroup *externParent = [self.root groupForUUID:externGroup.parent.uuid];
    KPKGroup *localParent = localGroup.parent;
    
    if(!externParent || !localParent) {
      continue;
    }
    
    if([localParent.uuid isEqual:externParent.uuid]) {
      /* parents are the same */
      continue;
    }

    
    switch([localGroup.timeInfo.locationChanged compare:externGroup.timeInfo.locationChanged]) {
      case NSOrderedAscending:
      case NSOrderedDescending:
      case NSOrderedSame:
        continue;
    }
  }
}
- (void)_mergeEntriesFromTree:(KPKTree *)tree options:(KPKSynchronizationOptions)options {
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
      KPK_SCOPED_ROLLBACK_BEGIN(localEntry.updateTiming, NO)
      [localEntry addToGroup:localParent atIndex:externEntry.index];
      KPK_SCOPED_ROLLBACK_END(localEntry.updateTiming)
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
  /* Update Location */
  for(KPKEntry *externEntry in tree.allEntries) {
    KPKEntry *localEntry = [self.root entryForUUID:externEntry.uuid];
    if(!localEntry) {
      /* no local group for extern group found */
      continue;
    }
    KPKGroup *externParent = externEntry.parent;
    KPKGroup *localParent = localEntry.parent;
    
    if(nil == externParent || nil == localParent) {
      continue;
    }
    
    if([localParent.uuid isEqual:externParent.uuid]) {
      /* parents are the same */
      continue;
    }
    if(NSOrderedAscending == [localEntry.timeInfo.locationChanged compare:externEntry.timeInfo.locationChanged]) {
      KPKGroup *newLocalParent = [self.root groupForUUID:externParent.uuid];
      if(newLocalParent) {
        [localEntry moveToGroup:newLocalParent];
      }
    }
  }
}

- (void)_mergeHistory:(KPKEntry *)entry ofEntry:(KPKEntry *)otherEntry {
  
}

- (BOOL)_mergeDeletedObjects:(NSDictionary<NSUUID *,KPKDeletedNode *> *)deletedObjects {
  for(NSUUID *uuid in deletedObjects) {
    KPKDeletedNode *otherDeletedNode = deletedObjects[uuid];
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
  /* reapply deletion */
  //FIXME: this causes data loss if a deleted group now has children!!!
  for(NSUUID *uuid in self.mutableDeletedObjects) {
    KPKGroup *group = [self.root groupForUUID:uuid];
    [group.parent _removeChild:group];
    KPKEntry *entry = [self.root entryForUUID:uuid];
    [entry.parent _removeChild:entry];
  }
  return NO;
}

- (void)_reapplyDeletions {
  NSArray *pending = self.mutableDeletedObjects.allKeys;
  NSMutableArray *skipped = [[NSMutableArray alloc] initWithCapacity:pending.count];
  while(pending.count > 0) {
    /* FIXME if group is not emptry and has not-deleted sub group or sub entry will run in infinite loop! */
    for(NSUUID *uuid in pending) {
      KPKEntry *deletedEntry = [self.root entryForUUID:uuid];
      /* delete the entry using low level API not remove */
      [deletedEntry.parent _removeChild:deletedEntry];
      
      KPKGroup *deletedGroup = [self.root groupForUUID:uuid];
      if(deletedGroup.countOfGroups == 0 && deletedGroup.countOfEntries == 0) {
        [deletedGroup.parent _removeChild:deletedGroup];
      }
      else {
        [skipped addObject:uuid];
      }
    }
    /* re-queue the skipped uuids */
    pending = [skipped copy];
  }
}

- (void)_mergeMetaDataFromTree:(KPKTree *)tree {
  
}

@end
