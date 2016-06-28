//
//  KPKTreeDelegate.h
//  KeePassKit
//
//  Created by Michael Starke on 28/06/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKTree;

@protocol KPKTreeDelegate <NSObject>

@optional
/**
 *  Allows the delegate to return a default autotype sequence
 *
 *  @return the default autotype sequence to be used
 */
- (NSString *)defaultAutotypeSequenceForTree:(KPKTree *)tree;
/**
 *  Is called whenever the tree wants to issue a modification
 *
 *  @param tree Tree asking if it can be modified
 *
 *  @return YES if the tree can be modified, otherwise NO
 */
- (BOOL)shouldEditTree:(KPKTree *)tree;
/**
 *  Delegates can provide an Undo-Manager to enabel Undo-Redo registration inside the tree.
 *  The provided item is not stored, so you can use this to disable undo/redo globally for a period by just providing nil
 *  Alternativly you can disable and enable undoregistration on the provided NSUndoManager
 *
 *  @param tree Tree for which an undo manager is requested
 *
 *  @return the undo manager to be used for the tree.
 */
- (NSUndoManager *)undoManagerForTree:(KPKTree *)tree;

@end
