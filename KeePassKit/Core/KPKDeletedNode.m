//
//  KPKDeletedNode.m
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

#import "KPKDeletedNode.h"
#import "KPKNode.h"

@implementation KPKDeletedNode

+ (instancetype)deletedNodeForNode:(KPKNode *)node {
  return [[KPKDeletedNode alloc] initWithUUID:node.uuid date:[NSDate date]];
}

- (instancetype)initWithNode:(KPKNode *)node {
  self = [self initWithUUID:node.uuid date:[NSDate date]];
  return self;
}

- (instancetype)initWithUUID:(NSUUID *)uuid date:(NSDate *)date {
  self = [super init];
  if(self) {
    _deletionDate = [date copy];
    _uuid = [uuid copy];
  }
  return self;
}
@end
