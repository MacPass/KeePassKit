//
//  KPKTimeInfo.m
//  MacPass
//
//  Created by Michael Starke on 23.07.13.
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

#import "KPKTimeInfo.h"
#import "KPKNode.h"
#import "KPKTree.h"


@implementation KPKTimeInfo

@synthesize updateTiming = _updateTiming;

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (id)init {
  self = [super init];
  if(self) {
    NSDate *now = [NSDate date];
    _creationTime = now;
    _lastModificationTime = now;
    _lastAccessTime = now;
    _expiryTime = [NSDate distantFuture];
    _locationChanged = now;
    _expires = NO;
    _usageCount = 0;
    _updateTiming = NO;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [self init];
  if(self && [aDecoder isKindOfClass:[NSKeyedUnarchiver class]]) {
    _creationTime = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"creationTime"];
    _lastModificationTime = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"lastModificationTime"];
    _lastAccessTime = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"lastAccessTime"];
    _expiryTime = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"expiryTime"];
    _expires = [aDecoder decodeBoolForKey:@"expires"];
    _locationChanged = [aDecoder decodeObjectOfClass:[NSDate class] forKey:@"locationChanged"];
    _usageCount = [aDecoder decodeIntegerForKey:@"usageCount"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  if([aCoder isKindOfClass:[NSKeyedArchiver class]]) {
    [aCoder encodeObject:self.creationTime forKey:@"creationTime"];
    [aCoder encodeObject:self.lastAccessTime forKey:@"lastAccessTime"];
    [aCoder encodeObject:self.expiryTime forKey:@"expiryTime"];
    [aCoder encodeBool:self.expires forKey:@"expires"];
    [aCoder encodeObject:self.locationChanged forKey:@"locationChanged"];
    [aCoder encodeInteger:self.usageCount forKey:@"usageCount"];
  }
}

- (id)copyWithZone:(NSZone *)zone {
  KPKTimeInfo *timeInfo = [[KPKTimeInfo alloc] init];
  timeInfo.creationTime = [self.creationTime copyWithZone:zone];
  timeInfo.lastAccessTime = [self.lastAccessTime copyWithZone:zone];
  timeInfo.lastModificationTime = [self.lastModificationTime copyWithZone:zone];
  timeInfo.expiryTime = [self.expiryTime copyWithZone:zone];
  timeInfo.expires = self.expires;
  timeInfo.locationChanged = [self.locationChanged copyWithZone:zone];
  timeInfo.usageCount = self.usageCount; // reset?
  return timeInfo;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"creationTime=%@, modificationTime=%@, accessTime=%@, expiryTime=%@, moved=%@, used=%ld",
          self.creationTime,
          self.lastModificationTime,
          self.lastAccessTime,
          self.expiryTime,
          self.locationChanged,
          self.usageCount];
}

#pragma mark -
#pragma mark Properties
- (void)setExpires:(BOOL)expires {
  if(self.expires != expires) {
    [[[self.node.tree undoManager] prepareWithInvocationTarget:self] setExpires:self.expires];
    _expires = expires;
    if(self.updateTiming) {
      self.lastModificationTime = [NSDate date];
    }
  }
}

- (void)setExpiryTime:(NSDate *)expiryTime {
  if(self.expiryTime != expiryTime) {
    [[[self.node.tree undoManager] prepareWithInvocationTarget:self] setExpiryTime:self.expiryTime];
    _expiryTime = expiryTime;
    if(self.updateTiming) {
      self.lastModificationTime = [NSDate date];
    }
  }
}

- (void)reset {
  NSDate *now = [NSDate date];
  self.creationTime = now;
  self.lastModificationTime = now;
  self.lastAccessTime = now;
  self.locationChanged = now;
  self.usageCount = 0;
}

- (void)wasModified {
  if(!self.updateTiming) {
    return;
  }
  self.lastModificationTime = [NSDate date];
}

- (void)wasAccessed {
  if(!self.updateTiming) {
    return;
  }

  self.lastAccessTime = [NSDate date];
}

- (void)wasMoved {
  if(!self.updateTiming) {
    return;
  }
  self.locationChanged = [NSDate date];
}

@end
