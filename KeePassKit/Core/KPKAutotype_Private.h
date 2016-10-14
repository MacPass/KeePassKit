//
//  KPKAutotype_Private.h
//  MacPass
//
//  Created by Michael Starke on 30/09/15.
//  Copyright © 2015 HicknHack Software GmbH. All rights reserved.
//

#import "KPKAutotype.h"

NS_ASSUME_NONNULL_BEGIN

@class KPKWindowAssociation;

@interface KPKAutotype ()

@property (nullable, weak) KPKEntry *entry;
@property (nullable, copy, readonly) NSString *autotypeNotes;
@property (nonatomic, strong) NSMutableArray<KPKWindowAssociation *> *mutableAssociations;

@end

NS_ASSUME_NONNULL_END
