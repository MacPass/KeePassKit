//
//  KPKOTPGenerator_Private.h
//  KeePassKit
//
//  Created by Michael Starke on 04.12.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPKOTPGenerator.h"

@interface KPKOTPGenerator ()

- (instancetype)_init;
- (NSUInteger)_counter;
- (NSString *)_alphabet;
- (NSString *)_issuerForEntry:(KPKEntry *)entry;

@end
