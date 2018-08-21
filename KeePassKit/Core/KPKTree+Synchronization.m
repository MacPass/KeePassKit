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

#import "KPKScopedSet.h"

KPKNode *_findNodeInGroup(KPKNode *node, KPKGroup *group, KPKSynchronizationOptions options) {
  __block KPKNode *localNode = nil;
  if(options & KPKSynchronizationOptionMatchGroupsByTitleOnly && node.asGroup) {
    [group _traverseNodesWithOptions:KPKNodeTraversalOptionSkipEntries block:^(KPKNode *aNode, BOOL *stop) {
      if([aNode.title isEqualToString:node.title]) {
        localNode = aNode;
        *stop = YES;
      }
    }];
    return localNode;
  }
  return node.asGroup ? [group groupForUUID:node.uuid] : [group entryForUUID:node.uuid];
}

@implementation KPKTree (Synchronization)

- (void)synchronizeWithTree:(KPKTree *)tree mode:(KPKSynchronizationMode)mode options:(KPKSynchronizationOptions)options {
  
  if(options & KPKSynchronizationOptionCreateNewUuids) {
    /* create new uuid in the sourc tree */
    [tree.root _regenerateUUIDs];
  }
  
  /* merge strategy is as follows:
   1) add all unkown entries from other
   2) update all known entires to latest version
   3) add all unkown groups from other
   4) update all known groups to latest version
   5) locate entries to correct postion
   6) locate groups to correct position
   7) update deleted information
   8) reapply deletions to ensure entries and groups are at final place
   */
  [self _mergeNodes:[@[tree.root] arrayByAddingObjectsFromArray:tree.allGroups] mode:mode options:options];
  [self _mergeNodes:tree.allEntries mode:mode options:options];
  [self _mergeLocationFromNodes:tree.allEntries options:options];
  [self _mergeLocationFromNodes:tree.allGroups options:options];
  [self _mergeDeletedObjects:tree.mutableDeletedObjects];
  if(mode == KPKSynchronizationModeSynchronize) {
    [self _reapplyDeletions:self.root];
  }
  [self.metaData _mergeWithMetaDataFromTree:tree mode:mode];
  ;
  /* clear undo stack since merge is not supposed to be undoable */
  [self.undoManager removeAllActions];
}

- (void)_mergeNodes:(NSArray<KPKNode *> *)nodes mode:(KPKSynchronizationMode)mode options:(KPKSynchronizationOptions)options {
  for(KPKNode *externNode in nodes) {
    KPKDeletedNode *deletedNode = self.deletedObjects[externNode.uuid];
    if(nil != deletedNode) {
      NSComparisonResult result = [deletedNode.deletionDate compare:externNode.timeInfo.modificationDate];
      if(result == NSOrderedDescending ) {
        continue; // Node was deleted in destination after being modified in source
      }
    }
    
    KPKNode *localNode = _findNodeInGroup(externNode, self.root, options);

    /* Node is unkown, create a copy and integrate it */
    if(!localNode) {
      localNode = [[externNode.class alloc] initWithUUID:externNode.uuid];
      [localNode _updateFromNode:externNode options:KPKUpdateOptionIgnoreModificationTime | KPKUpdateOptionIncludeMovedTime | KPKUpdateOptionIncludeHistory];
      
      KPKGroup *localParent = (KPKGroup *)_findNodeInGroup(externNode.parent, self.root, options);
      if(!localParent) {
        localParent = self.root;
      }
      KPK_SCOPED_NO_BEGIN(localNode.updateTiming)
      [localNode addToGroup:localParent atIndex:externNode.index];
      KPK_SCOPED_NO_END(localNode.updateTiming)
    }
    else {
      /*
       ignore entries and subgroups to just compare the group attributes,
       KPKNodeEqualityIgnoreHistory not needed since we do not compare entries at all
       */
      KPKNodeCompareOptions equalityOptions = (KPKNodeCompareOptionIgnoreGroups | KPKNodeCompareOptionIgnoreEntries);
      if(externNode.asGroup && options & KPKSynchronizationOptionMatchGroupsByTitleOnly) {
        equalityOptions |= KPKNodeCompareOptionIgnoreUUID;
      }
      
      if(KPKComparsionEqual == [localNode _compareToNode:externNode options:equalityOptions]) {
        continue; // node did not change
      }
      KPKUpdateOptions updateOptions = (mode == KPKSynchronizationModeOverwriteExisting) ? ( KPKUpdateOptionIgnoreModificationTime | KPKUpdateOptionIncludeHistory ) : 0;
      if(mode == KPKSynchronizationModeOverwriteExisting ||
         mode == KPKSynchronizationModeOverwriteIfNewer ||
         mode == KPKSynchronizationModeSynchronize) {
        
        
        KPKEntry *localEntry = localNode.asEntry;
        NSComparisonResult result = [localEntry.timeInfo.modificationDate compare:externNode.timeInfo.modificationDate];
        
        /* keep all changes as history so no extern/local edits will get lost */
        if(nil != localEntry && mode != KPKSynchronizationModeOverwriteExisting) {
          if(result == NSOrderedAscending && ![externNode.asEntry hasHistoryOfEntry:localEntry]) {
            [localEntry _pushHistoryAndMaintain:NO];
          }
          if(result == NSOrderedDescending && ![localEntry hasHistoryOfEntry:externNode.asEntry]) {
            [externNode.asEntry _pushHistoryAndMaintain:NO];
          }
        }
        [localNode _updateFromNode:externNode options:updateOptions];
        
        if(mode != KPKSynchronizationModeOverwriteExisting) {
          [self _mergeHistory:localEntry ofEntry:externNode.asEntry mode:mode];
        }
      }
    }
  }
}

