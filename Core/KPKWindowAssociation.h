//
//  KPKWindowAssociation.h
//  MacPass
//
//  Created by Michael Starke on 14.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKAutotype;

@interface KPKWindowAssociation : NSObject <NSCopying, NSCoding>

@property (nonatomic, copy) NSString *windowTitle;
@property (nonatomic, copy) NSString *keystrokeSequence;
@property (weak) KPKAutotype *autotype;

@end
