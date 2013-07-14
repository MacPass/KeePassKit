//
//  KPKTree.h
//  KeePassKit
//
//  Created by Michael Starke on 11.07.13.
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
#import "KPKNode.h"

@class KPKGroup;
@class KPKEntry;
@class KPKPassword;

@interface KPKTree : KPKNode

@property (nonatomic, assign) KPKGroup *root;
/**
 Acces to the root group via the groups property
 to offer a bindiable interface for a tree
 */
@property (nonatomic, readonly) NSArray *groups;
@property (nonatomic, readonly) NSArray *allGroups;
@property (nonatomic, readonly) NSArray *allEntries;

- (id)initWithData:(NSData *)data password:(KPKPassword *)password;
- (NSData *)serializeWithPassword:(KPKPassword *)password error:(NSError *)error;

- (KPKGroup *)createGroup:(KPKGroup *)parent;
- (KPKEntry *)createEntry:(KPKGroup *)parent;

@end
