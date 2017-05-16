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

@property (nonatomic,strong) NSMutableArray <KPKGroup *> *mutableGroups;
@property (nonatomic,strong) NSMutableArray <KPKEntry *> *mutableEntries;

- (void)_removeChild:(KPKNode *)node;
- (void)_addChild:(KPKNode *)node atIndex:(NSUInteger)index;
- (NSUInteger)_indexForNode:(KPKNode *)node;

@end
