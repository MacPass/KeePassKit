//
//  KPKTree+History.m
//  KeePassKit
//
//  Created by Michael Starke on 12.10.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTree.h"
#import "KPKGroup.h"
#import "KPKGroup_Private.h"
#import "KPKEntry_Private.h"

@implementation KPKTree (History)

- (void)maintainHistory {
  [self.root _traverseNodesWithBlock:^(KPKNode *node) {
    [node.asEntry _maintainHistory];
  } options:KPKNodeTraversalOptionSkipGroups];
}

@end
