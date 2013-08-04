//
//  KPKTimerecording.h
//  MacPass
//
//  Created by Michael Starke on 23.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *	Items implementing this protocoll are trackabale in changes,
 *  Access and move.
 */
@protocol KPKTimerecording <NSObject>

@required
/**
 *	Tells the object to update it's timing information on mdofications
 *  Set to YES, all actions result in modifed times, NO modifes withou
 *  updating the dates.
 */
@property (nonatomic, assign) BOOL updateTiming;

@optional
/**
 *	Called to signal a modification
 */
- (void)wasModified;

/**
 *	Called to signal an access
 */
- (void)wasAccessed;

/**
 *	Called to signal a move
 */
- (void)wasMoved;

@end
