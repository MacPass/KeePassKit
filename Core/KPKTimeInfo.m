//
//  KPKTimeInfo.m
//  MacPass
//
//  Created by Michael Starke on 23.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTimeInfo.h"

@implementation KPKTimeInfo

- (id)init {
  self = [super init];
  if(self) {
    NSDate *now = [NSDate date];
    _creationTime = now;
    _lastModificationTime = now;
    _lastAccessTime = now;
    _expiryTime = [NSDate distantFuture];
    _expires = NO;
    _usageCount = 0;
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [self init];
  if(self && [aDecoder isKindOfClass:[NSKeyedUnarchiver class]]) {
    _creationTime = [aDecoder decodeObjectForKey:@"creationTime"];
    _lastModificationTime = [aDecoder decodeObjectForKey:@"lastModificationTime"];
    _lastAccessTime = [aDecoder decodeObjectForKey:@"lastAccessTime"];
    _expiryTime = [aDecoder decodeObjectForKey:@"expiryTime"];
    _expires = [aDecoder decodeBoolForKey:@"expires"];
    _locationChanged = [aDecoder decodeObjectForKey:@"locationChanged"];
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

@end
