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
#import "KPKTimerecording.h"

@class KPKGroup;
@class KPKTree;
@class KPKIcon;
@class KPKTimeInfo;

/**
 *	Baseclass for all Nodes in a Tree.
 */
@interface KPKNode : NSObject <NSCoding, KPKTimerecording>

@property(nonatomic, weak) KPKTree *tree;
@property(nonatomic, assign) NSInteger icon;
@property(nonatomic, weak) KPKIcon *customIcon;
//@property(nonatomic, readonly, weak) KPKIcon *customIcon; // Refernce to the Tree Icons
@property(nonatomic, weak) KPKGroup *parent;
@property(nonatomic, strong) NSUUID *uuid;
@property(nonatomic, assign) KPKVersion minimumVersion;
@property(nonatomic, strong) KPKTimeInfo *timeInfo;

@property (nonatomic, assign) BOOL updateTiming;
@property (nonatomic, weak, readonly) NSUndoManager *undoManager;

/**
 *	Returns the default icon number for a Group
 *	@return	default icon index for a group
 */
+ (NSUInteger)defaultIcon;

/**
 *	Returns the root group of the node by walking up the tree
 *	@return	root group of the node
 */
- (KPKGroup *)rootGroup;

- (void)wasModified;
- (void)wasAccessed;
- (void)wasMoved;

@end
