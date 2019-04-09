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
#import "KPKTimeInfo_Private.h"
#import "KPKNode.h"
#import "KPKTree.h"
#import "KPKScopedSet.h"
#import "NSDate+KPKAdditions.h"

@interface KPKTimeInfo ()

@property(assign) BOOL isExpired;

@end

@implementation KPKTimeInfo

@synthesize updateTiming = _updateTiming;

+ (BOOL)supportsSecureCoding {
  return YES;
}

+ (NSSet *)keyPathsForValuesAffectingIsExpired {
  return [NSSet setWithArray:@[ NSStringFromSelector(@selector(expires)),
                                NSStringFromSelector(@selector(expirationDate))]];
}

- (instancetype)init {
  self = [super init];
  if(self) {
    NSDate *now = NSDate.date;
    _creationDate = now;
    _modificationDate = now;
    _accessDate = now;
    _expirationDate = NSDate.distantFuture;
    _locationChanged = now;
    _expires = NO;
    _usageCount = 0;
    _updateTiming = YES;
    _isExpired = NO;
  }
  return self;
}

- (void)dealloc {
  /* Remove any scheduled calls for expiration */
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_updateExpireState) object:nil];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [self init];
  if(self && [aDecoder isKindOfClass:NSKeyedUnarchiver.class]) {
    _creationDate = [aDecoder decodeObjectOfClass:NSDate.class forKey:NSStringFromSelector(@selector(creationDate))];
    _modificationDate = [aDecoder decodeObjectOfClass:NSDate.class forKey:NSStringFromSelector(@selector(modificationDate))];
    _accessDate = [aDecoder decodeObjectOfClass:NSDate.class forKey:NSStringFromSelector(@selector(accessDate))];
    _expirationDate = [aDecoder decodeObjectOfClass:NSDate.class forKey:NSStringFromSelector(@selector(expirationDate))];
    _expires = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(expires))];
    _locationChanged = [aDecoder decodeObjectOfClass:NSDate.class forKey:NSStringFromSelector(@selector(locationChanged))];
    _usageCount = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(usageCount))];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  if([aCoder isKindOfClass:NSKeyedArchiver.class]) {
    [aCoder encodeObject:self.creationDate forKey:NSStringFromSelector(@selector(creationDate))];
    [aCoder encodeObject:self.accessDate forKey:NSStringFromSelector(@selector(accessDate))];
    [aCoder encodeObject:self.expirationDate forKey:NSStringFromSelector(@selector(expirationDate))];
    [aCoder encodeBool:self.expires forKey:NSStringFromSelector(@selector(expires))];
    [aCoder encodeObject:self.locationChanged forKey:NSStringFromSelector(@selector(locationChanged))];
    [aCoder encodeInteger:self.usageCount forKey:NSStringFromSelector(@selector(usageCount))];
  }
}

- (id)copyWithZone:(NSZone *)zone {
  KPKTimeInfo *timeInfo = [[KPKTimeInfo alloc] init];
  KPK_SCOPED_NO_BEGIN(timeInfo.updateTiming)
  timeInfo.creationDate = [self.creationDate copyWithZone:zone];
  timeInfo.accessDate = [self.accessDate copyWithZone:zone];
  timeInfo.modificationDate = [self.modificationDate copyWithZone:zone];
  timeInfo.expirationDate = [self.expirationDate copyWithZone:zone];
  timeInfo.expires = self.expires;
  timeInfo.locationChanged = [self.locationChanged copyWithZone:zone];
  timeInfo.usageCount = self.usageCount; // reset?
  timeInfo.updateTiming = self.updateTiming;
  KPK_SCOPED_NO_END(timeInfo.updateTiming);
  return timeInfo;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"creationDate=%@\rmodificationDate=%@\raccessDate=%@\rexpirationDate=%@\rmoved=%@\rused=%ld",
          self.creationDate,
          self.modificationDate,
          self.accessDate,
          self.expirationDate,
          self.locationChanged,
          (unsigned long)self.usageCount];
}

- (NSUInteger)hash {
  return self.creationDate.hash ^ self.modificationDate.hash ^ self.accessDate.hash ^ self.expirationDate.hash ^ self.expires;
}

- (BOOL)isEqual:(id)object {
  if(self == object) {
    return YES;
  }
  if([object isKindOfClass:KPKTimeInfo.class]) {
    return [self isEqualToTimeInfo:(KPKTimeInfo *)object];
  }
  NSLog(@"%@:Incompatible object %@ for equality!", self, object);
  return NO;
}

- (BOOL)isEqualToTimeInfo:(KPKTimeInfo *)timeInfo {
  if(self == timeInfo) {
    return YES;
  }
  return ([self.accessDate isEqualToDate:timeInfo.accessDate]
          && [self.creationDate isEqualToDate:timeInfo.creationDate]
          && [self.modificationDate isEqualToDate:timeInfo.modificationDate]
          && [self.expirationDate isEqualToDate:timeInfo.expirationDate]
          && [self.locationChanged isEqualToDate:timeInfo.locationChanged]
          && self.usageCount == timeInfo.usageCount
          && self.expires == timeInfo.expires);  
}


#pragma mark -
#pragma mark Properties
- (void)setExpires:(BOOL)expires {
  if(self.expires != expires) {
    [[self.node.undoManager prepareWithInvocationTarget:self] setExpires:self.expires];
    [self touchModified];
    _expires = expires;
    [self _updateExpireState];
  }
}

- (void)setExpirationDate:(NSDate *)expirationDate {
  if(self.expirationDate != expirationDate) {
    [[self.node.undoManager prepareWithInvocationTarget:self] setExpirationDate:self.expirationDate];
    [self touchModified];
    _expirationDate = expirationDate;
    [self _updateExpireState];
  }
}

- (void)reset {
  NSDate *now = NSDate.date;
  self.creationDate = now;
  self.modificationDate = now;
  self.accessDate = now;
  self.locationChanged = now;
  self.usageCount = 0;
  self.updateTiming = YES;
}

- (void)touchModified {
  if(!self.updateTiming) {
    return;
  }
  self.modificationDate = NSDate.date;
}

- (void)touchAccessed {
  if(!self.updateTiming) {
    return;
  }
  
  self.accessDate = NSDate.date;
}

- (void)touchMoved {
  if(!self.updateTiming) {
    return;
  }
  self.locationChanged = NSDate.date;
}

- (void)_updateExpireState {
  /* Remove sheduled invocation */
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_updateExpireState) object:nil];
  /* Shedule invocation only if we can expire */
  if(self.expires && self.expirationDate) {
    NSTimeInterval expireTimeInterval = (self.expirationDate).timeIntervalSinceNow;
    if( expireTimeInterval > 0) {
      [self performSelector:@selector(_updateExpireState) withObject:nil afterDelay:expireTimeInterval];
    }
    else {
      self.isExpired = YES;
      return; // done!
    }
  }
  /* We aren't expired, update if needed */
  if(self.isExpired) {
    self.isExpired = NO;
  }
}

- (void)_reducePrecicionToSeconds {
  KPK_SCOPED_NO_BEGIN(self.updateTiming);
  self.creationDate = self.creationDate.kpk_dateWithReducedPrecsion;
  self.modificationDate = self.modificationDate.kpk_dateWithReducedPrecsion;
  self.accessDate = self.accessDate.kpk_dateWithReducedPrecsion;
  self.expirationDate = self.expirationDate.kpk_dateWithReducedPrecsion;
  self.locationChanged = self.locationChanged.kpk_dateWithReducedPrecsion;
  KPK_SCOPED_NO_END(self.updateTiming);
}

@end
