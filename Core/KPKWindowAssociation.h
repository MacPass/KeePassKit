//
//  KPKWindowAssociation.h
//  MacPass
//
//  Created by Michael Starke on 14.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKAutotype;

/**
 *  Association for Autotype to a given window title
 */
@interface KPKWindowAssociation : NSObject <NSCopying, NSCoding>

/**
 *  The title of the window for this autotype sequence
 */
@property (nonatomic, copy) NSString *windowTitle;
/**
 *  The autotype sequence to use for this window association
 */
@property (nonatomic, copy) NSString *keystrokeSequence;
/**
 *  Reference to the parent autotype for undo/redo capability
 */
@property (weak) KPKAutotype *autotype;

- (id)initWithWindow:(NSString *)window keystrokeSequence:(NSString *)strokes;
/**
 *  Returns YES if the supplied window title is matched by the association
 *
 *  @param windowTitle the title of the window to test for matching
 *
 *  @return YES on successful match, no otherwise
 */
- (BOOL)matchesWindowTitle:(NSString *)windowTitle;

@end
