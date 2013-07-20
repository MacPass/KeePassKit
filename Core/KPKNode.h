//
//  KPKNode.h
//  KeePassKit
//
//  Created by Michael Starke on 12.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//


#import <Foundation/Foundation.h>
#import "KPKVersion.h"
@class KPKGroup;
@class KPKTree;
@class KPKIcon;

/* Basic Node in the Tree */
@interface KPKNode : NSObject

@property(nonatomic, weak) KPKTree *tree;
@property(nonatomic, assign) NSInteger icon;
@property(nonatomic, weak) KPKIcon *customIcon; // Refernce to the Tree Icons
@property(nonatomic, weak) KPKGroup *parent;
@property(nonatomic, strong) NSUUID *uuid;
@property(nonatomic, assign) KPKVersion minimumVersion;

@property(nonatomic, strong) NSDate *creationTime;
@property(nonatomic, strong) NSDate *lastModificationTime;
@property(nonatomic, strong) NSDate *lastAccessTime;
@property(nonatomic, strong) NSDate *expiryTime;

/**
 Holds the Undomanager that is propagated throughout the tree.
 If you plan on using the Model inside a document base application
 be sure to supply the undomanager when you create the tree.
 
 If you ommit the manager, the object does not register any undoable actions.
 
 The Model does NOT set any names on undo/redo.
 */
@property(nonatomic, weak) NSUndoManager *undoManger;

- (KPKGroup *)rootGroup;

@end
