//
//  KPKEditingSession+Private.h
//  MacPass
//
//  Created by Michael Starke on 14/10/15.
//  Copyright © 2015 HicknHack Software GmbH. All rights reserved.
//

#import "KPKEditingSession.h"

@interface KPKEditingSession ()

+ (instancetype)_editingSessionWithSource:(KPKNode *)node;
- (instancetype)_initWithSource:(KPKNode *)node;

@end
