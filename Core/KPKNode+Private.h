//
//  KPKNode+Private.h
//  MacPass
//
//  Created by Michael Starke on 12/08/15.
//  Copyright (c) 2015 HicknHack Software GmbH. All rights reserved.
//

#ifndef MacPass_KPKNode_Private_h
#define MacPass_KPKNode_Private_h


#import "KPKNode.h"

@interface KPKNode (Private)

#pragma mark Initalizer
- (instancetype)_init;

#pragma mark NSSecureCoding
- (instancetype)_initWithCoder:(NSCoder *)aDecoder;
- (void)_encodeWithCoder:(NSCoder *)aCoder;

@end

#endif
