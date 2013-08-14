//
//  KPKWindowAssociation.h
//  MacPass
//
//  Created by Michael Starke on 14.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPKUndoing.h"

@interface KPKWindowAssociation : NSObject <KPKUndoing>

@property (nonatomic, copy) NSString *windowTitle;
@property (nonatomic, copy) NSString *keystrokeSequence;

@property (nonatomic, weak) NSUndoManager *undoManager;

@end
