//
//  KPKSynchronizationOptions.h
//  KeePassKit
//
//  Created by Michael Starke on 28.04.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#ifndef KPKSynchronizationOptions_h
#define KPKSynchronizationOptions_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, KPKSynchronizationOptions) {
  KPKSynchronizationOverwriteExistingOption = 1,
  KPKSynchronizationKeepExistingOption = 2,
  KPKSynchronizationOverwriteIfNewerOption = 3,
  KPKSynchronizationCreateNewUuidsOption = 4,
  KPKSynchronizationSynchronizeOption = 5
};

#endif /* KPKSynchronizationOptions_h */
