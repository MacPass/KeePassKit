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
  }
  return self;
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
