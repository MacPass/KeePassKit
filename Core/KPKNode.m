//
//  KPKNode.m
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


#import "KPKNode.h"
#import "KPKGroup.h"
#import "KPKTimeInfo.h"
#import "KPKTree.h"

#import "NSUUID+KeePassKit.h"

@implementation KPKNode

+ (NSUInteger)defaultIcon {
  return 0;
}

- (id)init {
  self = [super init];
  if (self) {
    _iconId = 0;
    _uuid = [[NSUUID alloc] init];
    _minimumVersion = KPKLegacyVersion;
    _timeInfo = [[KPKTimeInfo alloc] init];
    _iconId = [[self class] defaultIcon];
    _updateTiming = YES;
    _iconUUID = nil;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [self init];
  if(self) {
    _timeInfo = [aDecoder decodeObjectForKey:@"timeInfo"];
    _uuid = [aDecoder decodeObjectForKey:@"uuid"];
    _minimumVersion = (KPKVersion) [aDecoder decodeIntegerForKey:@"minimumVersion"];
    _iconId = [aDecoder decodeIntegerForKey:@"iconId"];
    _iconUUID = [aDecoder decodeObjectForKey:@"iconUUID"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.timeInfo forKey:@"timeInfo"];
  [aCoder encodeObject:self.uuid forKey:@"uuid"];
  [aCoder encodeInteger:self.minimumVersion forKey:@"minimumVersion"];
  [aCoder encodeInteger:self.iconId forKey:@"iconId"];
  [aCoder encodeObject:self.iconUUID forKey:@"iconUUID"];
}

#pragma mark Properties
- (void)setIconId:(NSInteger)iconId {
  if(iconId != _iconId) {
    [[self.undoManager prepareWithInvocationTarget:self] setIconId:_iconId];
    _iconId = iconId;
  }
}

- (void)setIconUUID:(NSUUID *)iconUUID {
  if(![self.iconUUID isEqual:iconUUID]) {
    [[self.undoManager prepareWithInvocationTarget:self] setIconUUID:self.iconUUID];
    _iconUUID = iconUUID;
  }
}

- (KPKGroup *)rootGroup {
  KPKGroup *rootGroup = self.parent;
  while(rootGroup) {
    rootGroup = rootGroup.parent;
  }
  return rootGroup;
}

- (NSUndoManager *)undoManager {
  return self.tree.undoManager;
}

- (void)wasModified {
  if(self.updateTiming) {
    self.timeInfo.lastModificationTime = [NSDate date];
  }
}

- (void)wasAccessed {
  if(self.updateTiming) {
    self.timeInfo.lastAccessTime = [NSDate date];
  }
}

- (void)wasMoved {
  if(self.updateTiming) {
    self.timeInfo.locationChanged = [NSDate date];
  }
}

@end
