//
//  KPKNode.m
//  MacPass
//
//  Created by Michael Starke on 12.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKNode.h"

@implementation KPKNode

- (id)init {
  self = [super init];
  if (self) {
    _image = 0;
    _uuid = [NSUUID UUID];
    _minimumVersion = KPKDatabaseVersion1;
    
    NSDate *now = [NSDate date];
    _creationTime = now;
    _lastModificationTime = now;
    _lastAccessTime = now;
    _expiryTime = [NSDate distantFuture];
  }
  return self;
}

@end
