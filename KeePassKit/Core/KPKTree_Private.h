//
//  KPKTree_Private.h
//  KeePassKit
//
//  Created by Michael Starke on 13/10/15.
//  Copyright © 2015 HicknHack Software GmbH. All rights reserved.
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

#import "KPKTree.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KPKTree ()

@property(nonatomic, strong) NSMutableDictionary<NSUUID *,KPKDeletedNode *> *mutableDeletedObjects;
/* Deleted nodes are stored inside this dictionary for undomanager support */
@property(strong) NSMutableDictionary<NSUUID *, KPKNode *> *mutableDeletedNodes;

/* call this to add tags to the tree. Tags are counted, hence callit it twice will increase the counter on each tag */
- (void)_registerTags:(NSArray <NSString *>*)tags;
/* call this to remove tags from the tree. Tags are counted, hence you should call this only once fore each removal. */
- (void)_unregisterTags:(NSArray <NSString *>*)tags;

NS_ASSUME_NONNULL_END

@end
