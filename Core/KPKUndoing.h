//
//  KPKUndoing.h
//  MacPass
//
//  Created by Michael Starke on 23.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KPKUndoing <NSObject>

@required
/**
 Holds the Undomanager that is propagated throughout the tree.
 If you plan on using the Model inside a document base application
 be sure to supply the undomanager when you create the tree.
 
 If you ommit the manager, the object does not register any undoable actions.
 
 The Model does NOT set any names on undo/redo.
 */
@property (nonatomic, weak) NSUndoManager *undoManager;

@end
