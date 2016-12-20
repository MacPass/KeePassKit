//
//  KPKGroup_Private.h
//  KeePassKit
//
//  Created by Michael Starke on 18/02/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKGroup.h"
#import "KPKNode_Private.h"

@interface KPKGroup ()

- (void)_removeChild:(KPKNode *)node;
- (void)_addChild:(KPKNode *)node atIndex:(NSUInteger)index;
- (NSUInteger)_indexForNode:(KPKNode *)node;

- (BOOL)_isEqualToGroup:(KPKGroup *)group options:(KPKNodeEqualityOptions)options;

@end