- (void)_mergeLocationFromNodes:(NSArray <KPKNode *>*)nodes options:(KPKSynchronizationOptions)options {
  for(KPKNode *externNode in nodes) {
    
    KPKNode *localNode = _findNodeInGroup(externNode, self.root, options);
    
    if(!localNode) {
      /* no local node for extern node found */
      continue;
    }
    KPKGroup *localExternParent = (KPKGroup *)_findNodeInGroup(externNode.parent, self.root, options);
    KPKGroup *localParent = localNode.parent;
    
    if(!localExternParent || !localParent) {
      continue;
    }

    if([localParent.uuid isEqual:localExternParent.uuid]) {
      localNode.timeInfo.locationChanged = [localNode.timeInfo.locationChanged laterDate:externNode.timeInfo.locationChanged];
      continue;
    }
    else if(KPKSynchronizationOptionMatchGroupsByTitleOnly & options) {
      if([localParent.title isEqualToString:externNode.title]) {
        localNode.timeInfo.locationChanged = [localNode.timeInfo.locationChanged laterDate:externNode.timeInfo.locationChanged];
        continue; // parents have the same title which is fine for us
      }
    }
    
    switch([localNode.timeInfo.locationChanged compare:externNode.timeInfo.locationChanged]) {
      case NSOrderedAscending:
        localNode.timeInfo.locationChanged = externNode.timeInfo.locationChanged;
        KPK_SCOPED_NO_BEGIN(localNode.updateTiming)
        /* try to perserve index */
        [localNode moveToGroup:localExternParent atIndex:externNode.index];
        KPK_SCOPED_NO_END(localNode.updateTiming)
      case NSOrderedSame:
      case NSOrderedDescending:
        continue;
    }
  }
}

