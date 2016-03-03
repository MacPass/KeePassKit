//
//  KPKAutotype+Private.h
//  MacPass
//
//  Created by Michael Starke on 30/09/15.
//  Copyright © 2015 HicknHack Software GmbH. All rights reserved.
//

#import "KPKAutotype.h"

NS_ASSUME_NONNULL_BEGIN

@interface KPKAutotype ()

@property (nullable, weak) KPKEntry *entry;

- (NSString *)_autotypeNotes;

@end

NS_ASSUME_NONNULL_END