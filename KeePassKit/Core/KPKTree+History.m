//
//  KPKTree+History.m
//  KeePassKit
//
//  Created by Michael Starke on 12.10.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTree.h"
#import "KPKGroup.h"
#import "KPKEntry_Private.h"
#import "KPKNode_Private.h"

@implementation KPKTree (History)

- (void)maintainHistory {
  [self.root _traverseNodesWithOptions:KPKNodeTraversalOptionSkipGroups
                                 block:^(KPKNode *node, BOOL *stop) {
                                   [node.asEntry _maintainHistory]; 
                                 }];
}

@end