- (void)_mergeHistory:(KPKEntry *)entry ofEntry:(KPKEntry *)otherEntry mode:(KPKSynchronizationMode)mode {
  if(!entry || !otherEntry) {
    return; // nil parameters
  }
  NSAssert([entry.uuid isEqual:otherEntry.uuid],@"History entry has UUID mismatch!");
  
  if(entry.mutableHistory.count == otherEntry.mutableHistory.count) {
    BOOL historyEqual = YES;
    for(NSUInteger index = 0; index < entry.mutableHistory.count; index++) {
      if(NSOrderedSame != [entry.mutableHistory[index].timeInfo.modificationDate compare:otherEntry.mutableHistory[index].timeInfo.modificationDate]) {
        historyEqual = NO;
        break;
      }
    }
    if(historyEqual) {
      return; // No need to merge anything
    }
  }
  
  NSMutableDictionary <NSDate *, KPKEntry *> *historyDict = [[NSMutableDictionary alloc] init];
  for(KPKEntry *historyEntry in entry.mutableHistory) {
    NSAssert([historyEntry.uuid isEqual:entry.uuid], @"UUID of history entry does not match corresponding entry!");
    historyDict[historyEntry.timeInfo.modificationDate] = historyEntry;
  }
  /* overwrite maching only if forced, otherwise keep local entry in history */
  for(KPKEntry *externalHistoryEntry in otherEntry.mutableHistory) {
    NSAssert([externalHistoryEntry.uuid isEqual:entry.uuid], @"UUID of history entry does not match corresponding entry!");
    NSDate *modificationDate = externalHistoryEntry.timeInfo.modificationDate;
    if(historyDict[modificationDate] && (mode == KPKSynchronizationModeOverwriteExisting)) {
      historyDict[modificationDate] = externalHistoryEntry;
    }
    else {
      historyDict[modificationDate] = externalHistoryEntry;
    }
  }
  /* sort array an reassing it, copy items to be sure */
  NSArray *sortedEntries = [historyDict.allValues sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
    return [((KPKEntry *)obj1).timeInfo.modificationDate compare:((KPKEntry *)obj2).timeInfo.modificationDate];
  }];
  entry.mutableHistory = [[NSMutableArray alloc] initWithArray:sortedEntries copyItems:YES];
}

- (void)_mergeDeletedObjects:(NSDictionary<NSUUID *,KPKDeletedNode *> *)deletedObjects {
  for(NSUUID *uuid in deletedObjects) {
    KPKDeletedNode *otherDeletedNode = deletedObjects[uuid];
    KPKDeletedNode *localDeletedNode = self.mutableDeletedObjects[uuid];
    if(!localDeletedNode) {
      self.mutableDeletedObjects[uuid] = otherDeletedNode;
      continue; // done;
    }
    
    /* if the other node was deleted later, we use this other node instead and remove ours */
    NSComparisonResult result = [localDeletedNode.deletionDate compare:otherDeletedNode.deletionDate];
    if(result == NSOrderedAscending) {
      self.mutableDeletedObjects[uuid] = otherDeletedNode;
    }
  }
}

- (void)_reapplyDeletions:(KPKGroup *)group {
  
  for(KPKGroup *subGroup in group.mutableGroups.reverseObjectEnumerator) {
    [self _reapplyDeletions:subGroup];
  }
  
  for(KPKEntry *entry in group.mutableEntries.reverseObjectEnumerator) {
    KPKDeletedNode *delNode = self.mutableDeletedObjects[entry.uuid];
    if(!delNode) {
      continue; // node is not deleted
    }
    NSComparisonResult result = [entry.timeInfo.modificationDate compare:delNode.deletionDate];
    switch(result) {
      case NSOrderedAscending:
        [entry.parent _removeChild:entry];
        break;
      case NSOrderedSame:
      case NSOrderedDescending:
      default:
        /* undelete to prevent data loss! */
        self.mutableDeletedObjects[entry.uuid] = nil;
    }
  }
  BOOL groupIsEmpty = (group.mutableGroups.count == 0 && group.mutableEntries.count == 0);
  KPKDeletedNode *delNode = self.mutableDeletedObjects[group.uuid];
  if(delNode) {
    NSComparisonResult result = [group.timeInfo.modificationDate compare:delNode.deletionDate];
    switch(result) {
      case NSOrderedAscending:
        if(groupIsEmpty) {
          [group.parent _removeChild:group];
          break;
        }
        // fall through to undelete!
      case NSOrderedSame:
      case NSOrderedDescending:
      default:
        /* undelete to prevent data loss! */
        self.mutableDeletedObjects[group.uuid] = nil;
    }
  }
}

@end
