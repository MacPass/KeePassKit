//
//  KPKDeletedNode.h
//  MacPass
//
//  Created by Michael Starke on 20.07.13.
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

@class KPKNode;

/**
 Represents a deletion object. These are created whenever a Group or Entry
 is permanently deleted from the database.
 */
@interface KPKDeletedNode : NSObject <NSCopying>

@property (nonatomic, copy, readonly) NSUUID *uuid;
@property (nonatomic, copy, readonly) NSDate *deletionDate;

+ (instancetype)deletedNodeForNode:(KPKNode *)node;

- (instancetype)initWithNode:(KPKNode *)node;
- (instancetype)initWithUUID:(NSUUID *)uuid date:(NSDate *)date;

@end
