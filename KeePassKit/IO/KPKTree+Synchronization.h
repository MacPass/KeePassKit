//
//  KPKTree+KPKSynchronization.h
//  KeePassKit
//
//  Created by Michael Starke on 17/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <KeePassKit/KeePassKit.h>

typedef NS_ENUM(NSUInteger, KPKSynchronizationOptions) {
    KPKSynchronizationOverwriteExistingOption = 1,
    KPKSynchronizationKeepExistingOption = 2,
    KPKSynchronizationOverwriteIfNewerOption = 3,
    KPKSynchronizationCreateNewUuidsOption = 4,
    KPKSynchronizationSynchronizeOption = 5
};
@interface KPKTree (Synchronization)

- (BOOL)syncronizeWithTree:(KPKTree *)tree options:(KPKSynchronizationOptions)options;

@end
