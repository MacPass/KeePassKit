//
//  KPKEditingSession.m
//  KeePassKit
//
//  Created by Michael Starke on 30/05/14.
//  Copyright (c) 2014 HicknHack Software GmbH. All rights reserved.
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

#import "KPKEditingSession.h"
#import "KPKNode.h"

@interface KPKEditingSession ()

@property (copy) KPKNode *node;
@property (weak) KPKNode *source;

@end

@implementation KPKEditingSession

+ (instancetype)_editingSessionWithSource:(KPKNode *)node {
  return [[KPKEditingSession alloc] _initWithSource:node];
}

- (instancetype)_initWithSource:(KPKNode *)node {
  self = [super init];
  if(self) {
    self.node = node;
    self.source = node;
  }
  return self;
}

- (BOOL)hasChanges {
  return ![self.node isEqual:self.source];
}

@end
