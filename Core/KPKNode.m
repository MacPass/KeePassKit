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

+ (BOOL)supportsSecureCoding {
  return YES;
}

+ (NSUInteger)defaultIcon {
  return 0;
}

- (id)init {
  self = [super init];
  if (self) {
    _uuid = [[NSUUID alloc] init];
    _minimumVersion = KPKLegacyVersion;
    _timeInfo = [[KPKTimeInfo alloc] init];
    _timeInfo.node = self;
    _iconId = [[self class] defaultIcon];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [self init];
  if(self) {
    _uuid = [aDecoder decodeObjectOfClass:[NSUUID class] forKey:NSStringFromSelector(@selector(uuid))];
    _minimumVersion = (KPKVersion) [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(minimumVersion))];
    _iconId = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(iconId))];
    _iconUUID = [aDecoder decodeObjectOfClass:[NSUUID class] forKey:NSStringFromSelector(@selector(iconUUID))];
    /* decode time info at last */
    _timeInfo = [aDecoder decodeObjectOfClass:[KPKTimeInfo class] forKey:NSStringFromSelector(@selector(timeInfo))];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.timeInfo forKey:NSStringFromSelector(@selector(timeInfo))];
  [aCoder encodeObject:self.uuid forKey:NSStringFromSelector(@selector(uuid))];
  [aCoder encodeInteger:self.minimumVersion forKey:NSStringFromSelector(@selector(minimumVersion))];
  [aCoder encodeInteger:self.iconId forKey:NSStringFromSelector(@selector(iconId))];
  [aCoder encodeObject:self.iconUUID forKey:NSStringFromSelector(@selector(iconUUID))];
}

#pragma mark Properties
- (BOOL)isEditable {
  if(self.tree) {
    return self.tree.isEditable;
  }
  return YES;
}

- (BOOL)hasDefaultIcon {
  /* if we have a custom icon, we are certainly not default */
  if(self.iconUUID) {
    return NO;
  }
  return (self.iconId == [[self class] defaultIcon]);
}

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

#pragma mark KPKTimerecording
- (void)setUpdateTiming:(BOOL)updateTiming {
  self.timeInfo.updateTiming = updateTiming;
}

- (BOOL)updateTiming {
  return self.timeInfo.updateTiming;
}

- (void)wasModified {
  [self.timeInfo wasModified];
}

- (void)wasAccessed {
  [self.timeInfo wasAccessed];
}

- (void)wasMoved {
  [self.timeInfo wasMoved];
}

- (void)updateTo:(KPKNode *)node {
  /* Update content*/
}

- (void)remove {
  /* not implemented */
  NSAssert(NO, @"Unable to call %@ on %@", NSStringFromSelector(_cmd), NSStringFromClass([self class]));
}

- (KPKGroup *)asGroup {
  return nil;
}

- (KPKEntry *)asEntry {
  return nil;
}

@end
